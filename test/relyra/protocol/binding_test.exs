defmodule Relyra.Protocol.BindingTest do
  use ExUnit.Case, async: false

  alias Relyra.Protocol.Binding

  setup do
    pem = File.read!("test/fixtures/security/authn_request_signing/golden_signing_key.pem")
    {:ok, signing_pem: pem}
  end

  describe "encode_redirect/3" do
    test "encodes SAMLRequest by default" do
      assert {:ok, result} = Binding.encode_redirect("<xml/>", "relay123")
      assert is_binary(result["SAMLRequest"])
      assert rem(byte_size(result["SAMLRequest"]), 4) == 0
      assert result["RelayState"] == "relay123"
      assert inflate_b64(result["SAMLRequest"]) == "<xml/>"
    end

    test "encodes SAMLResponse when opts type is :response" do
      assert {:ok, result} = Binding.encode_redirect("<xml/>", "relay123", type: :response)
      assert is_binary(result["SAMLResponse"])
      assert result["RelayState"] == "relay123"
      assert inflate_b64(result["SAMLResponse"]) == "<xml/>"
    end
  end

  describe "encode_redirect/3 raw-DEFLATE (OASIS §3.4.4.1)" do
    test "deflate->base64 round-trips byte-identically via :zlib raw-inflate" do
      xml = ~s(<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="id_1"/>)
      {:ok, %{"SAMLRequest" => b64}} = Binding.encode_redirect(xml, "rs")

      assert inflate_b64(b64) == xml
    end

    test "deflate is applied for both signed and unsigned paths (structural anti-regression)" do
      xml = ~s(<x/>)
      {:ok, %{"SAMLRequest" => unsigned_b64}} = Binding.encode_redirect(xml, "rs")
      refute unsigned_b64 == Base.encode64(xml, padding: false)
    end
  end

  describe "encode_redirect/3 signed path (Phase 35 AUTHN-01)" do
    test "returns a signed redirect_query with spec order and signature", %{signing_pem: pem} do
      xml = ~s(<samlp:AuthnRequest ID="id_1"/>)

      assert {:ok, %{redirect_query: bytes}} =
               Binding.encode_redirect(xml, "rs",
                 sign: true,
                 signing_key_pem: pem,
                 connection_id: "binding-test"
               )

      assert String.starts_with?(bytes, "SAMLRequest=")
      assert String.contains?(bytes, "&RelayState=rs")
      assert String.contains?(bytes, "&SigAlg=")
      assert String.contains?(bytes, "&Signature=")
      assert length(String.split(bytes, "&Signature=")) == 2
    end

    test "omits RelayState entirely when nil", %{signing_pem: pem} do
      assert {:ok, %{redirect_query: bytes}} =
               Binding.encode_redirect("<x/>", nil,
                 sign: true,
                 signing_key_pem: pem,
                 connection_id: "binding-test"
               )

      refute String.contains?(bytes, "&RelayState=")
    end

    test "supports adfs_lower percent-encoding", %{signing_pem: pem} do
      assert {:ok, %{redirect_query: bytes}} =
               Binding.encode_redirect("<x/>", "relay/state",
                 sign: true,
                 signing_key_pem: pem,
                 encoding: :adfs_lower,
                 connection_id: "binding-test"
               )

      assert String.contains?(bytes, "%2f")
      refute String.contains?(bytes, "%2F")
    end

    test "defaults to rfc3986_upper percent-encoding", %{signing_pem: pem} do
      assert {:ok, %{redirect_query: bytes}} =
               Binding.encode_redirect("<x/>", "relay/state",
                 sign: true,
                 signing_key_pem: pem,
                 connection_id: "binding-test"
               )

      assert String.contains?(bytes, "%2F")
    end

    test "omits RelayState key from unsigned maps when nil" do
      assert {:ok, result} = Binding.encode_redirect("<x/>", nil)
      refute Map.has_key?(result, "RelayState")
    end
  end

  describe "decode_redirect/2" do
    test "decodes valid SAMLRequest" do
      xml = "<xml/>"

      params = %{
        "SAMLRequest" => Base.encode64(xml, padding: false),
        "RelayState" => "relay456"
      }

      assert {:ok, %{response_xml: decoded_xml, relay_state: rs}} =
               Binding.decode_redirect(params)

      assert decoded_xml == xml
      assert rs == "relay456"
    end

    test "decodes valid SAMLResponse" do
      xml = "<xml/>"

      params = %{
        "SAMLResponse" => Base.encode64(xml, padding: false),
        "RelayState" => "relay456"
      }

      assert {:ok, %{response_xml: decoded_xml, relay_state: rs}} =
               Binding.decode_redirect(params)

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

  defp inflate_b64(b64) do
    {:ok, deflated} = Base.decode64(b64, padding: false)
    z = :zlib.open()

    try do
      :ok = :zlib.inflateInit(z, -15)
      :zlib.inflate(z, deflated) |> IO.iodata_to_binary()
    after
      :zlib.close(z)
    end
  end
end
