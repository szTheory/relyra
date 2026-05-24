defmodule Relyra.MetadataRefreshTest do
  use Relyra.TestSupport.MigrationCase, async: false

  import ExUnit.CaptureLog

  alias Relyra.Ecto.{Certificate, Connection, MetadataRevision}
  alias Relyra.Metadata

  @repo Relyra.TestSupport.EctoTestRepo
  @stub __MODULE__.ReqStub

  test "refresh fetches only when explicitly invoked and applies a new revision through Req.Test" do
    connection = insert_enabled_connection!("01JT74Q2YJ9WFM0MMSYF6QK4M1")
    register_source!(connection.connection_id)

    Req.Test.stub(@stub, fn conn ->
      Req.Test.text(conn, metadata_xml())
    end)

    assert {:ok, revision} =
             Metadata.refresh(connection.connection_id,
               repo: @repo,
               req: Req.new(plug: {Req.Test, @stub}),
               actor: "operator@example.com"
             )

    updated = @repo.get_by!(Connection, connection_id: connection.connection_id)
    assert revision.source_kind == :remote_url
    assert updated.idp_entity_id == "https://refresh.idp.example.com/metadata"
    assert updated.idp_sso_url == "https://refresh.idp.example.com/sso/redirect"
    assert revision.certificate_fingerprints == [refresh_certificate_fingerprint()]

    updated = @repo.preload(updated, :certificates)

    assert Enum.any?(
             updated.certificates,
             &(&1.fingerprint_sha256 == "fp-existing" and &1.lifecycle_state == :active)
           )

    assert Enum.any?(updated.certificates, &(&1.lifecycle_state == :next))
  end

  test "refresh returns a typed configuration error when req is not configured while local import still works" do
    connection = insert_enabled_connection!("01JT74Q2YJ9WFM0MMSYF6QK4M2")
    register_source!(connection.connection_id)

    assert {:error, %Relyra.Error{type: :adapter_not_configured}} =
             Metadata.refresh(connection.connection_id, repo: @repo)

    assert {:ok, _revision} =
             Metadata.import_xml(connection.connection_id, metadata_xml(), repo: @repo)
  end

  test "failed refreshes keep the applied runtime snapshot unchanged and emit redacted observability" do
    connection = insert_enabled_connection!("01JT74Q2YJ9WFM0MMSYF6QK4M3")
    register_source!(connection.connection_id)
    original = @repo.get_by!(Connection, connection_id: connection.connection_id)

    Req.Test.stub(@stub, fn conn ->
      Req.Test.text(conn, "<EntityDescriptor>")
    end)

    handler_id = attach_metadata_refresh_telemetry()

    log =
      capture_log(fn ->
        assert {:error, %Relyra.Error{type: :malformed_xml}} =
                 Metadata.refresh(connection.connection_id,
                   repo: @repo,
                   req: Req.new(plug: {Req.Test, @stub}),
                   actor: "operator@example.com"
                 )
      end)

    assert log =~ "[REDACTED]"
    refute log =~ "<EntityDescriptor>"

    assert_receive {:telemetry_event, [:relyra, :saml, :metadata, :refresh, :start], _,
                    start_meta},
                   100

    assert start_meta.source_kind == :remote_url

    assert_receive {:telemetry_event, [:relyra, :saml, :metadata, :refresh, :stop],
                    %{duration_ms: _}, stop_meta},
                   100

    assert stop_meta.outcome == :error
    assert stop_meta.error_code == :malformed_xml
    assert stop_meta.certificate_count == 0
    :telemetry.detach(handler_id)

    updated = @repo.get_by!(Connection, connection_id: connection.connection_id)
    assert updated.idp_entity_id == original.idp_entity_id
    assert updated.idp_sso_url == original.idp_sso_url

    assert @repo.aggregate(MetadataRevision, :count, :id) >= 1
  end

  defp register_source!(connection_id) do
    {:ok, _source} =
      Metadata.register_source(
        connection_id,
        %{
          url: "https://idp.example.com/metadata",
          actor: "operator@example.com",
          cause: "refresh registration"
        },
        repo: @repo
      )
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    connection =
      %Connection{
        id: Ecto.UUID.generate(),
        connection_id: connection_id,
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://existing.idp.example.com/entity",
        idp_sso_url: "https://existing.idp.example.com/sso",
        inserted_at: now,
        updated_at: now
      }
      |> @repo.insert!()

    %Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: connection.id,
      fingerprint_sha256: "fp-existing",
      pem: "-----BEGIN CERTIFICATE-----\nEXISTING\n-----END CERTIFICATE-----",
      source: "manual",
      role: :signing,
      lifecycle_state: :active,
      activated_at: now,
      inserted_at: now,
      updated_at: now,
      metadata: %{}
    }
    |> @repo.insert!()

    connection
  end

  defp attach_metadata_refresh_telemetry do
    handler_id = {__MODULE__, make_ref()}

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:relyra, :saml, :metadata, :refresh, :start],
          [:relyra, :saml, :metadata, :refresh, :stop],
          [:relyra, :saml, :metadata, :refresh, :exception]
        ],
        &__MODULE__.handle_event/4,
        self()
      )

    handler_id
  end

  def handle_event(event_name, measurements, metadata, pid) do
    send(pid, {:telemetry_event, event_name, measurements, metadata})
  end

  defp metadata_xml do
    """
    <EntityDescriptor entityID="https://refresh.idp.example.com/metadata" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing">
          <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
            <X509Data>
              <X509Certificate>#{refresh_certificate_body()}</X509Certificate>
            </X509Data>
          </KeyInfo>
        </KeyDescriptor>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://refresh.idp.example.com/sso/redirect"/>
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
  end

  defp refresh_certificate_fingerprint do
    # CR-02: the stored certificate fingerprint is now the SHA-256 of the DER
    # bytes (the openssl `x509 -outform DER | dgst -sha256` recipe the operator
    # pin task documents), NOT the SHA-256 of the PEM text. Computed independently
    # here (not via TrustAnchor) so this stays a real cross-check of import.ex.
    [{:Certificate, der, :not_encrypted} | _] =
      :public_key.pem_decode(refresh_certificate_pem())

    :crypto.hash(:sha256, der) |> Base.encode16(case: :lower)
  end

  defp refresh_certificate_body do
    refresh_certificate_pem()
    |> String.replace("-----BEGIN CERTIFICATE-----\n", "")
    |> String.replace("\n-----END CERTIFICATE-----\n", "")
    |> String.replace("\n", "")
  end

  defp refresh_certificate_pem do
    """
    -----BEGIN CERTIFICATE-----
    MIIDEzCCAfugAwIBAgIUXVtzU8ffQDHWYvtv2Y0kLqwKqtYwDQYJKoZIhvcNAQEL
    BQAwGTEXMBUGA1UEAwwOcGhhc2UxMC10ZXN0LTIwHhcNMjYwNTA1MjAxODUwWhcN
    MjYwODAzMjAxODUwWjAZMRcwFQYDVQQDDA5waGFzZTEwLXRlc3QtMjCCASIwDQYJ
    KoZIhvcNAQEBBQADggEPADCCAQoCggEBANtAySPCQWOd+oNvfnfkLYeyzeoSOuHP
    K5K6Jsbj7JobGvAO6uSN1qlkOItclJH4LFK6hQXLeqnSbuuITiCg8IREElH5Z2Dj
    YPI/H9WRc+xjfyOxaQS3Q1Lm0Tm/jCgTbB6FPTfr2/EnYNpgiEOP+iIg+e++RWqi
    Zn9ub3/Rfg37eHRERhxwKxC7HYXukwIVf5vj3nasyR6LLREBpqKIYt2Hvc75h/Qf
    0ULknFOc+wa1AE5hZs6gckCph8LcLR8BYnwHWcEPr23o4QBncKSga00xdhX+TUYK
    BSXDRpz92OIfxTn+ig5xyaeYvenUtKVXn9TPC62w3ipM+tg2R9i/sY0CAwEAAaNT
    MFEwHQYDVR0OBBYEFMlYhziYSpJJxzY6fzciZDK9XRrUMB8GA1UdIwQYMBaAFMlY
    hziYSpJJxzY6fzciZDK9XRrUMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEL
    BQADggEBAGmRgs4UZFXt/jS5HMLqF4REobCzq/LV3TC+MIp3DgT3zEk8dpJijFhX
    mvMis52P8O4u95NVKVfjvRZcW/fXYWALaFDms7pUJnnteuggVVpzF2ZB84wxB3Op
    8FSUyhD9rPZLqOOuEfaFfzySSAwN8qger1gYgrzzCEDXKmsigam2NdTeHqnBx7dW
    nZ2mWI43dw3K9zwo30njAPPELb4CuK7I80ZV7gb3Uo13qe5oN6zXjwc/zYrFkTDm
    C4m3WtD2buRS/kf5o/+3U/IPmvseekE//IoZ3ZqWh3pJhFvnAiv0mb8cKXA5Rl2U
    OBiJCYv0CChnwYhjWmr+Ot9HdHcHqM4=
    -----END CERTIFICATE-----
    """
  end
end
