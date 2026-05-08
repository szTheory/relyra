defmodule Relyra.TestSupport.ConformanceFixturesTest do
  use ExUnit.Case, async: true

  alias Relyra.TestSupport.ConformanceFixtures

  test "load_manifest!/1 preserves manifest row ordering and loads fixture xml" do
    manifest_path =
      write_manifest!(
        [
          %{
            "id" => "conf-pass-001",
            "requirement_ids" => ["CONF-01"],
            "provenance" => %{"source" => "spec-a"},
            "status" => "pass",
            "xml_path" => "fixtures/pass.xml"
          },
          %{
            "id" => "conf-reject-001",
            "requirement_ids" => ["CVE-REG-01"],
            "provenance" => %{"source" => "spec-b"},
            "status" => "reject",
            "xml" => "<Response ID='reject-1'/>"
          },
          %{
            "id" => "conf-unsupported-001",
            "requirement_ids" => ["CONF-01"],
            "provenance" => %{"source" => "spec-c"},
            "status" => "unsupported"
          },
          %{
            "id" => "conf-deferred-001",
            "requirement_ids" => ["CVE-REG-01"],
            "provenance" => %{"source" => "spec-d"},
            "status" => "deferred"
          }
        ],
        %{"fixtures/pass.xml" => "<Response ID='pass-1'/>\n"}
      )

    rows = ConformanceFixtures.load_manifest!(manifest_path)

    assert Enum.map(rows, & &1["id"]) == [
             "conf-pass-001",
             "conf-reject-001",
             "conf-unsupported-001",
             "conf-deferred-001"
           ]

    assert Enum.map(ConformanceFixtures.executed_rows(rows), & &1["id"]) == [
             "conf-pass-001",
             "conf-reject-001"
           ]

    assert Enum.map(ConformanceFixtures.coverage_rows(rows), & &1["id"]) == [
             "conf-pass-001",
             "conf-reject-001",
             "conf-unsupported-001",
             "conf-deferred-001"
           ]

    assert ConformanceFixtures.fixture_xml(Enum.at(rows, 0)) == "<Response ID='pass-1'/>\n"
  end

  test "load_manifest!/1 raises when required provenance or fixture keys are missing" do
    manifest_path =
      write_manifest!([
        %{
          "id" => "conf-missing-keys-001",
          "requirement_ids" => ["CONF-01"]
        }
      ])

    assert_raise ArgumentError, ~r/missing keys/i, fn ->
      ConformanceFixtures.load_manifest!(manifest_path)
    end
  end

  test "unsupported and deferred rows stay visible to reporting while excluded from execution" do
    rows = [
      %{"id" => "pass-1", "status" => "pass"},
      %{"id" => "reject-1", "status" => "reject"},
      %{"id" => "unsupported-1", "status" => "unsupported"},
      %{"id" => "deferred-1", "status" => "deferred"}
    ]

    assert Enum.map(ConformanceFixtures.executed_rows(rows), & &1["status"]) == ["pass", "reject"]
    assert Enum.map(ConformanceFixtures.coverage_rows(rows), & &1["status"]) == ["pass", "reject", "unsupported", "deferred"]
  end

  defp write_manifest!(rows, extra_files \\ %{}) do
    tmp_dir = Path.join(System.tmp_dir!(), "relyra-conformance-#{System.unique_integer([:positive])}")
    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    Enum.each(extra_files, fn {relative_path, contents} ->
      path = Path.join(tmp_dir, relative_path)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, contents)
    end)

    manifest_path = Path.join(tmp_dir, "manifest.json")
    File.write!(manifest_path, Jason.encode!(rows, pretty: true))
    manifest_path
  end
end
