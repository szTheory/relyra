defmodule Relyra.Telemetry.Handlers.LoginTraceTest.RequestStore do
  @moduledoc false
  @behaviour Relyra.RequestStore

  @impl true
  def put_intent(_relay_state, _intent, _opts), do: :ok

  @impl true
  def fetch_intent(_relay_state, _opts), do: {:error, :not_used}

  @impl true
  def consume_intent(_relay_state, _request_id, _opts), do: :ok
end

defmodule Relyra.Telemetry.Handlers.LoginTraceTest.ReplayStore do
  @moduledoc false
  @behaviour Relyra.ReplayStore

  @impl true
  def consume_replay_key(_replay_key, _metadata, _opts), do: :ok
end

defmodule Relyra.Telemetry.Handlers.LoginTraceTest do
  use Relyra.TestSupport.MigrationCase, async: false

  import Ecto.Query

  alias Relyra.Ecto.{AuditEvent, Connection}
  alias Relyra.LoginResult
  alias Relyra.Telemetry.Handlers.LoginTrace

  @repo Relyra.TestSupport.EctoTestRepo
  @fixed_now ~U[2026-04-24 16:00:00Z]
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"
  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @digest_sha256 "http://www.w3.org/2001/04/xmlenc#sha256"

  setup do
    _ = LoginTrace.detach()
    :ok = LoginTrace.attach(repo: @repo)

    on_exit(fn ->
      _ = LoginTrace.detach()
      Process.delete(:relyra_validation_trace)
      Process.delete(:relyra_login_trace)
    end)

    connection_record = insert_connection!("conn-123")
    {:ok, connection_record: connection_record}
  end

  test "successful consume appends one :login audit row with :succeeded", %{
    connection_record: connection_record
  } do
    assert {:ok, %LoginResult{validation_trace: validation_trace}} =
             Relyra.consume_response(
               response_xml(),
               request_intent(),
               consume_opts(connection_record)
             )

    assert validation_trace != []

    login_events =
      from(e in AuditEvent,
        where: e.domain == ^:login and e.connection_record_id == ^connection_record.id
      )
      |> @repo.all()

    assert length(login_events) == 1

    event = List.first(login_events)
    assert event.domain == :login
    assert event.action == :succeeded
    assert event.actor == "system:login_trace"
    assert event.cause == "sp_initiated"
    assert event.after_summary["overall_outcome"] == "ok"
    assert is_map(event.after_summary["steps"])
    refute Map.has_key?(event.after_summary, "xml")
    refute Map.has_key?(event.after_summary, "response_xml")
    refute serialized(event.after_summary) =~ "response_xml"
    refute serialized(event.after_summary) =~ ~s("xml")
  end

  test "failed consume appends one :login audit row with :failed", %{
    connection_record: connection_record
  } do
    assert {:error, %Relyra.Error{}} =
             Relyra.consume_response(
               "<not-xml",
               request_intent(),
               consume_opts(connection_record)
             )

    login_events =
      from(e in AuditEvent,
        where: e.domain == ^:login and e.connection_record_id == ^connection_record.id
      )
      |> @repo.all()

    assert length(login_events) == 1
    event = List.first(login_events)
    assert event.action == :failed
    assert event.after_summary["overall_outcome"] == "error"
    refute Map.has_key?(event.after_summary, "xml")
    refute Map.has_key?(event.after_summary, "response_xml")
  end

  defp consume_opts(connection_record) do
    [
      now: @fixed_now,
      relay_state: request_intent().relay_state,
      connection: connection(connection_record.connection_id),
      request_store: __MODULE__.RequestStore,
      replay_store: __MODULE__.ReplayStore
    ]
  end

  defp connection(connection_id) do
    %{
      connection_id: connection_id,
      organization_id: "org-456",
      provider_preset: "okta",
      idp_entity_id: "https://idp.example.com/metadata",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_sso_url: "https://idp.example.com/sso",
      cert_chain: [Relyra.TestSupport.XmldsigSigner.self_signed_cert_pem()]
    }
  end

  defp request_intent do
    %{
      request_id: "id_request_123",
      connection_id: "conn-123",
      relay_state: "rs_1234567890abcdef",
      in_response_to: "id_request_123",
      destination: "https://sp.example.com/saml/acs",
      recipient: "https://sp.example.com/saml/acs",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      return_to: "/account"
    }
  end

  defp response_xml do
    structure_only =
      "<Response Destination=\"https://sp.example.com/saml/acs\" InResponseTo=\"id_request_123\" ConnectionId=\"conn-123\">" <>
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

    %{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.sign_response(structure_only)
    signed_xml
  end

  defp insert_connection!(connection_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      display_name: "Login trace test",
      organization_id: "org_login_trace",
      status: :enabled,
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp serialized(value), do: inspect(value, limit: :infinity, printable_limit: :infinity)
end
