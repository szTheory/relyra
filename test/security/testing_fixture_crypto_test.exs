defmodule Relyra.Security.TestingFixtureCryptoTest do
  @moduledoc """
  Public `Relyra.Testing` fixture crypto proof.

  This suite covers the curated public negative fixtures that Hex adopters can
  copy into their own tests. It is deliberately separate from the private
  adversarial corpus and proves each fixture through `Relyra.consume_response/3`.
  """
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Testing
  alias Relyra.Testing.Fixture

  @fixed_now ~U[2026-04-24 16:00:00Z]

  describe "public negative fixtures" do
    test "wrong_audience/1 rejects with exact :invalid_audience through consume_response/3" do
      fixture =
        Testing.wrong_audience(
          expected_audience: "https://sp.example.com/metadata",
          actual_audience: "https://evil.example.com/metadata",
          request_id: "id_request_wrong_audience",
          assertion_id: "assertion-wrong-audience",
          relay_state: "rs_wrong_audience",
          not_before: "2026-04-24T15:55:00Z",
          not_on_or_after: "2026-04-24T16:05:00Z",
          subject_confirmation_not_on_or_after: "2026-04-24T16:05:00Z"
        )

      assert %Fixture{expected: {:error, :invalid_audience}} = fixture
      assert fixture.connection.sp_entity_id == "https://sp.example.com/metadata"
      assert fixture.response_xml =~ "https://evil.example.com/metadata"

      assert {:error, %Error{type: :invalid_audience}} =
               Relyra.consume_response(
                 fixture.response_xml,
                 fixture.request_intent,
                 Testing.consume_opts(fixture, now: @fixed_now)
               )
    end

    test "tampered_digest/1 rejects with exact :digest_mismatch through consume_response/3" do
      fixture =
        Testing.tampered_digest(
          request_id: "id_request_tampered_digest",
          assertion_id: "assertion-tampered-digest",
          relay_state: "rs_tampered_digest",
          name_id: "alice@example.com",
          tampered_name_id: "attacker@example.com",
          not_before: "2026-04-24T15:55:00Z",
          not_on_or_after: "2026-04-24T16:05:00Z",
          subject_confirmation_not_on_or_after: "2026-04-24T16:05:00Z"
        )

      assert %Fixture{expected: {:error, :digest_mismatch}} = fixture
      assert fixture.response_xml =~ "<NameID>attacker@example.com</NameID>"

      assert {:error, %Error{type: :digest_mismatch}} =
               Relyra.consume_response(
                 fixture.response_xml,
                 fixture.request_intent,
                 Testing.consume_opts(fixture, now: @fixed_now)
               )
    end

    test "invalid_signature/1 rejects with exact :invalid_signature through consume_response/3" do
      fixture =
        Testing.invalid_signature(
          request_id: "id_request_invalid_signature",
          assertion_id: "assertion-invalid-signature",
          relay_state: "rs_invalid_signature",
          not_before: "2026-04-24T15:55:00Z",
          not_on_or_after: "2026-04-24T16:05:00Z",
          subject_confirmation_not_on_or_after: "2026-04-24T16:05:00Z"
        )

      assert %Fixture{expected: {:error, :invalid_signature}} = fixture

      assert {:error, %Error{type: :invalid_signature}} =
               Relyra.consume_response(
                 fixture.response_xml,
                 fixture.request_intent,
                 Testing.consume_opts(fixture, now: @fixed_now)
               )
    end
  end

  test "public testing crypto suite does not alias the private signature gate directly" do
    alias_lines =
      __ENV__.file
      |> File.read!()
      |> String.split("\n")
      |> Enum.filter(&Regex.match?(~r/^\s*alias Relyra\.Security\.Signature\b/, &1))

    assert alias_lines == []
  end
end
