defmodule Relyra.ReleaseHardeningTest do
  use ExUnit.Case, async: true

  test "release discipline artifacts exist" do
    assert File.exists?("CHANGELOG.md")
    assert File.exists?(".release-please-config.json")
    assert File.exists?(".release-please-manifest.json")
    assert File.exists?(".github/workflows/release-please.yml")
    assert File.exists?(".github/workflows/publish-hex.yml")
  end

  test "release prerequisites are documented" do
    security = File.read!("SECURITY.md")

    assert security =~ "Release prerequisites"
    assert security =~ "domain / namespace"
    assert security =~ "Keycloak"
    assert security =~ "pin"
  end

  test "release CI/CD workflows are wired" do
    mixfile = File.read!("mix.exs")
    release_please = File.read!(".github/workflows/release-please.yml")
    publish_hex = File.read!(".github/workflows/publish-hex.yml")
    parity = File.read!(".github/workflows/release-parity.yml")
    config = File.read!(".release-please-config.json")

    assert mixfile =~ "ci.release"
    assert mixfile =~ "@version"
    assert release_please =~ "googleapis/release-please-action@v4"
    assert release_please =~ "mix ci.release"
    assert release_please =~ "mix ci.security"
    assert release_please =~ "mix hex.publish --yes"
    assert release_please =~ "release_created"
    assert publish_hex =~ "workflow_dispatch"
    assert publish_hex =~ "mix ci.release"
    assert publish_hex =~ "mix ci.security"
    assert publish_hex =~ "mix hex.publish --yes"
    assert parity =~ "mix ci.release"
    assert config =~ "\"release-type\": \"elixir\""
    assert config =~ "\"include-v-in-tag\": true"
  end

  test "changelog exposes an unreleased section" do
    changelog = File.read!("CHANGELOG.md")

    assert changelog =~ "## [Unreleased]"
    assert changelog =~ "Keep a Changelog"
  end
end
