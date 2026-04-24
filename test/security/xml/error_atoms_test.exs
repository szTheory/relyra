defmodule Relyra.Security.XML.ErrorAtomsTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML.PureBeam

  @tag :xml_errors
  test "malformed XML consistently maps to :malformed_xml" do
    malformed = "<root>"

    types =
      1..3
      |> Enum.map(fn _ ->
        assert {:error, %Error{type: type}} = PureBeam.parse_safely(malformed)
        type
      end)

    assert Enum.uniq(types) == [:malformed_xml]
  end

  @tag :xml_errors
  test "DOCTYPE payload consistently maps to :doctype_forbidden" do
    payload = "<!DOCTYPE foo><foo/>"

    types =
      1..3
      |> Enum.map(fn _ ->
        assert {:error, %Error{type: type}} = PureBeam.parse_safely(payload)
        type
      end)

    assert Enum.uniq(types) == [:doctype_forbidden]
  end

  @tag :xml_errors
  test "ENTITY payload consistently maps to :entity_expansion_forbidden" do
    payload = "<!ENTITY xxe 'boom'><foo/>"

    types =
      1..3
      |> Enum.map(fn _ ->
        assert {:error, %Error{type: type}} = PureBeam.parse_safely(payload)
        type
      end)

    assert Enum.uniq(types) == [:entity_expansion_forbidden]
  end
end
