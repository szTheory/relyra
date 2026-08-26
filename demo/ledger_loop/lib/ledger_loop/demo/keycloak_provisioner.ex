defmodule LedgerLoop.Demo.KeycloakProvisioner do
  @moduledoc """
  Installs the optional Keycloak demo profile through Relyra's audited trust seams.
  """

  import Ecto.Query

  alias LedgerLoop.Accounts.{SAMLIdentity, User}
  alias LedgerLoop.Repo
  alias Relyra.Ecto.{CertificateInventory, Connection, Connections}
  alias Relyra.Metadata.Import

  @connection_id "01H0B4Y1A2B3C4D5E6F7G8H9J4"
  @actor "ledger_loop_keycloak_provisioner"
  @cause "phase70_profile_bootstrap"
  @sarah_email "sarah@northstar.example.com"

  def connection_id, do: @connection_id

  def public_issuer(host \\ "relyra.localhost"), do: "http://keycloak.#{host}/realms/demo-app"

  def descriptor_url(_host \\ "relyra.localhost"),
    do: "http://keycloak:8080/realms/demo-app/protocol/saml/descriptor"

  def provision!(opts \\ []) do
    host = Keyword.get(opts, :relyra_host, "relyra.localhost")
    url = Keyword.get(opts, :descriptor_url, descriptor_url(host))
    fetcher = Keyword.get(opts, :descriptor_fetcher, &fetch_descriptor/1)
    audit = audit_context()

    with {:ok, descriptor} <- fetcher.(url),
         {:ok, _connection} <- ensure_draft_connection(host, audit),
         {:ok, _revision} <-
           Import.import_xml(@connection_id, descriptor,
             repo: Repo,
             actor: @actor,
             cause: @cause,
             audit: audit
           ),
         {:ok, _certificate} <- activate_imported_certificate(audit),
         :ok <- ensure_sarah_identity(host),
         {:ok, enabled} <- enable_connection(audit) do
      {:ok, enabled}
    end
  end

  defp fetch_descriptor(url) do
    case Req.get(url: url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} when is_binary(body) -> {:ok, body}
      {:ok, %{status: status}} -> {:error, {:descriptor_fetch_failed, status}}
      {:error, reason} -> {:error, {:descriptor_fetch_failed, reason}}
    end
  end

  defp ensure_draft_connection(host, audit) do
    attrs = %{
      connection_id: @connection_id,
      display_name: "Northstar Health — Keycloak real IdP",
      organization_id: "northstar",
      sp_entity_id: "http://#{host}/saml/#{@connection_id}/metadata",
      acs_url: "http://#{host}/saml/#{@connection_id}/acs",
      idp_entity_id: public_issuer(host),
      idp_sso_url: "#{public_issuer(host)}/protocol/saml",
      allow_idp_initiated: false,
      sign_authn_requests: false
    }

    case Repo.get_by(Connection, connection_id: @connection_id) do
      nil -> Connections.create(attrs, repo: Repo, audit: audit)
      connection -> Connections.update(connection.connection_id, attrs, repo: Repo, audit: audit)
    end
  end

  defp activate_imported_certificate(audit) do
    connection =
      Repo.get_by!(Connection, connection_id: @connection_id) |> Repo.preload(:certificates)

    case Enum.find(
           connection.certificates,
           &(&1.role == :signing and &1.lifecycle_state == :next)
         ) do
      nil ->
        case Enum.find(
               connection.certificates,
               &(&1.role == :signing and &1.lifecycle_state == :active)
             ) do
          nil -> {:error, :missing_imported_signing_certificate}
          certificate -> {:ok, certificate}
        end

      certificate ->
        CertificateInventory.activate_signing_certificate(
          Repo,
          @connection_id,
          certificate.fingerprint_sha256,
          audit: audit
        )
    end
  end

  defp ensure_sarah_identity(host) do
    user = Repo.get_by!(User, email: @sarah_email)
    issuer = public_issuer(host)

    case Repo.one(
           from identity in SAMLIdentity,
             where: identity.subject == ^@sarah_email and identity.issuer == ^issuer
         ) do
      nil ->
        %SAMLIdentity{}
        |> SAMLIdentity.changeset(%{user_id: user.id, subject: @sarah_email, issuer: issuer})
        |> Repo.insert()
        |> case do
          {:ok, _identity} -> :ok
          {:error, changeset} -> {:error, {:identity_insert_failed, changeset}}
        end

      _identity ->
        :ok
    end
  end

  defp enable_connection(audit) do
    case Repo.get_by!(Connection, connection_id: @connection_id).status do
      :enabled -> {:ok, Repo.get_by!(Connection, connection_id: @connection_id)}
      _status -> Connections.enable(@connection_id, repo: Repo, audit: audit)
    end
  end

  defp audit_context do
    %{actor: @actor, cause: @cause, correlation_id: "keycloak-profile-#{@connection_id}"}
  end
end
