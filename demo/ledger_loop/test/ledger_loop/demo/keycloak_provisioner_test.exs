defmodule LedgerLoop.Demo.KeycloakProvisionerTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Accounts.{LoginReceipt, SAMLIdentity}
  alias LedgerLoop.Demo.{KeycloakProvisioner, Reset}
  alias LedgerLoop.Repo
  alias Relyra.Ecto.{AuditEvent, Certificate, Connection}

  @issuer "http://keycloak.relyra.localhost/realms/demo-app"
  @sarah "sarah@northstar.example.com"

  setup do
    Reset.reset!()
    :ok
  end

  test "initial provisioning is audited and a byte-identical descriptor is unchanged" do
    descriptor = descriptor("A")

    assert {:ok, :provisioned} =
             KeycloakProvisioner.provision!(descriptor_fetcher: fn _url -> {:ok, descriptor} end)

    connection = keycloak_connection!()
    assert connection.status == :enabled
    assert connection.idp_entity_id == @issuer
    assert connection.idp_sso_url == "#{@issuer}/protocol/saml"

    assert [%SAMLIdentity{issuer: @issuer, subject: @sarah}] =
             Repo.all(from identity in SAMLIdentity, where: identity.issuer == ^@issuer)

    assert [%Certificate{lifecycle_state: :active, role: :signing} = certificate] =
             Repo.all(from certificate in Certificate, where: certificate.connection_record_id == ^connection.id)

    assert certificate.fingerprint_sha256 == descriptor_fingerprint(descriptor)
    assert_audited_trust_events(connection.id)

    trust_counts = trust_counts(connection.id)

    assert {:ok, :unchanged} =
             KeycloakProvisioner.provision!(descriptor_fetcher: fn _url -> {:ok, descriptor} end)

    assert trust_counts == trust_counts(connection.id)
    assert 1 == Repo.aggregate(SAMLIdentity, :count, :id)
  end

  for stage <- [:fetch, :parse, :apply, :activation, :identity] do
    test "#{stage} failure leaves Keycloak unavailable and creates no receipt" do
      assert {:error, {unquote(stage), _reason}} =
               KeycloakProvisioner.provision!(
                 descriptor_fetcher: fn _url -> {:ok, descriptor("A")} end,
                 fail_at: unquote(stage)
               )

      assert_no_enabled_keycloak_connection()
      assert Repo.aggregate(LoginReceipt, :count, :id) == 0
    end
  end

  defp assert_no_enabled_keycloak_connection do
    case Repo.get_by(Connection, connection_id: KeycloakProvisioner.connection_id()) do
      nil -> :ok
      %Connection{status: status} -> refute status == :enabled
    end
  end

  defp keycloak_connection! do
    Repo.get_by!(Connection, connection_id: KeycloakProvisioner.connection_id())
  end

  defp assert_audited_trust_events(connection_record_id) do
    events =
      Repo.all(
        from event in AuditEvent,
          where: event.connection_record_id == ^connection_record_id and event.domain in [:connection, :metadata, :certificate]
      )

    assert Enum.map(events, & &1.domain) |> Enum.uniq() |> Enum.sort() == [:certificate, :connection, :metadata]

    assert Enum.all?(events, fn event ->
             event.actor == "ledger_loop_keycloak_provisioner" and
               event.cause == "phase70_profile_bootstrap" and
               is_binary(event.correlation_id)
           end)
  end

  defp trust_counts(connection_record_id) do
    %{
      connections: Repo.aggregate(from(connection in Connection, where: connection.id == ^connection_record_id), :count, :id),
      certificates: Repo.aggregate(from(certificate in Certificate, where: certificate.connection_record_id == ^connection_record_id), :count, :id),
      audits:
        Repo.aggregate(
          from(event in AuditEvent,
            where: event.connection_record_id == ^connection_record_id and event.domain in [:connection, :metadata, :certificate]
          ),
          :count,
          :id
        )
    }
  end

  defp descriptor(_label) do
    certificate =
      __DIR__
      |> Path.join("../../../priv/fake_idp/idp_cert.pem")
      |> File.read!()
      |> String.replace(~r/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s+/, "")

    """
    <EntityDescriptor entityID="#{@issuer}" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing"><KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#"><X509Data><X509Certificate>#{certificate}</X509Certificate></X509Data></KeyInfo></KeyDescriptor>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="#{@issuer}/protocol/saml?key=#{label}" />
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
  end

  defp descriptor_fingerprint(descriptor) do
    [_, encoded] = Regex.run(~r/<X509Certificate>(.+)<\/X509Certificate>/s, descriptor)

    encoded
    |> Base.decode64!()
    |> :crypto.hash(:sha256)
    |> Base.encode16(case: :lower)
  end
end
