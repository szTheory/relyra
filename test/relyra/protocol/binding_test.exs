defmodule Relyra.Protocol.BindingTest do
  use ExUnit.Case, async: true

  alias Relyra.Protocol.Binding

  describe "encode_redirect/3" do
    test "encodes SAMLRequest by default" do
      assert {:ok, result} = Binding.encode_redirect("<xml/>", "relay123")
      assert result["SAMLRequest"] == Base.encode64("<xml/>", padding: false)
      assert result["RelayState"] == "relay123"
    end

    test "encodes SAMLResponse when opts type is :response" do
      assert {:ok, result} = Binding.encode_redirect("<xml/>", "relay123", type: :response)
      assert result["SAMLResponse"] == Base.encode64("<xml/>", padding: false)
      assert result["RelayState"] == "relay123"
    end
  end

  describe "decode_redirect/2" do
    test "decodes valid SAMLRequest" do
      xml = "<xml/>"
      params = %{
        "SAMLRequest" => Base.encode64(xml, padding: false),
        "RelayState" => "relay456"
      }

      assert {:ok, %{response_xml: decoded_xml, relay_state: rs}} = Binding.decode_redirect(params)
      assert decoded_xml == xml
      assert rs == "relay456"
    end

    test "decodes valid SAMLResponse" do
      xml = "<xml/>"
      params = %{
        "SAMLResponse" => Base.encode64(xml, padding: false),
        "RelayState" => "relay456"
      }

      assert {:ok, %{response_xml: decoded_xml, relay_state: rs}} = Binding.decode_redirect(params)
      assert decoded_xml == xml
      assert rs == "relay456"
    end

    test "returns error when both are missing" do
      params = %{"RelayState" => "relay456"}
      assert {:error, error} = Binding.decode_redirect(params)
      assert error.type == :invalid_binding_payload
      assert error.message == "SAMLRequest or SAMLResponse is required for HTTP-Redirect binding"
    end
  end
end
