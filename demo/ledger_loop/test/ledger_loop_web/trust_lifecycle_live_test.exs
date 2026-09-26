defmodule LedgerLoopWeb.TrustLifecycleLiveTest do
  use LedgerLoopWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias LedgerLoop.Demo.Reset
  alias LedgerLoop.FakeIdP.Keypair
  alias LedgerLoop.Repo
  alias Relyra.ConnectionResolver.Ecto, as: ConnectionResolver
  alias Relyra.Ecto.{AuditEvent, Certificate, Connection, MetadataRevision}

  @draft_connection_id "01H0B4Y1A2B3C4D5E6F7G8H9J1"
  @admin_actor "northstar-admin@example.com"
  @foreign_admin_actor "harborline-admin@example.com"
  @admin_username "trust-lifecycle-test-admin"
  @admin_password "trust-lifecycle-test-password"

  setup do
    Reset.reset!()

    previous_config = Application.get_env(:ledger_loop, :demo_admin_auth)

    Application.put_env(:ledger_loop, :demo_admin_auth,
      username: @admin_username,
      password: @admin_password
    )

    on_exit(fn ->
      if previous_config do
        Application.put_env(:ledger_loop, :demo_admin_auth, previous_config)
      else
        Application.delete_env(:ledger_loop, :demo_admin_auth)
      end
    end)

    :ok
  end

  test "Northstar admin imports reviewed metadata, activates its key, and enables the draft connection" do
    connection = Repo.get_by!(Connection, connection_id: @draft_connection_id)
    assert connection.status == :draft
    assert connection.idp_entity_id == nil

    metadata_view = live_admin("northstar")
    metadata_xml = metadata_xml()

    assert render(metadata_view) =~ "Metadata Management"

    metadata_view
    |> form("form[phx-submit=\"import_metadata\"]", metadata_import: %{xml: "<EntityDescriptor>"})
    |> render_submit()

    unchanged = Repo.get!(Connection, connection.id)
    assert unchanged.status == :draft
    assert unchanged.idp_entity_id == nil
    assert unchanged.active_metadata_revision_id == nil

    assert Repo.aggregate(
             from(event in AuditEvent, where: event.connection_record_id == ^connection.id),
             :count
           ) == 0

    assert Repo.exists?(
             from(revision in MetadataRevision,
               where:
                 revision.connection_record_id == ^connection.id and
                   revision.outcome == :parse_failed
             )
           )

    metadata_view
    |> form("form[phx-submit=\"import_metadata\"]", metadata_import: %{xml: metadata_xml})
    |> render_submit()

    imported = Repo.get!(Connection, connection.id)
    assert imported.idp_entity_id == "https://idp.northstar.example.com"
    assert imported.idp_sso_url == "https://idp.northstar.example.com/sso"
    assert imported.status == :draft
    assert imported.active_metadata_revision_id
    assert imported.active_metadata_revision_id == imported.last_known_good_metadata_revision_id

    revision = Repo.get!(MetadataRevision, imported.active_metadata_revision_id)
    assert revision.outcome == :applied
    assert render(metadata_view) =~ "Active"

    [staged_certificate] =
      Repo.all(
        from(certificate in Certificate,
          where:
            certificate.connection_record_id == ^connection.id and
              certificate.lifecycle_state == :next and certificate.role == :signing
        )
      )

    assert String.trim_trailing(staged_certificate.pem) ==
             String.trim_trailing(Keypair.cert_pem())

    connections_view =
      live_admin("northstar", "/relyra/admin/connections/#{@draft_connection_id}")

    assert render(connections_view) =~ "Draft/Missing Metadata"

    connections_view
    |> form("form[phx-submit=\"confirm_activate_certificate\"]",
      fingerprint: staged_certificate.fingerprint_sha256,
      confirmation: String.slice(staged_certificate.fingerprint_sha256, 0..5)
    )
    |> render_submit()

    connections_view
    |> element("button[data-testid=\"enable-connection-button\"]")
    |> render_click()

    enabled = Repo.get!(Connection, connection.id)
    assert enabled.status == :enabled

    assert {:ok, resolved} =
             ConnectionResolver.resolve_connection(%{connection_id: @draft_connection_id},
               repo: Repo
             )

    assert resolved.idp_certificates == [String.trim_trailing(Keypair.cert_pem())]

    events =
      Repo.all(
        from(event in AuditEvent,
          where: event.connection_record_id == ^connection.id,
          order_by: [asc: event.inserted_at]
        )
      )

    assert Enum.map(events, &{&1.domain, &1.action}) == [
             {:certificate, :staged},
             {:metadata, :applied},
             {:certificate, :activated},
             {:connection, :enabled}
           ]

    assert Enum.all?(events, &(&1.actor == @admin_actor))

    assert Enum.map(events, & &1.cause) == [
             "live_admin_metadata_import",
             "live_admin_metadata_import",
             "live_admin_activate_certificate",
             "live_admin_connection_enable"
           ]

    serialized_events = inspect(events)
    refute serialized_events =~ "<EntityDescriptor"
    refute serialized_events =~ "BEGIN CERTIFICATE"

    refute serialized_events =~
             Base.encode64(:public_key.pem_decode(Keypair.cert_pem()) |> hd() |> elem(1))
  end

  test "Harborline admin cannot view or mutate Northstar trust through the scoped routes" do
    connection = Repo.get_by!(Connection, connection_id: @draft_connection_id)

    before_events =
      Repo.aggregate(
        from(event in AuditEvent, where: event.connection_record_id == ^connection.id),
        :count
      )

    foreign_view =
      live_admin("harborline", "/relyra/admin/connections/#{@draft_connection_id}/metadata")

    refute render(foreign_view) =~ "Northstar Health (Draft/Missing Metadata)"
    refute has_element?(foreign_view, "button[data-testid=\"enable-connection-button\"]")

    assert Repo.get!(Connection, connection.id).status == :draft
    assert Repo.get!(Connection, connection.id).idp_entity_id == nil

    assert Repo.aggregate(
             from(event in AuditEvent, where: event.connection_record_id == ^connection.id),
             :count
           ) == before_events
  end

  defp live_admin(
         organization_id,
         path \\ "/relyra/admin/connections/#{@draft_connection_id}/metadata"
       ) do
    conn =
      build_conn()
      |> put_req_header(
        "authorization",
        Plug.BasicAuth.encode_basic_auth(@admin_username, @admin_password)
      )
      |> init_test_session(%{
        "admin_actor" =>
          if(organization_id == "northstar", do: @admin_actor, else: @foreign_admin_actor),
        "admin_actor_label" => "Tenant Administrator",
        "admin_organization_id" => organization_id
      })

    {:ok, view, _html} = live(conn, path)
    view
  end

  defp metadata_xml do
    certificate =
      Keypair.cert_pem()
      |> String.replace(~r/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s+/, "")

    """
    <EntityDescriptor entityID="https://idp.northstar.example.com" xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
      <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <KeyDescriptor use="signing"><KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#"><X509Data><X509Certificate>#{certificate}</X509Certificate></X509Data></KeyInfo></KeyDescriptor>
        <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.northstar.example.com/sso" />
      </IDPSSODescriptor>
    </EntityDescriptor>
    """
  end
end
