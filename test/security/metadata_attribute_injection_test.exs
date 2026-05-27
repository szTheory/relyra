defmodule Relyra.Security.MetadataAttributeInjectionTest do
  @moduledoc """
  TD-01 (WR-03): adversarial corpus for dynamic attribute interpolation in
  `Relyra.Protocol.Metadata.build_sp_metadata/2`.

  Proves `entityID` and `Location` attribute values escape XML metacharacters
  and control characters before serialization.
  """
  use ExUnit.Case, async: true

  alias Relyra.Protocol.Metadata

  test "entityID attribute escapes XML metacharacters and control chars" do
    adversarial = "https://sp.example.com/&<>\"\t"

    connection = %{
      sp_entity_id: adversarial,
      acs_url: "https://sp.example.com/acs"
    }

    xml = Metadata.build_sp_metadata(connection)

    refute String.contains?(xml, ~s(entityID="#{adversarial}"))
    assert xml =~ "entityID=\"https://sp.example.com/&amp;&lt;>&quot;&#x9;\""
  end

  test "Location attribute escapes XML metacharacters and control chars" do
    adversarial = "https://sp.example.com/acs?x=&<>\"\t"

    connection = %{
      sp_entity_id: "https://sp.example.com",
      acs_url: adversarial
    }

    xml = Metadata.build_sp_metadata(connection)

    refute String.contains?(xml, ~s(Location="#{adversarial}"))
    assert xml =~ "&amp;"
    assert xml =~ "&lt;"
    assert xml =~ "&quot;"
    assert xml =~ "&#x9;"
  end

  test "newline in entityID is escaped as &#xA;" do
    connection = %{
      sp_entity_id: "https://sp.example.com/\nentity",
      acs_url: "https://sp.example.com/acs"
    }

    xml = Metadata.build_sp_metadata(connection)

    refute String.contains?(xml, "entityID=\"https://sp.example.com/\nentity\"")
    assert xml =~ "&#xA;"
  end
end
