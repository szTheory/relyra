defmodule Relyra.Docs.DemoGuideDriftTest do
  @moduledoc """
  Static contract for the repository-local demo launcher.

  The launcher deliberately keeps its Compose command shapes and banner copy in
  one Makefile. These assertions read that source at runtime so a target rename,
  an accidental topology merge, or a second banner implementation fails in the
  focused documentation lane without needing Docker to be running.
  """
  use ExUnit.Case, async: true

  @makefile_path "Makefile"

  @public_targets ~w(
    proxy up up-build up-d up-d-build down reset reseed nuke logs url open fleet doctor help
  )

  test "Makefile exposes the canonical documented target inventory" do
    makefile = File.read!(@makefile_path)

    assert makefile =~ ".DEFAULT_GOAL := help"
    assert makefile =~ "Relyra demo launcher"

    assert documented_targets(makefile) == MapSet.new(@public_targets),
           "Make help comments must enumerate exactly the public launcher targets"

    Enum.each(@public_targets, fn target ->
      assert makefile =~ "## #{target}:"
    end)
  end

  test "Makefile keeps the solo and fleet Compose shapes literal and separate" do
    makefile = File.read!(@makefile_path)

    assert makefile =~ "SOLO_COMPOSE := docker compose"

    assert makefile =~
             "FLEET_COMPOSE := docker compose -f docker-compose.yml -f docker-compose.proxy.yml"

    assert makefile =~ "PROXY_COMPOSE := docker compose -f docker/traefik/compose.yml"

    refute makefile =~ "$(shell $(SOLO_COMPOSE)"
    refute makefile =~ "$(shell $(FLEET_COMPOSE)"
  end

  test "detached launches render the sole banner only after Compose succeeds" do
    makefile = File.read!(@makefile_path)

    assert_target_contains(makefile, "up-d", [
      "$(SOLO_COMPOSE) up --no-build -d",
      "$(MAKE) --no-print-directory url"
    ])

    assert_target_contains(makefile, "up-d-build", [
      "$(SOLO_COMPOSE) up --build -d",
      "$(MAKE) --no-print-directory url"
    ])
  end

  test "url banner has the complete ordered browser contract" do
    makefile = File.read!(@makefile_path)
    url_recipe = target_body(makefile, "url")

    assert_in_order(url_recipe, [
      "==> Browser origins",
      "http://$(RELYRA_HOST)",
      "http://localhost:$(PORT)",
      "==> Route map",
      "Home: http://$(RELYRA_HOST)/",
      "Admin: http://$(RELYRA_HOST)/relyra/admin",
      "Login test: http://$(RELYRA_HOST)/login/test",
      "Support scenario: http://$(RELYRA_HOST)/support/scenario",
      "Health: http://$(RELYRA_HOST)/healthz",
      "http://keycloak.$(RELYRA_HOST)/admin",
      "http://localhost:8080/dashboard/",
      "==> Walkthrough",
      "1. Open Login test",
      "2. Choose FakeIdP",
      "3. Complete the sign-in",
      "4. Inspect the operator trace",
      "==> Topology notes",
      "*.localhost is browser-facing; Docker health checks and internal probes use service DNS."
    ])

    assert url_recipe =~ "OPTIONAL — fleet + keycloak profile"
    assert url_recipe =~ "OPTIONAL — shared fleet proxy"
  end

  defp documented_targets(makefile) do
    ~r/^## ([a-z0-9-]+):/m
    |> Regex.scan(makefile, capture: :all_but_first)
    |> Enum.map(fn [target] -> target end)
    |> MapSet.new()
  end

  defp assert_target_contains(makefile, target, expected_lines) do
    body = target_body(makefile, target)
    Enum.each(expected_lines, &assert(body =~ &1))
  end

  defp target_body(makefile, target) do
    pattern = ~r/^#{Regex.escape(target)}:\n((?:\t.*\n?)*)/m

    case Regex.run(pattern, makefile, capture: :all_but_first) do
      [body] -> body
      nil -> flunk("Missing Make target: #{target}")
    end
  end

  defp assert_in_order(text, tokens) do
    Enum.reduce(tokens, -1, fn token, previous_index ->
      case :binary.match(text, token) do
        {index, _length} when index > previous_index ->
          index

        {index, _length} ->
          flunk("Expected #{inspect(token)} after byte #{previous_index}, found at #{index}")

        :nomatch ->
          flunk("Missing banner token: #{inspect(token)}")
      end
    end)
  end
end
