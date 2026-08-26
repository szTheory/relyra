defmodule LedgerLoop.Demo.KeycloakProvisionerTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Accounts.{LoginReceipt, SAMLIdentity}
  alias LedgerLoop.Demo.{KeycloakProvisioner, Reset}
  alias LedgerLoop.Repo
  alias Relyra.ConnectionResolver.Ecto, as: ConnectionResolver
  alias Relyra.Ecto.{AuditEvent, Certificate, Connection, MetadataRevision}
  alias Relyra.Metadata.TrustAnchor

  @issuer "http://keycloak.relyra.localhost/realms/demo-app"
  @sarah "sarah@northstar.example.com"

  setup do
    Reset.reset!()
    :ok
  end

  test "initial provisioning is audited and a byte-identical descriptor is unchanged" do
    descriptor = descriptor(:a)
    parent = self()

    descriptor_parser = fn xml ->
      send(parent, :descriptor_parsed)
      Relyra.Metadata.Parser.parse(xml)
    end

    assert {:ok, :provisioned} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor} end,
               descriptor_parser: descriptor_parser
             )

    assert_receive :descriptor_parsed
    refute_receive :descriptor_parsed

    connection = keycloak_connection!()
    assert connection.status == :enabled
    assert connection.idp_entity_id == @issuer
    assert connection.idp_sso_url == "#{@issuer}/protocol/saml"

    assert [%SAMLIdentity{issuer: @issuer, subject: @sarah}] =
             Repo.all(from identity in SAMLIdentity, where: identity.issuer == ^@issuer)

    assert [%AuditEvent{} = mapping_event] = mapping_events(connection.id)
    assert mapping_event.domain == :mapping
    assert mapping_event.action == :created
    assert mapping_event.actor == "ledger_loop_keycloak_provisioner"
    assert mapping_event.cause == "phase70_profile_bootstrap"
    assert mapping_event.correlation_id == "keycloak-profile-#{KeycloakProvisioner.connection_id()}"

    assert [%Certificate{lifecycle_state: :active, role: :signing} = certificate] =
             Repo.all(
               from certificate in Certificate,
                 where: certificate.connection_record_id == ^connection.id
             )

    assert certificate.fingerprint_sha256 == descriptor_fingerprint(descriptor)
    assert_audited_trust_events(connection.id)

    trust_counts = trust_counts(connection.id)

    assert {:ok, :unchanged} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor} end,
               descriptor_parser: descriptor_parser
             )

    assert_receive :descriptor_parsed
    refute_receive :descriptor_parsed

    assert trust_counts == trust_counts(connection.id)

    assert 1 ==
             Repo.aggregate(
               from(identity in SAMLIdentity, where: identity.issuer == ^@issuer),
               :count,
               :id
             )

    assert [^mapping_event] = mapping_events(connection.id)
  end

  test "mapping-audit failure rolls back Sarah identity and remains retryable" do
    descriptor = descriptor(:a)

    assert {:error, {:identity, {:audit, :injected_audit_failure}}} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor} end,
               mapping_audit_writer: fn _repo, _attrs -> {:error, :injected_audit_failure} end
             )

    assert_no_enabled_keycloak_connection()
    assert_no_keycloak_identity_or_mapping_audit()
    assert Repo.aggregate(LoginReceipt, :count, :id) == 0

    assert {:ok, :provisioned} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor} end
             )

    assert_one_keycloak_identity_and_mapping_audit()
  end

  test "enablement failure rolls back Sarah identity and mapping audit together" do
    descriptor = descriptor(:a)

    assert {:error, {:identity, {:enable, :injected_enable_failure}}} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor} end,
               connection_enabler: fn _connection_id, _opts -> {:error, :injected_enable_failure} end
             )

    assert_no_enabled_keycloak_connection()
    assert_no_keycloak_identity_or_mapping_audit()
    assert Repo.aggregate(LoginReceipt, :count, :id) == 0

    assert {:ok, :provisioned} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor} end
             )

    assert_one_keycloak_identity_and_mapping_audit()
  end

  test "wrong public issuer leaves all Keycloak trust and identity state unavailable" do
    wrong_issuer = "http://keycloak.other.localhost/realms/demo-app"
    invalid_descriptor = String.replace(descriptor(:a), @issuer, wrong_issuer)

    assert {:error, {:parse, :unexpected_public_issuer}} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, invalid_descriptor} end
             )

    assert Repo.get_by(Connection, connection_id: KeycloakProvisioner.connection_id()) == nil
    assert Repo.aggregate(MetadataRevision, :count, :id) == 0
    assert Repo.aggregate(LoginReceipt, :count, :id) == 0

    assert Repo.aggregate(
             from(identity in SAMLIdentity, where: identity.issuer == ^wrong_issuer),
             :count,
             :id
           ) == 0
  end

  test "provisioner persists canonical candidates without raw XML import" do
    source =
      __DIR__
      |> Path.join("../../../lib/ledger_loop/demo/keycloak_provisioner.ex")
      |> File.read!()

    assert source =~ "MetadataApply.apply_revision"
    refute source =~ "Import.import_xml"
  end

  for stage <- [:fetch, :parse, :apply, :activation, :identity] do
    test "#{stage} failure leaves Keycloak unavailable and creates no receipt" do
      assert {:error, {unquote(stage), _reason}} =
               KeycloakProvisioner.provision!(
                 descriptor_fetcher: fn _url -> {:ok, descriptor(:a)} end,
                 fail_at: unquote(stage)
               )

      assert_no_enabled_keycloak_connection()
      assert Repo.aggregate(LoginReceipt, :count, :id) == 0
    end
  end

  test "a signing-key rotation stays unavailable until the new trust is active" do
    descriptor_a = descriptor(:a)
    descriptor_b = descriptor(:b)

    assert {:ok, :provisioned} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor_a} end
             )

    parent = self()

    assert {:ok, :provisioned} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor_b} end,
               after_disable: fn ->
                 send(parent, {:resolver_after_disable, resolver_result()})
                 :ok
               end
             )

    assert_receive {:resolver_after_disable, {:error, %{type: :connection_unavailable}}}

    assert {:ok, snapshot} = resolver_result()

    snapshot_fingerprints = Enum.map(snapshot.idp_certificates, &TrustAnchor.fingerprint/1)

    assert Enum.any?(
             snapshot_fingerprints,
             &(&1 == descriptor_fingerprint(descriptor_b))
           )

    refute Enum.all?(
             snapshot_fingerprints,
             &(&1 == descriptor_fingerprint(descriptor_a))
           )

    connection = keycloak_connection!()
    counts_after_rotation = trust_counts(connection.id)

    assert {:ok, :unchanged} =
             KeycloakProvisioner.provision!(
               descriptor_fetcher: fn _url -> {:ok, descriptor_b} end
             )

    assert counts_after_rotation == trust_counts(connection.id)
  end

  defp resolver_result do
    ConnectionResolver.resolve_connection(%{connection_id: KeycloakProvisioner.connection_id()},
      repo: Repo
    )
  end

  defp assert_no_enabled_keycloak_connection do
    case Repo.get_by(Connection, connection_id: KeycloakProvisioner.connection_id()) do
      nil -> :ok
      %Connection{status: status} -> refute status == :enabled
    end
  end

  defp assert_no_keycloak_identity_or_mapping_audit do
    assert Repo.aggregate(
             from(identity in SAMLIdentity, where: identity.issuer == ^@issuer),
             :count,
             :id
           ) == 0

    assert Repo.aggregate(
             from(event in AuditEvent,
               where:
                 event.domain == :mapping and
                   event.correlation_id == ^"keycloak-profile-#{KeycloakProvisioner.connection_id()}"
             ),
             :count,
             :id
           ) == 0
  end

  defp assert_one_keycloak_identity_and_mapping_audit do
    assert Repo.aggregate(
             from(identity in SAMLIdentity, where: identity.issuer == ^@issuer),
             :count,
             :id
           ) == 1

    assert [%AuditEvent{}] = mapping_events(keycloak_connection!().id)
  end

  defp mapping_events(connection_record_id) do
    Repo.all(
      from event in AuditEvent,
        where:
          event.connection_record_id == ^connection_record_id and
            event.domain == :mapping and
            event.action == :created and
            event.correlation_id == ^"keycloak-profile-#{KeycloakProvisioner.connection_id()}"
    )
  end

  defp keycloak_connection! do
    Repo.get_by!(Connection, connection_id: KeycloakProvisioner.connection_id())
  end

  defp assert_audited_trust_events(connection_record_id) do
    events =
      Repo.all(
        from event in AuditEvent,
          where:
            event.connection_record_id == ^connection_record_id and
              event.domain in [:connection, :metadata, :certificate]
      )

    assert Enum.map(events, & &1.domain) |> Enum.uniq() |> Enum.sort() == [
             :certificate,
             :connection,
             :metadata
           ]

    for domain <- [:connection, :metadata, :certificate] do
      assert Enum.any?(events, fn event ->
               event.domain == domain and
                 event.actor == "ledger_loop_keycloak_provisioner" and
                 event.cause == "phase70_profile_bootstrap" and
                 is_binary(event.correlation_id)
             end)
    end
  end

  defp trust_counts(connection_record_id) do
    %{
      connections:
        Repo.aggregate(
          from(connection in Connection, where: connection.id == ^connection_record_id),
          :count,
          :id
        ),
      certificates:
        Repo.aggregate(
          from(certificate in Certificate,
            where: certificate.connection_record_id == ^connection_record_id
          ),
          :count,
          :id
        ),
      audits:
        Repo.aggregate(
          from(event in AuditEvent,
            where:
              event.connection_record_id == ^connection_record_id and
                event.domain in [:connection, :metadata, :certificate]
          ),
          :count,
          :id
        )
    }
  end

  defp descriptor(which) do
    certificate = certificate_body(which)

    """
    <EntityDescriptor entityID="#{@issuer}" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing"><KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#"><X509Data><X509Certificate>#{certificate}</X509Certificate></X509Data></KeyInfo></KeyDescriptor>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="#{@issuer}/protocol/saml" />
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
  end

  defp certificate_body(:a) do
    __DIR__
    |> Path.join("../../../priv/fake_idp/idp_cert.pem")
    |> File.read!()
    |> String.replace(~r/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s+/, "")
  end

  defp certificate_body(:b) do
    __DIR__
    |> Path.join("../../../../../test/relyra/ecto/escape_hatch_audit_test.exs")
    |> File.read!()
    |> then(&Regex.run(~r/<X509Certificate>([A-Za-z0-9+\/=]+)<\/X509Certificate>/, &1))
    |> List.last()
  end

  defp descriptor_fingerprint(descriptor) do
    [_, encoded] = Regex.run(~r/<X509Certificate>(.+)<\/X509Certificate>/s, descriptor)

    :crypto.hash(:sha256, Base.decode64!(encoded))
    |> Base.encode16(case: :lower)
  end
end
