defmodule Relyra.Security.XML.SeamContractTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML
  alias Relyra.Security.XML.PureBeam

  @tag :xml_seam
  test "xml seam behaviour exposes required callbacks" do
    callbacks =
      XML.behaviour_info(:callbacks)
      |> Enum.map(&elem(&1, 0))

    assert :parse_safely in callbacks
    assert :select_signed_node in callbacks
    assert :canonicalize in callbacks
  end

  @tag :xml_seam
  test "parse_safely tuple contract returns parsed structure, not raw XML binary" do
    xml = "<root><value>ok</value></root>"
    assert {:ok, parsed_doc} = PureBeam.parse_safely(xml)
    refute is_binary(parsed_doc)
  end

  @tag :xml_seam
  test "select_signed_node and canonicalize return typed placeholder errors" do
    assert {:error, %Error{type: :missing_signature}} = PureBeam.select_signed_node(:doc, [])
    assert {:error, %Error{type: :canonicalization_failed}} = PureBeam.canonicalize(:node, [])
  end
end
