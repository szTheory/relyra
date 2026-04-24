defmodule Relyra.Protocol.RelayStateTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.RelayState

  @manifest_path "test/fixtures/security/relay_state/manifest.json"

  test "manifest fixtures enforce opaque relay state policy" do
    @manifest_path
    |> load_manifest!()
    |> Enum.each(&assert_fixture/1)
  end

  defp assert_fixture(%{
         "relay_state" => relay_state,
         "expected_error_type" => nil
       }) do
    assert {:ok, ^relay_state} = RelayState.validate(relay_state)
  end

  defp assert_fixture(%{
         "relay_state" => relay_state,
         "expected_error_type" => "relay_state_rejected",
         "expected_reason" => reason
       }) do
    assert {:error, %Error{type: :relay_state_rejected, details: details}} =
             RelayState.validate(relay_state)

    case reason do
      "raw_url" -> assert details.reason == :raw_url
      "invalid_format" -> assert details.reason == :invalid_format
      "tampered" -> assert details.reason == :tampered
    end
  end

  defp load_manifest!(path) do
    path
    |> File.read!()
    |> String.replace("{", "%{")
    |> String.replace(~r/"([^"\\]+)"\s*:/, "\"\\1\" =>")
    |> String.replace("null", "nil")
    |> Code.eval_string([], __ENV__)
    |> elem(0)
  end
end
