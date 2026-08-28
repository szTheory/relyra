defmodule LedgerLoopWeb.FakeIdPFlowTest do
  @moduledoc """
  End-to-end in-process SP-initiated login flow tests.

  SUCCESS round-trip:
    /saml/<…J0>/login → 302 → /fake_idp/login?SAMLRequest=…&RelayState=…
    → POST /fake_idp/sso (success) → renders self-submitting form
    → POST /saml/<…J0>/acs → 302 / → LoginReceipt inserted

  TAMPERED round-trip:
    Same chain but idp_action = "failure" → ACS returns 400 (no session, no receipt)
    → domain: :login AuditEvent with :digest_mismatch error_code written
    → ConnectionTraceLive renders the typed rejection
  """

  use LedgerLoopWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias LedgerLoop.Accounts.LoginReceipt
  alias LedgerLoop.Demo.Fixtures
  alias LedgerLoop.Demo.Reset
  alias LedgerLoop.Repo
  alias Relyra.Ecto.AuditEvent

  @endpoint LedgerLoopWeb.Endpoint
  @conn_ulid Fixtures.relyra_enabled_scenario_id()
  @demo_admin_username "fake-idp-test-admin"
  @demo_admin_password "fake-idp-test-password"

  # Seed the full demo state so the …J0 connection, cert, saml_identities, and
  # users are present.  Reset.reset! mirrors the production reset path and inserts
  # via Repo.insert_all from the Fixtures module.
  setup do
    Reset.reset!()

    previous_config = Application.get_env(:ledger_loop, :demo_admin_auth)

    Application.put_env(:ledger_loop, :demo_admin_auth,
      username: @demo_admin_username,
      password: @demo_admin_password
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

  # ---------------------------------------------------------------------------
  # Success round-trip
  # ---------------------------------------------------------------------------

  describe "SUCCESS: SP-initiated full round-trip" do
    test "login → fake IdP → ACS verifies → LoginReceipt inserted + redirect /", %{conn: conn} do
      saml_urls = %{
        login: "#{@endpoint.url()}/saml/#{@conn_ulid}/login",
        acs: "#{@endpoint.url()}/saml/#{@conn_ulid}/acs"
      }

      # 1. Hit /saml/<id>/login — must 302 to idp_sso_url (/fake_idp/login) with SAMLRequest + RelayState
      conn1 = get(conn, URI.parse(saml_urls.login).path)
      assert conn1.status == 302
      location = get_resp_header(conn1, "location") |> List.first()
      assert location =~ "/fake_idp/login"
      assert location =~ "SAMLRequest="
      assert location =~ "RelayState="

      # 2. Follow to /fake_idp/login — extract in_response_to from rendered HTML
      uri = URI.parse(location)
      qs = URI.decode_query(uri.query || "")
      saml_request = Map.fetch!(qs, "SAMLRequest")
      relay_state = Map.fetch!(qs, "RelayState")

      conn2 =
        get(build_conn(), "/fake_idp/login", %{
          "SAMLRequest" => saml_request,
          "RelayState" => relay_state
        })

      assert conn2.status == 200
      body2 = response(conn2, 200)

      # The in_response_to hidden field must be present (extracted from the SAMLRequest)
      assert body2 =~ "name=\"in_response_to\""
      in_response_to = extract_hidden_field(body2, "in_response_to")
      assert is_binary(in_response_to) and byte_size(in_response_to) > 0

      # 3. POST /fake_idp/sso (success) → self-submitting form with scoped ACS action
      conn3 =
        post(build_conn(), "/fake_idp/sso", %{
          "idp_action" => "success",
          "RelayState" => relay_state,
          "in_response_to" => in_response_to
        })

      assert conn3.status == 200
      body3 = response(conn3, 200)
      assert body3 =~ "onload=\"document.forms[0].submit()\""
      assert body3 =~ "name=\"SAMLResponse\""
      assert body3 =~ "action=\"#{URI.parse(saml_urls.acs).path}\""
      saml_response = extract_hidden_field(body3, "SAMLResponse")
      assert is_binary(saml_response) and byte_size(saml_response) > 0

      # 4. POST /saml/<id>/acs → relyra verifies → redirect to "/"
      conn4 =
        post(build_conn(), URI.parse(saml_urls.acs).path, %{
          "SAMLResponse" => saml_response,
          "RelayState" => relay_state
        })

      assert conn4.status == 302
      assert get_resp_header(conn4, "location") |> List.first() == "/"

      # 5. A LoginReceipt was inserted for sarah@northstar.example.com
      sarah_user = Fixtures.users() |> Enum.find(&(&1.email == "sarah@northstar.example.com"))
      receipts = Repo.all(from r in LoginReceipt, where: r.user_id == ^sarah_user.id)
      assert length(receipts) >= 1
    end
  end

  # ---------------------------------------------------------------------------
  # Tampered (digest_mismatch) round-trip + trace UI
  # ---------------------------------------------------------------------------

  describe "TAMPERED: typed crypto rejection surfaced in trace UI" do
    test "tampered assertion → no session, digest_mismatch AuditEvent in trace", %{conn: conn} do
      # 1. SP-initiated start
      conn1 = get(conn, "/saml/#{@conn_ulid}/login")
      assert conn1.status == 302
      location = get_resp_header(conn1, "location") |> List.first()
      uri = URI.parse(location)
      qs = URI.decode_query(uri.query || "")
      saml_request = Map.fetch!(qs, "SAMLRequest")
      relay_state = Map.fetch!(qs, "RelayState")

      # 2. Get in_response_to from /fake_idp/login
      conn2 =
        get(build_conn(), "/fake_idp/login", %{
          "SAMLRequest" => saml_request,
          "RelayState" => relay_state
        })

      body2 = response(conn2, 200)
      in_response_to = extract_hidden_field(body2, "in_response_to")

      # 3. POST failure action — Signer.tamper/1 mutates the Assertion NameID post-sign
      conn3 =
        post(build_conn(), "/fake_idp/sso", %{
          "idp_action" => "failure",
          "RelayState" => relay_state,
          "in_response_to" => in_response_to
        })

      body3 = response(conn3, 200)
      tampered_response = extract_hidden_field(body3, "SAMLResponse")

      # 4. POST to ACS — relyra MUST reject with :digest_mismatch
      #    ACS returns 400 (default_error_response), NOT a redirect to "/"
      conn4 =
        post(build_conn(), "/saml/#{@conn_ulid}/acs", %{
          "SAMLResponse" => tampered_response,
          "RelayState" => relay_state
        })

      assert conn4.status == 400
      refute get_resp_header(conn4, "location") |> List.first() == "/"

      # No LoginReceipt inserted for sarah
      sarah_user = Fixtures.users() |> Enum.find(&(&1.email == "sarah@northstar.example.com"))
      receipts = Repo.all(from r in LoginReceipt, where: r.user_id == ^sarah_user.id)
      assert receipts == []

      # 5. LoginTrace flushed a domain: :login AuditEvent for the enabled connection
      enabled_conn =
        Fixtures.relyra_connections() |> Enum.find(&(&1.connection_id == @conn_ulid))

      audit_events =
        Repo.all(
          from e in AuditEvent,
            where: e.connection_record_id == ^enabled_conn.id and e.domain == :login,
            order_by: [desc: e.inserted_at]
        )

      assert length(audit_events) >= 1, "Expected at least one domain: :login AuditEvent"

      latest = List.first(audit_events)
      assert latest.action == :failed

      # Steps are stored in after_summary["steps"] (a map keyed by step_name).
      # The overall_outcome is also in after_summary.
      after_summary = latest.after_summary || %{}
      assert Map.get(after_summary, "overall_outcome") == "error"

      steps_map = Map.get(after_summary, "steps") || %{}

      # The signature.verify step should have error outcome + digest_mismatch code
      sig_step = Map.get(steps_map, "signature.verify") || %{}

      assert Map.get(sig_step, "outcome") == "error",
             "Expected signature.verify step to have outcome=error; steps: #{inspect(steps_map)}"

      assert Map.get(sig_step, "error_code") == "digest_mismatch",
             "Expected digest_mismatch error_code; step: #{inspect(sig_step)}"

      # 6. Mount the ConnectionTraceLive and assert the trace is rendered
      admin_conn =
        build_conn()
        |> put_req_header(
          "authorization",
          Plug.BasicAuth.encode_basic_auth(@demo_admin_username, @demo_admin_password)
        )
        |> init_test_session(%{
          "admin_actor" => "demo_admin",
          "admin_actor_label" => "Demo Administrator",
          "admin_organization_id" => "northstar"
        })

      {:ok, _view, html} = live(admin_conn, "/relyra/admin/connections/#{@conn_ulid}/trace")
      assert html =~ "Login Trace"
      # At least one trace row rendered (the failed attempt we just triggered)
      assert html =~ "login-trace-row-"
      # The trace should surface the rejection (failed action or error outcome)
      assert html =~ "error" or html =~ "failed"
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Extract the value of a hidden input field by name from raw HTML.
  defp extract_hidden_field(html, name) do
    case Regex.run(~r/name="#{Regex.escape(name)}" value="([^"]*)"/, html) do
      [_, value] ->
        value

      nil ->
        case Regex.run(~r/name="#{Regex.escape(name)}"[^>]*value="([^"]*)"/, html) do
          [_, value] -> value
          nil -> nil
        end
    end
  end
end
