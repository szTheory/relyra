defmodule LedgerLoop.Demo.KeycloakProvisioner do
  @moduledoc """
  Installs the optional Keycloak demo profile through Relyra's audited trust seams.

  The profile is deliberately fail-closed: a descriptor that cannot be fetched,
  parsed, applied, activated, or mapped leaves its connection unavailable.
  """

  import Ecto.Query

  alias LedgerLoop.Accounts.{SAMLIdentity, User}
  alias LedgerLoop.Repo
  alias Relyra.Ecto.{CertificateInventory, Connection, Connections}
  alias Relyra.Metadata.{Import, Parser}

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

    result =
      with :ok <- maybe_fail(opts, :fetch),
           {:ok, descriptor} <- fetch_descriptor(fetcher, url),
           :ok <- maybe_fail(opts, :parse),
           {:ok, facts} <- descriptor_facts(descriptor, host),
           :ok <- maybe_unchanged(facts, host),
           :ok <- disable_connection(audit),
           :ok <- run_after_disable(opts),
           {:ok, _connection} <- ensure_draft_connection(host, audit),
           :ok <- maybe_fail(opts, :apply),
           {:ok, _revision} <- import_descriptor(descriptor, audit),
           :ok <- maybe_fail(opts, :activation),
           {:ok, _certificate} <- activate_and_reconcile_certificates(facts.fingerprints, audit),
           :ok <- maybe_fail(opts, :identity),
           :ok <- ensure_sarah_identity(host),
           {:ok, _enabled} <- enable_connection(audit) do
        {:ok, :provisioned}
      else
        :unchanged -> {:ok, :unchanged}
        {:error, _reason} = error -> error
      end

    fail_closed(result, audit)
  end

  defp fetch_descriptor(fetcher, url) do
    case fetcher.(url) do
      {:ok, body} when is_binary(body) -> {:ok, body}
      {:error, reason} -> {:error, {:fetch, reason}}
      other -> {:error, {:fetch, {:unexpected_fetch_result, other}}}
    end
  end

  defp descriptor_facts(descriptor, host) do
    with {:ok, parsed} <- Parser.parse(descriptor),
         candidate <- Import.build_candidate(parsed),
         true <- candidate.idp_entity_id == public_issuer(host) do
      {:ok,
       %{
         issuer: candidate.idp_entity_id,
         sso_url: candidate.idp_sso_url,
         fingerprints: candidate.certificates |> Enum.map(& &1.fingerprint_sha256) |> MapSet.new()
       }}
    else
      false -> {:error, {:parse, :unexpected_public_issuer}}
      {:error, reason} -> {:error, {:parse, reason}}
    end
  end

  defp maybe_unchanged(facts, host) do
    case Repo.get_by(Connection, connection_id: @connection_id) do
      %Connection{status: :enabled} = connection ->
        active_fingerprints =
          Repo.all(
            from certificate in Ecto.assoc(connection, :certificates),
              where: certificate.role == :signing and certificate.lifecycle_state == :active
          )
          |> Enum.map(& &1.fingerprint_sha256)
          |> MapSet.new()

        identity_exists? =
          Repo.exists?(
            from identity in SAMLIdentity,
              where: identity.subject == ^@sarah_email and identity.issuer == ^public_issuer(host)
          )

        if connection.idp_entity_id == facts.issuer and connection.idp_sso_url == facts.sso_url and
             active_fingerprints == facts.fingerprints and identity_exists? do
          :unchanged
        else
          :ok
        end

      _other ->
        :ok
    end
  end

  defp disable_connection(audit) do
    case Repo.get_by(Connection, connection_id: @connection_id) do
      %Connection{status: :enabled} -> Connections.disable(@connection_id, repo: Repo, audit: audit)
      _connection -> :ok
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
      _connection -> Connections.update(@connection_id, attrs, repo: Repo, audit: audit)
    end
  end

  defp import_descriptor(descriptor, audit) do
    case Import.import_xml(@connection_id, descriptor,
           repo: Repo,
           actor: @actor,
           cause: @cause,
           audit: audit
         ) do
      {:ok, revision} -> {:ok, revision}
      {:error, reason} -> {:error, {:apply, reason}}
    end
  end

  defp activate_and_reconcile_certificates(fingerprints, audit) do
    connection = Repo.get_by!(Connection, connection_id: @connection_id) |> Repo.preload(:certificates)

    with {:ok, certificate} <- activate_imported_certificate(connection, fingerprints, audit),
         :ok <- retire_stale_signing_certificates(certificate.fingerprint_sha256, audit) do
      {:ok, certificate}
    else
      {:error, reason} -> {:error, {:activation, reason}}
    end
  end

  defp activate_imported_certificate(connection, fingerprints, audit) do
    certificate =
      Enum.find(connection.certificates, fn certificate ->
        certificate.role == :signing and certificate.lifecycle_state == :next and
          MapSet.member?(fingerprints, certificate.fingerprint_sha256)
      end) ||
        Enum.find(connection.certificates, fn certificate ->
          certificate.role == :signing and certificate.lifecycle_state == :active and
            MapSet.member?(fingerprints, certificate.fingerprint_sha256)
        end)

    case certificate do
      nil -> {:error, :missing_imported_signing_certificate}
      %{lifecycle_state: :active} -> {:ok, certificate}
      certificate ->
        CertificateInventory.activate_signing_certificate(
          Repo,
          @connection_id,
          certificate.fingerprint_sha256,
          audit: audit
        )
    end
  end

  defp retire_stale_signing_certificates(active_fingerprint, audit) do
    Repo.get_by!(Connection, connection_id: @connection_id)
    |> Repo.preload(:certificates)
    |> Map.fetch!(:certificates)
    |> Enum.filter(fn certificate ->
      certificate.role == :signing and certificate.lifecycle_state == :active and
        certificate.fingerprint_sha256 != active_fingerprint
    end)
    |> Enum.reduce_while(:ok, fn certificate, :ok ->
      case CertificateInventory.retire_signing_certificate(
             Repo,
             @connection_id,
             certificate.fingerprint_sha256,
             audit: audit
           ) do
        {:ok, _retired} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
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
          {:error, changeset} -> {:error, {:identity, changeset}}
        end

      _identity ->
        :ok
    end
  end

  defp enable_connection(audit), do: Connections.enable(@connection_id, repo: Repo, audit: audit)

  defp fail_closed({:ok, _outcome} = result, _audit), do: result

  defp fail_closed({:error, _reason} = result, audit) do
    _ = disable_connection(audit)
    result
  end

  defp maybe_fail(opts, stage) do
    if Keyword.get(opts, :fail_at) == stage, do: {:error, {stage, :injected_failure}}, else: :ok
  end

  defp run_after_disable(opts) do
    case Keyword.get(opts, :after_disable) do
      nil -> :ok
      hook when is_function(hook, 0) -> hook.()
    end
  end

  defp fetch_descriptor(url) do
    case Req.get(url: url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: body}} when is_binary(body) -> {:ok, body}
      {:ok, %{status: status}} -> {:error, {:descriptor_fetch_failed, status}}
      {:error, reason} -> {:error, {:descriptor_fetch_failed, reason}}
    end
  end

  defp audit_context do
    %{actor: @actor, cause: @cause, correlation_id: "keycloak-profile-#{@connection_id}"}
  end
end
