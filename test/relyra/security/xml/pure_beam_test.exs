defmodule Relyra.Security.XML.PureBeamTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML.PureBeam

  @signature_method "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @digest_method "http://www.w3.org/2001/04/xmlenc#sha256"

  test "select_signed_node/2 returns the only signed candidate with signature metadata" do
    assert {:ok, selected_node} = PureBeam.select_signed_node(base_parsed_doc())

    assert selected_node == %{
             xml_id: "assertion-1",
             xpath: "/Response/Assertion[1]",
             signed_xml:
               "  <Assertion ID='assertion-1'>\r\n    signed payload\r\n  </Assertion>\r\n",
             signature_method: @signature_method,
             digest_method: @digest_method
           }
  end

  test "select_signed_node/2 rejects duplicate ids before selecting a node" do
    parsed_doc = base_parsed_doc(%{duplicate_ids: ["dup-1", "dup-1"]})

    assert {:error, %Error{type: :duplicate_xml_id, details: details}} =
             PureBeam.select_signed_node(parsed_doc)

    assert details.duplicate_ids == ["dup-1", "dup-1"]
    assert details.duplicate_count == 2
  end

  test "select_signed_node/2 rejects document-provided key info" do
    parsed_doc = base_parsed_doc(%{key_info_trust: true})

    assert {:error, %Error{type: :untrusted_certificate, details: details}} =
             PureBeam.select_signed_node(parsed_doc)

    assert details.reason == :document_keyinfo_forbidden
  end

  test "select_signed_node/2 rejects ambiguous candidates" do
    parsed_doc =
      base_parsed_doc(%{
        signed_candidates: [
          %{
            xml_id: "assertion-1",
            xpath: "/Response/Assertion[1]",
            signed_xml: "<Assertion>1</Assertion>"
          },
          %{
            xml_id: "assertion-2",
            xpath: "/Response/Assertion[2]",
            signed_xml: "<Assertion>2</Assertion>"
          }
        ]
      })

    assert {:error, %Error{type: :ambiguous_signed_node, details: details}} =
             PureBeam.select_signed_node(parsed_doc)

    assert details.candidate_count == 2
  end

  test "canonicalize/2 normalizes line endings and surrounding whitespace" do
    assert {:ok, selected_node} = PureBeam.select_signed_node(base_parsed_doc())
    assert {:ok, canonical} = PureBeam.canonicalize(selected_node)

    assert canonical == %{
             canonical_xml: "<Assertion ID='assertion-1'>\n    signed payload\n  </Assertion>",
             xml_id: "assertion-1",
             xpath: "/Response/Assertion[1]"
           }
  end

  test "canonicalize/2 rejects invalid signed-node handles" do
    assert {:error, %Error{type: :canonicalization_failed, details: details}} =
             PureBeam.canonicalize(%{xml_id: "assertion-1"})

    assert details.reason == :invalid_signed_node_handle
  end

  defp base_parsed_doc(overrides \\ %{}) do
    Map.merge(
      %{
        key_info_trust: false,
        duplicate_ids: [],
        signature_method: @signature_method,
        digest_method: @digest_method,
        signed_candidates: [
          %{
            xml_id: "assertion-1",
            xpath: "/Response/Assertion[1]",
            signed_xml:
              "  <Assertion ID='assertion-1'>\r\n    signed payload\r\n  </Assertion>\r\n"
          }
        ]
      },
      overrides
    )
  end
end
