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

    test "signer.ex has no Relyra.TestSupport reference" do
      signer_path = Path.join([__DIR__, "../../../lib/ledger_loop/fake_idp/signer.ex"])
      signer_path = Path.expand(signer_path)
      contents = File.read!(signer_path)

      refute String.contains?(contents, "Relyra.TestSupport"),
             "signer.ex must not reference Relyra.TestSupport (undefined in prod path-dep build)"
    end

    test "signer.ex has no hand-rolled canonicalization helper" do
      signer_path = Path.join([__DIR__, "../../../lib/ledger_loop/fake_idp/signer.ex"])
      signer_path = Path.expand(signer_path)
      contents = File.read!(signer_path)

      # Strip comment lines, then check for any local "canonicaliz" usage beyond
      # the two sanctioned relyra calls.
      non_comment_lines =
        contents
        |> String.split("\n")
        |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
        |> Enum.join("\n")

      # The only canonicalization calls allowed are PureBeam.canonicalize and C14N.serialize
      local_canon = Regex.scan(~r/canonicaliz/i, non_comment_lines)

      # Should only appear in the two relyra calls (PureBeam.canonicalize or C14N-related)
      # and NOT as a hand-rolled implementation
      relyra_canon_count =
        Regex.scan(~r/(?:PureBeam\.canonicalize|C14N\.)/, non_comment_lines) |> length()

      assert length(local_canon) == relyra_canon_count,
             "signer.ex must have no hand-rolled canonicalization beyond the relyra engine calls"
    end
  end
end
