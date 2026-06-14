defmodule LedgerLoop.FakeIdP.SignerTest do
  use ExUnit.Case, async: true

  alias LedgerLoop.FakeIdP.Keypair
  alias LedgerLoop.FakeIdP.Signer
  alias Relyra.Error
  alias Relyra.Security.Signature
  alias Relyra.Security.XML.PureBeam

  # Connection fixture fields — must match the …J0 connection exactly so the
  # full validation pipeline accepts the signed Response.
  @issuer "https://idp.northstar.example.com"
  @acs_url "https://ledgerloop.example.com/sso/acs"
  @sp_entity_id "https://ledgerloop.example.com/sp"
  @name_id "sarah@northstar.example.com"

  defp default_opts do
    [
      issuer: @issuer,
      destination: @acs_url,
      recipient: @acs_url,
      audience: @sp_entity_id,
      name_id: @name_id,
      in_response_to: "test-request-id-001"
    ]
  end

  defp parse_signed_response(b64) do
    xml = Base.decode64!(b64)

    {:ok, parsed_doc} = PureBeam.parse_safely(xml)
    parsed_doc
  end

  defp connection_stub do
    %{connection_id: "01H0B4Y1A2B3C4D5E6F7G8H9J0"}
  end

  # ---------------------------------------------------------------------------
  # Test 1 — byte-compat / V6: signed_response verifies under Relyra's gate
  # ---------------------------------------------------------------------------

  describe "signed_response/1" do
    test "produces a base64 SAMLResponse that Relyra.Security.Signature.verify/4 accepts" do
      b64 = Signer.signed_response(default_opts())
      assert is_binary(b64)

      parsed_doc = parse_signed_response(b64)
      cert_pem = Keypair.cert_pem()

      result = Signature.verify(parsed_doc, connection_stub(), [cert_pem])
      assert {:ok, _signed_node} = result
    end

    test "uses a unique assertion_id per call to prevent replay collisions" do
      b64_1 = Signer.signed_response(default_opts())
      b64_2 = Signer.signed_response(default_opts())

      xml_1 = Base.decode64!(b64_1)
      xml_2 = Base.decode64!(b64_2)

      # Each call must embed a different assertion ID
      refute xml_1 == xml_2
    end
  end

  # ---------------------------------------------------------------------------
  # Test 2 — tamper: NameID mutation → :digest_mismatch
  # ---------------------------------------------------------------------------

  describe "tamper/1" do
    test "returns base64 with a mutated Assertion NameID" do
      b64 = Signer.signed_response(default_opts())
      tampered_b64 = Signer.tamper(b64)

      xml = Base.decode64!(b64)
      tampered_xml = Base.decode64!(tampered_b64)

      refute xml == tampered_xml
      assert String.contains?(tampered_xml, "TAMPERED")
    end

    test "tampered response causes Signature.verify/4 to return {:error, %Error{type: :digest_mismatch}}" do
      b64 = Signer.signed_response(default_opts())
      tampered_b64 = Signer.tamper(b64)

      parsed_doc = parse_signed_response(tampered_b64)
      cert_pem = Keypair.cert_pem()

      result = Signature.verify(parsed_doc, connection_stub(), [cert_pem])
      assert {:error, %Error{type: :digest_mismatch}} = result
    end

    # WR-05: still-tampers — guard does NOT fire on today's live template
    test "WR-05: tampering a signed_response/1 output changes bytes (guard does not fire)" do
      b64 = Signer.signed_response(default_opts())
      tampered_b64 = Signer.tamper(b64)

      # The guard must NOT raise — the real template has a <NameID> to match
      assert b64 != tampered_b64
      tampered_xml = Base.decode64!(tampered_b64)
      assert String.contains?(tampered_xml, "TAMPERED")
    end

    # WR-05: raise — tamper/1 on XML with no <NameID> must raise descriptively
    test "WR-05: raises with descriptive message when XML has no matching <NameID>" do
      # Build a base64 XML payload with no <NameID> element
      xml_without_name_id =
        "<Response><Issuer>https://idp.example.com</Issuer></Response>"

      b64 = Base.encode64(xml_without_name_id)

      assert_raise RuntimeError, ~r/tamper\/1 failed to locate/, fn ->
        Signer.tamper(b64)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Test 4 — WR-01: escaped response_xml/3 — metacharacter in_response_to
  # ---------------------------------------------------------------------------

  describe "WR-01 XML escaping" do
    # The existing verify/4-accepts row (Test 1) covers WR-01 success-path intactness.
    # This row checks that metacharacter-bearing in_response_to does not crash the signer.
    test "WR-01: signed_response/1 with metacharacter in_response_to returns a binary without crashing" do
      opts =
        default_opts()
        |> Keyword.put(:in_response_to, "a<b>&c")

      # The signer must not raise — it re-parses its own emitted XML, which
      # would crash with a MatchError if in_response_to is not escaped first.
      result = Signer.signed_response(opts)
      assert is_binary(result)
    end
  end

  # ---------------------------------------------------------------------------
  # Test 3 — anti-divergence guard: signer.ex must call only relyra's C14N
  # ---------------------------------------------------------------------------

  describe "anti-divergence guard" do
    test "signer.ex contains C14N.serialize and PureBeam.canonicalize calls" do
      signer_path = Path.join([__DIR__, "../../../lib/ledger_loop/fake_idp/signer.ex"])
      signer_path = Path.expand(signer_path)
      contents = File.read!(signer_path)

      assert String.contains?(contents, "C14N.serialize"),
             "signer.ex must call Relyra.Security.XML.C14N.serialize/1 (anti-divergence)"

      assert String.contains?(contents, "PureBeam.canonicalize"),
             "signer.ex must call Relyra.Security.XML.PureBeam.canonicalize/1 (anti-divergence)"
    end

    test "signer.ex has no functional Relyra.TestSupport usage (alias or call)" do
      signer_path = Path.join([__DIR__, "../../../lib/ledger_loop/fake_idp/signer.ex"])
      signer_path = Path.expand(signer_path)
      contents = File.read!(signer_path)

      # Strip comment/doc lines (lines starting with # or lines inside @moduledoc/doc strings)
      # and check that no code aliases or calls Relyra.TestSupport
      non_doc_lines =
        contents
        |> String.split("\n")
        |> Enum.reject(fn line ->
          stripped = String.trim(line)
          String.starts_with?(stripped, "#") or
            String.starts_with?(stripped, "@moduledoc") or
            String.starts_with?(stripped, "@doc") or
            String.starts_with?(stripped, "\"\"\"") or
            # Lines inside doc strings — approximate by rejecting pure prose lines
            (String.contains?(stripped, "Relyra.TestSupport") and
               not String.contains?(stripped, "alias") and
               not String.contains?(stripped, ".") and not String.starts_with?(stripped, "def"))
        end)
        |> Enum.join("\n")

      refute Regex.match?(~r/alias\s+Relyra\.TestSupport|Relyra\.TestSupport\.[A-Z]/, non_doc_lines),
             "signer.ex must not alias or call Relyra.TestSupport.* modules (undefined in prod path-dep build)"
    end

    test "signer.ex defines no local defp/def canonicalization function" do
      signer_path = Path.join([__DIR__, "../../../lib/ledger_loop/fake_idp/signer.ex"])
      signer_path = Path.expand(signer_path)
      contents = File.read!(signer_path)

      # No hand-rolled canonicalization: the module must not define any
      # private/public function whose name contains "canonicalize" or "canonicalization".
      # The only canonicalize *call* must be PureBeam.canonicalize (relyra's engine).
      refute Regex.match?(~r/def(?:p)?\s+canonicaliz/i, contents),
             "signer.ex must not define a local canonicalization function — use PureBeam.canonicalize instead"
    end
  end
end
