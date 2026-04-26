defmodule Relyra.ReleaseHardeningTest do
  use ExUnit.Case, async: true

  test "release discipline artifacts exist" do
    assert File.exists?("CHANGELOG.md")
    assert File.exists?(".release-please-config.json")
    assert File.exists?(".release-please-manifest.json")
  end

  test "release prerequisites are documented" do
    security = File.read!("SECURITY.md")

    assert security =~ "Release prerequisites"
    assert security =~ "domain / namespace"
    assert security =~ "Keycloak"
    assert security =~ "pin"
  end

  test "release parity lane is wired" do
    mixfile = File.read!("mix.exs")
    workflow = File.read!(".github/workflows/release-parity.yml")

    assert mixfile =~ "ci.release"
    assert workflow =~ "release-parity"
    assert workflow =~ "mix ci.release"
  end

  test "changelog exposes an unreleased section" do
    changelog = File.read!("CHANGELOG.md")

    assert changelog =~ "## [Unreleased]"
    assert changelog =~ "Keep a Changelog"
  end
end
