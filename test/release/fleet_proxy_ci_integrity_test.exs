defmodule Relyra.FleetProxyCIIntegrityTest do
  use ExUnit.Case, async: true

  @required_checks [
    "security (27, 1.19.5)",
    "security (28, 1.19.5)",
    "fleet-proxy-e2e"
  ]

  @required_check_consumers [
    "scripts/setup_branch_protection.sh",
    ".github/workflows/release-please-automerge.yml",
    ".github/workflows/release-please-pr-checks.yml",
    ".github/workflows/planning-pr-checks.yml"
  ]

  test "required fleet workflow cannot be skipped and retains its scheduled canary" do
    workflow = File.read!(".github/workflows/fleet-proxy-e2e.yml")

    assert workflow =~ "pull_request:"
    refute workflow =~ "paths:"
    refute workflow =~ "paths-ignore:"
    assert workflow =~ "fleet-proxy-e2e:\n    name: fleet-proxy-e2e"
    assert workflow =~ ~s(cron: "17 6 * * *")
    assert workflow =~ "rulestead-main-canary:"
    assert workflow =~ "repository: szTheory/rulestead"
    assert workflow =~ "ref: main"
    assert workflow =~ "test_rulestead_proxy_canary.sh"
    assert workflow =~ "github.event_name == 'schedule'"
  end

  test "hermetic fixture and harness retain pinned lifecycle assertions" do
    fixture = File.read!("test/integration/fleet-proxy-sibling.compose.yml")
    harness = File.read!("scripts/test_fleet_proxy_e2e.sh")
    browser = File.read!("test/browser/fleet_proxy.spec.mjs")

    assert fixture =~ "traefik/whoami:v1.12.0"
    refute fixture =~ "traefik/whoami:latest"
    assert harness =~ "npx playwright test"
    assert harness =~ "docker volume inspect"
    assert harness =~ "proxy_id_first"
    assert harness =~ "proxy_id_second"
    assert harness =~ "sibling.localhost"
    assert harness =~ ~s("${FLEET_COMPOSE[@]}" down --remove-orphans)
    assert harness =~ "docker network inspect"
    assert browser =~ "liveSockets"
    assert browser =~ "setSelectionRange"
    assert browser =~ "horizontallyAccessible"
  end

  test "all required-check consumers stay synchronized" do
    for path <- @required_check_consumers do
      body = File.read!(path)

      for check <- @required_checks do
        assert body =~ check, "#{path} is missing required context #{inspect(check)}"
      end
    end

    {json, 0} =
      System.cmd("bash", ["scripts/setup_branch_protection.sh", "--print-expected-json"])

    for check <- @required_checks do
      assert json =~ check
    end
  end
end
