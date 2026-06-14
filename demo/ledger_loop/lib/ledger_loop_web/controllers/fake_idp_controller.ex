defmodule LedgerLoopWeb.FakeIdPController do
  @moduledoc """
  Local testing harness — NOT a real Identity Provider.

  Routes:
    GET  /fake_idp/login  — renders the local FakeIdP form, captures InResponseTo
    POST /fake_idp/sso    — calls LedgerLoop.FakeIdP.Signer, self-submits to ACS

  This controller only handles the demo/test path.  Relyra's strict verifier
  (`do_verify/4`) must pass a real cryptographic check — this harness does NOT
  weaken the gate.
  """

  use LedgerLoopWeb, :controller

  alias LedgerLoop.Demo.Fixtures
  alias LedgerLoop.FakeIdP.Signer

  # 64 KiB output ceiling for the bounded inflate loop (WR-04).
  # A SAML AuthnRequest is typically <4 KiB; 64 KiB is ~16× headroom before
  # the fail-closed path triggers.
  @max_inflated_bytes 64 * 1024

  # …J0 connection fixture fields — driven at runtime so they match what
  # Relyra's validation pipeline expects (Pitfall 3).
  defp conn_fields do
    enabled =
      Fixtures.relyra_connections()
      |> Enum.find(&(&1.connection_id == Fixtures.relyra_enabled_scenario_id()))

    %{
      issuer: enabled.idp_entity_id,
      destination: enabled.acs_url,
      recipient: enabled.acs_url,
      audience: enabled.sp_entity_id,
      name_id: "sarah@northstar.example.com"
    }
  end

  @doc """
  GET /fake_idp/login

  Reads the inbound `SAMLRequest` (deflated base64 from SP-initiated redirect),
  inflates it, and extracts the `ID` attribute so it can be threaded as
  `InResponseTo` through the self-submitting POST (Pitfall 2).

  If `SAMLRequest` is absent (direct visit), renders with `in_response_to: nil`;
  the harness form still renders — correlation only matters on the real SP path.
  """
  def login(conn, params) do
    relay_state = params["RelayState"] || params["relay_state"]
    saml_request_b64 = params["SAMLRequest"]

    in_response_to = extract_in_response_to(saml_request_b64)

    render(conn, :login,
      relay_state: relay_state,
      in_response_to: in_response_to
    )
  end

  @doc """
  POST /fake_idp/sso

  Builds a SAML Response via `LedgerLoop.FakeIdP.Signer` and renders the
  self-submitting form pointing at the connection-scoped ACS route.

  `idp_action`: "success" — genuine signature; "failure" — tampered (NameID mutated).
  Any non-"failure" value (including crafted strings, arrays, maps) is treated as
  success — fail safe, no CaseClauseError/500 on crafted input (WR-03).
  """
  def sso(conn, params) do
    action = params["idp_action"] || "success"
    relay_state = params["RelayState"] || params["relay_state"] || ""
    in_response_to = params["in_response_to"]

    fields = conn_fields()
    conn_ulid = Fixtures.relyra_enabled_scenario_id()
    acs_url = "/saml/#{conn_ulid}/acs"

    saml_response =
      case action do
        "failure" ->
          valid_b64 =
            Signer.signed_response(
              issuer: fields.issuer,
              destination: fields.destination,
              recipient: fields.recipient,
              audience: fields.audience,
              name_id: fields.name_id,
              in_response_to: in_response_to
            )

          Signer.tamper(valid_b64)

        _ ->
          # Catch-all: unknown / crafted / missing idp_action → success path (WR-03)
          Signer.signed_response(
            issuer: fields.issuer,
            destination: fields.destination,
            recipient: fields.recipient,
            audience: fields.audience,
            name_id: fields.name_id,
            in_response_to: in_response_to
          )
      end

    render(conn, :sso,
      saml_response: saml_response,
      relay_state: relay_state,
      acs_url: acs_url
    )
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Inflate the deflated base64 SAMLRequest and extract its ID attribute.
  # Mirror Binding.deflate_xml/1: inflateInit window = -15 (raw inflate).
  # Returns nil on absent or garbled input (T-57-13).
  defp extract_in_response_to(nil), do: nil

  defp extract_in_response_to(b64) when is_binary(b64) do
    # The first ID attribute in a well-formed SP AuthnRequest is the root
    # AuthnRequest/@ID (IN-03 first-match assumption). The NCName regex constrains
    # the capture to the xsd:ID/NCName grammar: leading letter or '_', then
    # letters, digits, '.', '-', '_'. Non-name characters (e.g. '<', '&', space)
    # are rejected here before the ID reaches any downstream template (IN-03/WR-01).
    with {:ok, compressed} <- Base.decode64(b64, padding: false),
         {:ok, xml} <- inflate(compressed),
         [_, id] <- Regex.run(~r/\bID="([A-Za-z_][A-Za-z0-9._-]*)"/, xml) do
      id
    else
      _ -> nil
    end
  end

  # Bounded inflate using :zlib.safeInflate/2 (WR-04).
  # Replaces single-shot :zlib.inflate/2 with a loop that accumulates output
  # and aborts to :error when accumulated bytes exceed @max_inflated_bytes.
  # On a malformed stream, safeInflate raises and is caught by rescue _ -> :error.
  # Contract: {:ok, binary} | :error — same as the old inflate/1 so the
  # extract_in_response_to/1 with/else chain maps :error to nil unchanged.
  defp inflate(compressed) do
    z = :zlib.open()

    try do
      :ok = :zlib.inflateInit(z, -15)
      inflate_loop(z, compressed, [], 0)
    rescue
      _ -> :error
    after
      :zlib.close(z)
    end
  end

  defp inflate_loop(z, input, acc, total) do
    case :zlib.safeInflate(z, input) do
      {:continue, output} ->
        chunk = IO.iodata_to_binary(output)
        new_total = total + byte_size(chunk)

        if new_total > @max_inflated_bytes do
          # Overflow — fail closed; caller maps :error to nil (WR-04)
          :error
        else
          # Feed [] to drain the same stream on subsequent safeInflate calls
          inflate_loop(z, [], [chunk | acc], new_total)
        end

      {:finished, output} ->
        chunk = IO.iodata_to_binary(output)
        new_total = total + byte_size(chunk)

        if new_total > @max_inflated_bytes do
          :error
        else
          {:ok, IO.iodata_to_binary(Enum.reverse([chunk | acc]))}
        end
    end
  end
end
