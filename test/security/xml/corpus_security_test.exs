defmodule Relyra.Security.XML.CorpusSecurityTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML.PureBeam

  @manifest_path "priv/security_corpus.json"

  @tag :security_corpus
  test "manifest.json fixtures map to expected_error_type for each class" do
    manifest()
    |> Enum.each(fn fixture ->
      assert {:error, %Error{type: type}} = evaluate_fixture(fixture)
      assert type == String.to_atom(fixture["expected_error_type"])
    end)
  end

  @tag :security_corpus
  test "deterministic corpus check runs the same fixture 3 times" do
    manifest()
    |> Enum.take(5)
    |> Enum.each(fn fixture ->
      types =
        1..3
        |> Enum.map(fn _ ->
          assert {:error, %Error{type: type}} = evaluate_fixture(fixture)
          type
        end)

      assert Enum.uniq(types) == [String.to_atom(fixture["expected_error_type"])]
    end)
  end

  @tag :gate02_c14n
  @tag :security_corpus
  test "parser_differential_and_c14n is a binary gate with zero regressions" do
    fixtures =
      manifest()
      |> Enum.filter(&(&1["class"] == "parser_differential_and_c14n"))

    failures =
      Enum.reduce(fixtures, [], fn fixture, acc ->
        expected = String.to_atom(fixture["expected_error_type"])

        case evaluate_fixture(fixture) do
          {:error, %Error{type: type}} ->
            if type == expected do
              acc
            else
              [{fixture["id"], {:unexpected_type, type, expected}} | acc]
            end

          other ->
            [{fixture["id"], other} | acc]
        end
      end)

    assert failures == [],
           "GATE-02 binary gate failed: parser_differential_and_c14n zero regressions violated"
  end

  @tag :security_corpus
  test "every manifest row carries immutable provenance and requirement_ids" do
    manifest()
    |> Enum.each(fn fixture ->
      assert is_list(fixture["requirement_ids"]) and fixture["requirement_ids"] != [],
             "fixture #{fixture["id"]} is missing requirement_ids"

      assert is_binary(fixture["family"]) and String.trim(fixture["family"]) != "",
             "fixture #{fixture["id"]} is missing family"

      assert is_map(fixture["provenance"]) and map_size(fixture["provenance"]) > 0,
             "fixture #{fixture["id"]} is missing provenance"

      assert is_binary(fixture["source_ref"]) and String.trim(fixture["source_ref"]) != "",
             "fixture #{fixture["id"]} is missing source_ref"
    end)
  end

  @tag :security_corpus
  test "the corpus permanently covers xsw, xxe, and CVE-2024-45409 exploit families" do
    families =
      manifest()
      |> Enum.map(& &1["family"])
      |> MapSet.new()

    assert MapSet.member?(families, "signature_wrapping")
    assert MapSet.member?(families, "xxe")
    assert MapSet.member?(families, "CVE-2024-45409")
  end

  defp manifest do
    @manifest_path
    |> File.read!()
    |> :json.decode()
  end

  defp evaluate_fixture(fixture) do
    xml = fixture["xml"] || ""
    opts = if is_integer(fixture["max_bytes"]), do: [max_bytes: fixture["max_bytes"]], else: []

    case fixture["class"] do
      "signature_wrapping" ->
        with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, opts) do
          PureBeam.select_signed_node(parsed_doc, [])
        end

      "keyinfo_misuse" ->
        with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, opts) do
          PureBeam.select_signed_node(parsed_doc, [])
        end

      "cve_2024_45409" ->
        with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, opts) do
          PureBeam.select_signed_node(parsed_doc, [])
        end

      "unsigned_or_partial_signature" ->
        with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, opts) do
          PureBeam.select_signed_node(parsed_doc, [])
        end

      "parser_differential_and_c14n" ->
        with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, opts) do
          PureBeam.canonicalize(parsed_doc, [])
        end

      _other ->
        PureBeam.parse_safely(xml, opts)
    end
  end
end
