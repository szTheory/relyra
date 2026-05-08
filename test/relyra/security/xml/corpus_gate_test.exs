defmodule Relyra.Security.XML.CorpusGateTest do
  use ExUnit.Case, async: true
  alias Relyra.Error
  alias Relyra.Security.XML.CorpusGate

  describe "manifest/0 + manifest_path/0" do
    test "loads the priv/security_corpus.json manifest at compile time" do
      assert is_list(CorpusGate.manifest())
      assert String.ends_with?(CorpusGate.manifest_path(), "priv/security_corpus.json")
    end

    test "the manifest contains at least one fixture (proves the move from test/fixtures succeeded)" do
      # The test corpus is non-trivial; if this is empty, the move broke.
      assert length(CorpusGate.manifest()) > 0
    end
  end

  describe "check/2 against well-formed minimal XML" do
    test "returns :ok for a benign XML payload that does not trip any corpus fixture" do
      # A minimal benign EntityDescriptor (no signature wrapping, no namespace confusion)
      xml =
        ~s(<?xml version="1.0"?><EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://example.com"></EntityDescriptor>)

      # The hardened parser may reject this for OTHER reasons (missing required children),
      # which is fine — the gate either returns :ok OR returns the parser's own error.
      # A :corpus_violation MUST NOT fire for a benign sample.
      case CorpusGate.check(xml) do
        :ok -> :ok
        {:error, %Error{type: type}} -> refute type == :corpus_violation
      end
    end
  end

  describe "check/2 against fixture-known-bad XML" do
    @tag :security_corpus
    test "returns {:error, :corpus_violation} for at least one corpus fixture (canary)" do
      # Pick the first fixture that carries inline XML and verify the gate refuses it.
      fixture =
        Enum.find(CorpusGate.manifest(), fn f ->
          is_binary(Map.get(f, "xml")) and Map.get(f, "xml") != ""
        end)

      if fixture do
        assert {:error, %Error{type: :corpus_violation} = err} =
                 CorpusGate.check(Map.fetch!(fixture, "xml"))

        assert err.details.matched_fixture_id == Map.get(fixture, "id")
      else
        # If no fixture carries inline XML, the gate is misconfigured for runtime use.
        flunk(
          "Corpus manifest has no inline-XML fixture; CorpusGate cannot canary-test runtime refusal."
        )
      end
    end

    @tag :security_corpus
    test "compile-time manifest canary still exposes a pinned CVE-2024-45409 fixture ID" do
      fixture =
        Enum.find(CorpusGate.manifest(), fn row ->
          row["family"] == "CVE-2024-45409"
        end)

      assert fixture, "expected a pinned CVE-2024-45409 fixture in the runtime manifest"

      assert {:error,
              %Error{type: :corpus_violation, details: %{matched_fixture_id: matched_fixture_id}}} =
               CorpusGate.check(Map.fetch!(fixture, "xml"))

      assert matched_fixture_id == fixture["id"]
    end
  end
end
