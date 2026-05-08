defmodule Relyra.Ecto.EscapeHatchAuditTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Diagnostic.AllowList
  alias Relyra.Ecto.{AuditEvent, Connection, MetadataSource}
  alias Relyra.LiveAdmin.{Query, Scope}
  alias Relyra.Metadata.{AutoRefresh, Import, Parser}

  @repo Relyra.TestSupport.EctoTestRepo
  @stub __MODULE__.ReqStub

  test "AutoRefresh legacy_unsigned metadata bypass stays attributable correlated and REDACTED in exports" do
    connection = insert_enabled_connection!("01JU0ESCAPEHATCH000000000001")
    correlation_id = "legacy_unsigned-correlation"
    actor = "ops@example.com"
    cause = "unsigned metadata review window"
    candidate = parsed_candidate!(unsigned_metadata_xml())

    source =
      insert_metadata_source!(connection.id,
        require_signed_metadata: true,
        metadata_trust_fingerprints: [],
        legacy_unsigned_metadata_policy: %{
          "allow_until" => Date.utc_today() |> Date.add(7) |> Date.to_iso8601(),
          "reason" => "legacy_unsigned metadata migration"
        },
        last_known_metadata_signing_certs: candidate.certificate_fingerprints,
        auto_refresh_enabled: false
      )

    assert {:ok, revision} =
             AutoRefresh.refresh(source,
               repo: @repo,
               req: stub_req_returning(unsigned_metadata_xml()),
               actor: actor,
               cause: cause,
               audit: %{actor: actor, cause: cause, correlation_id: correlation_id}
             )

    metadata_event =
      AuditEvent
      |> @repo.all()
      |> Enum.find(&(&1.domain == :metadata and &1.action == :applied))

    assert metadata_event.actor == actor
    assert metadata_event.cause == cause
    assert metadata_event.correlation_id == correlation_id
    assert metadata_event.diff_summary["outcome"] == "applied"

    exported_event = AllowList.export_audit_log(metadata_event)
    expected_correlation = AllowList.hash_correlation_id(correlation_id)

    refute Map.has_key?(exported_event, :actor)
    assert exported_event.correlation_id == expected_correlation
    assert exported_event.cause == cause

    assert {:ok, detail} =
             Query.get_metadata_revisions(
               @repo,
               %Scope{actor: actor, organization_id: nil},
               connection.connection_id
             )

    assert detail.auto_refresh_health.legacy_unsigned_metadata_policy["allow_until"]

    assert detail.auto_refresh_health.legacy_unsigned_metadata_policy["reason"] =~
             "legacy_unsigned"

    assert Enum.any?(detail.revisions, &(&1.id == revision.id))
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      display_name: "Escape hatch audit proof",
      organization_id: "org_escape_hatch",
      status: :enabled,
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso/redirect",
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp insert_metadata_source!(connection_record_id, overrides) do
    base_attrs = %{
      connection_record_id: connection_record_id,
      url: "https://idp.example.com/metadata",
      kind: :remote_url,
      registered_by: "operator@example.com",
      registered_reason: "escape hatch audit fixture",
      last_outcome: :registered
    }

    {:ok, source} =
      %MetadataSource{}
      |> MetadataSource.changeset(base_attrs)
      |> @repo.insert()

    source
    |> Ecto.Changeset.change(Map.new(overrides))
    |> @repo.update!()
  end

  defp parsed_candidate!(xml) do
    {:ok, parsed} = Parser.parse(xml)
    Import.build_candidate(parsed)
  end

  defp stub_req_returning(xml) when is_binary(xml) do
    Req.Test.stub(@stub, fn conn -> Req.Test.text(conn, xml) end)
    Req.new(plug: {Req.Test, @stub})
  end

  defp unsigned_metadata_xml do
    """
    <EntityDescriptor entityID="https://idp.example.com/metadata" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing">
          <KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
            <X509Data>
              <X509Certificate>MIIDEzCCAfugAwIBAgIUL4tsJefr6QE1KzzBr+YBxOfBqd8wDQYJKoZIhvcNAQELBQAwGTEXMBUGA1UEAwwOcGhhc2UxMC10ZXN0LTEwHhcNMjYwNTA1MjAxODUwWhcNMjYwNjA0MjAxODUwWjAZMRcwFQYDVQQDDA5waGFzZTEwLXRlc3QtMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM1cwb/hjGGAKdoFzQ3ZumZ5w2EwisU6JrZ1tsLZvzuBFDnQwSMIlEBnOZcxVb6gBS1yKytU04m3w8Yuz+poJIHxURndwOtDAs4ogUEriv8Q9snb9dvjhJMUHzt8aFiG/dF8TyCbYqpyeElV6dA+gzACm570t23ZWFv49ucgekmOxomW6EbsuNwD3eH9eU5vLxXjXp/pdZfWHB37yuZbsawYPbZKlmlMUa5iYt+cLqODJJviF9p9XqjnzgEN9MC8vE2LxSHK7sMdWpjEwVRVuIxcNqseewcYIFx0Qp++PrSLkkDhkH4rpkZGOCbrnkxhEwctxyc8F+WbYwuaB3Y20EUCAwEAAaNTMFEwHQYDVR0OBBYEFJqT5ohQRMzc7ciLx25XzHFHrQVtMB8GA1UdIwQYMBaAFJqT5ohQRMzc7ciLx25XzHFHrQVtMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAGRp3+eeSCL/A4uKAV8zh+uYiQurc0ouQr5gBzihRrHMDj1Qf6T9wJgVo70LKpcuGpmrxH4Bqdf7W3s9snC+g+Cg2JK2Y2akMhjJ0W/jeiCc4SYswEbx3FK3oIfM63NPDsxWrFCAVQCK3k2/a2Go2FPZ8EjBTkRKsVGADK7ufYUcoyqEOhdK6+Z6oPE1fBjvoNomETj50YKOkEj2tAeSarR1vNLPihuV/pGsxOAx9QGnC2Vxn1LfU+G1sBJ8LDs/OhHf/H1rJjmgqE85KV3ACm0UV4YYW8XXmRRUQCV7nFG6cS+Gnks2bTwv7OBCV0aYyNmkxkWbGiyNRtwu83BRVdc=</X509Certificate>
            </X509Data>
          </KeyInfo>
        </KeyDescriptor>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.example.com/sso/redirect"/>
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
  end
end
