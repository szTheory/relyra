defmodule Relyra.Security.LoginTraceTest.RequestStore do
  @moduledoc false
  @behaviour Relyra.RequestStore

  @impl true
  def put_intent(_relay_state, _intent, _opts), do: :ok

  @impl true
  def fetch_intent(_relay_state, _opts), do: {:error, :not_used}

  @impl true
  def consume_intent(_relay_state, _request_id, _opts), do: :ok
end

defmodule Relyra.Security.LoginTraceTest.ReplayStore do
  @moduledoc false
  @behaviour Relyra.ReplayStore

  @impl true
  def consume_replay_key(_replay_key, _metadata, _opts), do: :ok
end

defmodule Relyra.Security.LoginTraceTest do
  @moduledoc """
  TRACE-02 / TRACE-03: login trace output must never leak raw SAML, PEM, or
  signature material; LiveView and CLI paths must produce redaction-equivalent
  exports via `Relyra.LoginTrace.Export`.
  """
  use Relyra.TestSupport.MigrationCase, async: false

  import Ecto.Query
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Mix.Tasks.Relyra.Trace, as: TraceTask
  alias Relyra.Ecto.{AuditEvent, Connection}
  alias Relyra.LiveAdmin.Query
  alias Relyra.LiveAdmin.Scope
  alias Relyra.LoginTrace.Export
  alias Relyra.Telemetry.Handlers.LoginTrace
  alias Relyra.TestSupport.LiveAdminEndpointSupport
  alias Relyra.TestSupport.XmldsigSigner

  @endpoint Relyra.TestSupport.LiveAdminEndpoint
  @repo Relyra.TestSupport.EctoTestRepo
  @fixed_now ~U[2026-04-24 16:00:00Z]
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"
  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @digest_sha256 "http://www.w3.org/2001/04/xmlenc#sha256"
  @connection_id "conn-security-trace"
  @org_id "org_security_trace"

  setup_all do
    LiveAdminEndpointSupport.ensure_started!()
    :ok
  end

  setup do
    Mix.Task.clear()
    _ = LoginTrace.detach()
    :ok = LoginTrace.attach(repo: @repo)

    on_exit(fn ->
      _ = LoginTrace.detach()
      Process.delete(:relyra_validation_trace)
      Process.delete(:relyra_login_trace)
    end)

    connection_record = insert_connection!()
    fixture = signed_fixture()

    assert {:ok, _result} =
             Relyra.consume_response(
               fixture.response_xml,
               request_intent(),
               consume_opts(connection_record, [fixture.cert_pem])
             )

    {:ok,
     connection_record: connection_record, fixture: fixture, forbidden: forbidden_markers(fixture)}
  end

  test "LiveView login trace HTML omits forbidden SAML, PEM, and signature material", %{
    connection_record: connection_record,
    forbidden: forbidden
  } do
    {:ok, _view, html} =
      live(
        authed_conn(),
        "/admin/connections/#{connection_record.connection_id}/trace"
      )

    refute_forbidden(html, forbidden)
  end

  test "mix relyra.trace CLI output omits forbidden SAML, PEM, and signature material", %{
    connection_record: connection_record,
    forbidden: forbidden
  } do
    Code.ensure_loaded!(@repo)

    output =
      ExUnit.CaptureIO.capture_io(fn ->
        TraceTask.run([
          "--repo",
          Atom.to_string(@repo),
          "--connection",
          connection_record.connection_id
        ])
      end)

    refute_forbidden(output, forbidden)
  end

  test "LiveView and CLI share redaction-equivalent exported login trace maps", %{
    connection_record: connection_record
  } do
    scope = %Scope{actor: "security@test", organization_id: @org_id}
    cli_scope = %Scope{actor: "system:relyra.trace", organization_id: nil}

    {:ok, liveview_traces} =
      Query.get_login_traces(@repo, scope, connection_record.connection_id)

    {:ok, cli_traces} =
      Query.get_login_traces(@repo, cli_scope, connection_record.connection_id)

    audit_exports =
      AuditEvent
      |> where([event], event.connection_record_id == ^connection_record.id)
      |> where([event], event.domain == ^:login)
      |> order_by([event], desc: event.inserted_at)
      |> @repo.all()
      |> Enum.map(&Export.export_login/1)

    assert liveview_traces == cli_traces
    assert liveview_traces == audit_exports
    assert length(liveview_traces) == 1
  end

  defp refute_forbidden(output, forbidden) do
    refute output =~ "-----BEGIN", "output leaked PEM material"
    refute output =~ "<?xml", "output leaked raw XML declaration"
    refute output =~ forbidden.signature_value, "output leaked SignatureValue from fixture"
    refute output =~ forbidden.cert_base64, "output leaked cert base64 from fixture"
    refute output =~ forbidden.raw_correlation, "output leaked raw correlation id"
  end

  defp forbidden_markers(%{response_xml: response_xml, cert_pem: cert_pem}) do
    signature_value =
      case Regex.run(~r/<SignatureValue>([^<]+)<\/SignatureValue>/, response_xml) do
        [_, value] -> value
        _ -> raise "fixture missing SignatureValue"
      end

    cert_base64 =
      cert_pem
      |> String.split("\n")
      |> Enum.reject(&String.starts_with?(&1, "-----"))
      |> Enum.join("")
      |> String.slice(0, 24)

    %{
      signature_value: signature_value,
      cert_base64: cert_base64,
      raw_correlation: request_intent().relay_state
    }
  end

  defp signed_fixture do
    structure_only =
      "<Response Destination=\"https://sp.example.com/saml/acs\" InResponseTo=\"id_request_123\" ConnectionId=\"#{@connection_id}\">" <>
        "<Issuer>https://idp.example.com/metadata</Issuer>" <>
        "<Status><StatusCode Value=\"#{@success_status}\"/></Status>" <>
        "<Assertion ID=\"assertion-1\">" <>
        "<Issuer>https://idp.example.com/metadata</Issuer>" <>
        "<Subject>" <>
        "<NameID>user@example.com</NameID>" <>
        "<SubjectConfirmation>" <>
        "<SubjectConfirmationData Recipient=\"https://sp.example.com/saml/acs\" NotOnOrAfter=\"2026-04-24T16:05:00Z\"/>" <>
        "</SubjectConfirmation>" <>
        "</Subject>" <>
        "<Conditions NotBefore=\"2026-04-24T15:58:00Z\" NotOnOrAfter=\"2026-04-24T16:05:00Z\">" <>
        "<AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction>" <>
        "</Conditions>" <>
        "</Assertion>" <>
        "<Signature>" <>
        "<SignedInfo>" <>
        "<SignatureMethod Algorithm=\"#{@rsa_sha256}\"/>" <>
        "<Reference URI=\"#assertion-1\">" <>
        "<DigestMethod Algorithm=\"#{@digest_sha256}\"/>" <>
        "</Reference>" <>
        "</SignedInfo>" <>
        "</Signature>" <>
        "</Response>"

    %{response_xml: signed_xml, cert_chain: [cert_pem]} =
      XmldsigSigner.sign_response(structure_only)

    %{response_xml: signed_xml, cert_pem: cert_pem}
  end

  defp consume_opts(connection_record, cert_chain) do
    [
      now: @fixed_now,
      relay_state: request_intent().relay_state,
      connection: connection(connection_record.connection_id, cert_chain),
      request_store: __MODULE__.RequestStore,
      replay_store: __MODULE__.ReplayStore
    ]
  end

  defp connection(connection_id, cert_chain) do
    %{
      connection_id: connection_id,
      organization_id: @org_id,
      provider_preset: "okta",
      idp_entity_id: "https://idp.example.com/metadata",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_sso_url: "https://idp.example.com/sso",
      cert_chain: cert_chain
    }
  end

  defp request_intent do
    %{
      request_id: "id_request_123",
      connection_id: @connection_id,
      relay_state: "rs_security_trace_abcdef123456",
      in_response_to: "id_request_123",
      destination: "https://sp.example.com/saml/acs",
      recipient: "https://sp.example.com/saml/acs",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      return_to: "/account"
    }
  end

  defp insert_connection! do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: @connection_id,
      display_name: "Security login trace",
      organization_id: @org_id,
      status: :enabled,
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp authed_conn do
    build_conn()
    |> init_test_session(%{
      "admin_actor" => "security@example.com",
      "admin_actor_label" => "Security Tester",
      "admin_organization_id" => @org_id
    })
  end
end
