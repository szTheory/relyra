defmodule LedgerLoopWeb.FakeIdPControllerTest do
  use LedgerLoopWeb.ConnCase, async: true

  alias LedgerLoop.Demo.Fixtures

  @conn_ulid Fixtures.relyra_enabled_scenario_id()

  # ---------------------------------------------------------------------------
  # Oversized SAMLRequest fixture (WR-04)
  # Deflates a 65 KiB repetitive payload at raw-inflate window (-15) and
  # base64-encodes without padding — produces a deflate stream whose inflated
  # output exceeds the 64 KiB ceiling, triggering the fail-closed nil path.
  # ---------------------------------------------------------------------------
  defp oversized_saml_request do
    large_payload = String.duplicate("A", 65 * 1024)
    compressed = :zlib.compress(large_payload)

    # Re-compress with raw deflate (window -15) to match the inflate/1 window
    z = :zlib.open()
    :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    chunks = :zlib.deflate(z, large_payload, :finish)
    :ok = :zlib.deflateEnd(z)
    :zlib.close(z)

    _ = compressed
    raw_deflated = IO.iodata_to_binary(chunks)
    Base.encode64(raw_deflated, padding: false)
  end

  # ---------------------------------------------------------------------------
  # Malformed-ID SAMLRequest fixture (IN-03/WR-01)
  # A valid deflate stream of XML whose ID attribute contains a non-NCName char.
  # ---------------------------------------------------------------------------
  defp malformed_id_saml_request(id_value) do
    xml =
      ~s(<AuthnRequest ID="#{id_value}" Version="2.0"><Issuer>http://sp.example.com</Issuer></AuthnRequest>)

    z = :zlib.open()
    :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    chunks = :zlib.deflate(z, xml, :finish)
    :ok = :zlib.deflateEnd(z)
    :zlib.close(z)
    Base.encode64(IO.iodata_to_binary(chunks), padding: false)
  end

  describe "GET /fake_idp/login" do
    test "renders the local test support warning banner", %{conn: conn} do
      conn = get(conn, "/fake_idp/login")

      assert html_response(conn, 200) =~ "Local Test Support / FakeIdP"
      assert html_response(conn, 200) =~ "This is a local testing harness"
      assert html_response(conn, 200) =~ "form action=\"/fake_idp/sso\" method=\"post\""
    end

    test "passes through RelayState", %{conn: conn} do
      conn = get(conn, "/fake_idp/login", %{"RelayState" => "my_relay_state"})

      assert html_response(conn, 200) =~ "value=\"my_relay_state\""
    end

    test "renders without in_response_to on direct visit (no SAMLRequest)", %{conn: conn} do
      conn = get(conn, "/fake_idp/login")

      # No hidden in_response_to field when SAMLRequest is absent
      refute html_response(conn, 200) =~ "name=\"in_response_to\""
    end

    # WR-04: oversized-inflating SAMLRequest — must yield in_response_to nil, no crash/hang
    test "WR-04 oversized SAMLRequest inflating >64 KiB yields nil in_response_to (no crash)", %{
      conn: conn
    } do
      b64 = oversized_saml_request()
      conn = get(conn, "/fake_idp/login", %{"SAMLRequest" => b64})

      assert html_response(conn, 200)
      refute html_response(conn, 200) =~ "name=\"in_response_to\""
    end

    # WR-04: garbled bytes → nil (contract preserved)
    test "WR-04 garbled SAMLRequest bytes yield nil in_response_to (fail-closed contract)", %{
      conn: conn
    } do
      conn = get(conn, "/fake_idp/login", %{"SAMLRequest" => "not-valid-base64!!!"})

      assert html_response(conn, 200)
      refute html_response(conn, 200) =~ "name=\"in_response_to\""
    end

    # IN-03/WR-01: non-NCName ID rejected — extractor returns nil
    test "IN-03 SAMLRequest with ID containing '<' (non-NCName) yields nil in_response_to", %{
      conn: conn
    } do
      b64 = malformed_id_saml_request("bad<id")
      conn = get(conn, "/fake_idp/login", %{"SAMLRequest" => b64})

      assert html_response(conn, 200)
      refute html_response(conn, 200) =~ "name=\"in_response_to\""
    end

    # IN-03/WR-01: non-NCName ID with space rejected
    test "IN-03 SAMLRequest with ID containing a space (non-NCName) yields nil in_response_to", %{
      conn: conn
    } do
      b64 = malformed_id_saml_request("bad id")
      conn = get(conn, "/fake_idp/login", %{"SAMLRequest" => b64})

      assert html_response(conn, 200)
      refute html_response(conn, 200) =~ "name=\"in_response_to\""
    end
  end

  describe "POST /fake_idp/sso" do
    test "renders a self-submitting form with a SAMLResponse for success", %{conn: conn} do
      conn =
        post(conn, "/fake_idp/sso", %{
          "idp_action" => "success",
          "RelayState" => "test_relay_state"
        })

      response = html_response(conn, 200)
      assert response =~ "onload=\"document.forms[0].submit()\""
      assert response =~ "name=\"SAMLResponse\""
      assert response =~ "name=\"RelayState\" value=\"test_relay_state\""
      assert response =~ "action=\"/saml/#{@conn_ulid}/acs\""
    end

    test "renders a self-submitting form with a Tampered signature for failure", %{conn: conn} do
      conn = post(conn, "/fake_idp/sso", %{"idp_action" => "failure"})

      response = html_response(conn, 200)
      assert response =~ "onload=\"document.forms[0].submit()\""
      assert response =~ "name=\"SAMLResponse\""
      assert response =~ "action=\"/saml/#{@conn_ulid}/acs\""
    end
  end
end
