defmodule Relyra.Protocol.ConsumeResponsePipelineTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Protocol.ValidationPipeline

  @manifest_path "test/fixtures/security/protocol/manifest.json"
  @valid_response "<Response><Assertion>signed</Assertion></Response>"
  @fixed_now ~U[2026-04-24 16:00:00Z]
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"

  test "ordered_stages/0 returns the strict consume order" do
    assert ValidationPipeline.ordered_stages() == [
             :parse_safely,
             :issuer_connection_match,
             :signature_verify,
             :signed_node_bind,
             :status,
             :destination,
             :audience,
             :recipient,
             :time_conditions
           ]
  end

  test "manifest fixtures map to typed consume_response/3 failures" do
    manifest()
    |> Enum.each(fn fixture ->
      assert {:error, %Relyra.Error{type: expected_type}} =
               Relyra.consume_response(
                 @valid_response,
                 request_intent(),
                 consume_opts(payload: fixture["payload"], now: @fixed_now)
               )

      assert expected_type == String.to_atom(fixture["expected_error_type"])
    end)
  end

  test "skew_seconds boundary accepts exact edge and rejects edge+1" do
    exact_edge_payload = %{
      "status" => @success_status,
      "assertion_times" => %{
        "not_before" => DateTime.add(@fixed_now, 120, :second) |> DateTime.to_iso8601(),
        "not_on_or_after" => DateTime.add(@fixed_now, -120, :second) |> DateTime.to_iso8601(),
        "subject_confirmation_not_on_or_after" =>
          DateTime.add(@fixed_now, -120, :second) |> DateTime.to_iso8601()
      }
    }

    assert {:ok, login_result} =
             Relyra.consume_response(
               @valid_response,
               request_intent(),
               consume_opts(payload: exact_edge_payload, now: @fixed_now, skew_seconds: 120)
             )

    assert is_map(login_result)

    edge_plus_one_payload = %{
      "status" => @success_status,
      "assertion_times" => %{
        "not_before" => DateTime.add(@fixed_now, 121, :second) |> DateTime.to_iso8601(),
        "not_on_or_after" => DateTime.add(@fixed_now, 600, :second) |> DateTime.to_iso8601(),
        "subject_confirmation_not_on_or_after" =>
          DateTime.add(@fixed_now, 600, :second) |> DateTime.to_iso8601()
      }
    }

    assert {:error, %Error{type: :assertion_not_yet_valid}} =
             Relyra.consume_response(
               @valid_response,
               request_intent(),
               consume_opts(payload: edge_plus_one_payload, now: @fixed_now, skew_seconds: 120)
             )
  end

  test "clock skew config rejects invalid skew_seconds values" do
    assert {:error, %Error{type: :clock_skew_exceeded}} =
             Relyra.consume_response(
               @valid_response,
               request_intent(),
               consume_opts(now: @fixed_now, skew_seconds: -1)
             )
  end

  test "consume_response/3 only returns typed success or typed error tuples" do
    success_result =
      Relyra.consume_response(@valid_response, request_intent(), consume_opts(now: @fixed_now))

    error_result =
      Relyra.consume_response(
        @valid_response,
        request_intent(),
        consume_opts(payload: %{"status" => "urn:oasis:names:tc:SAML:2.0:status:Responder"}, now: @fixed_now)
      )

    Enum.each([success_result, error_result], fn result ->
      assert match?({:ok, %{}}, result) or match?({:error, %Relyra.Error{}}, result)
    end)
  end

  defp request_intent do
    %{
      request_id: "id_request_123",
      connection_id: "conn-123",
      relay_state: "rs_1234567890abcdef",
      in_response_to: "id_request_123",
      destination: "https://sp.example.com/saml/acs",
      recipient: "https://sp.example.com/saml/acs"
    }
  end

  defp connection do
    %{
      connection_id: "conn-123",
      idp_entity_id: "https://idp.example.com/metadata",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      cert_chain: ["pem-cert-chain"]
    }
  end

  defp consume_opts(extra_opts) do
    Keyword.merge([connection: connection()], extra_opts)
  end

  defp manifest do
    @manifest_path
    |> File.read!()
    |> :json.decode()
  end
end
