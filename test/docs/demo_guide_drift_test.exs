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
      "http://$${RELYRA_HOST}",
      "http://localhost:$${PORT}",
      "==> Route map",
      "Home: http://$${RELYRA_HOST}/",
      "Admin: http://$${RELYRA_HOST}/relyra/admin",
      "Login test: http://$${RELYRA_HOST}/login/test",
      "Support scenario: http://$${RELYRA_HOST}/support/scenario",
      "Health: http://$${RELYRA_HOST}/healthz",
      "http://keycloak.$${RELYRA_HOST}/admin",
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

  test "Make CLI renders help, detached launch, and overridden browser origins" do
    {help, 0} = run_make(["help"])
    assert String.starts_with?(help, "Relyra demo launcher\n")

    {launch, 0} = run_make(["-n", "up-d"])
    assert launch =~ "docker compose up --no-build -d"
    assert launch =~ "make --no-print-directory url"

    {banner, 0} =
      run_make(["url"], [{"PORT", "4100"}, {"RELYRA_HOST", "alt.relyra.localhost"}])

    assert banner =~ "Proxy: http://alt.relyra.localhost"
    assert banner =~ "Loopback: http://localhost:4100"
    assert banner =~ "OPTIONAL — fleet + keycloak profile"
    assert banner =~ "OPTIONAL — shared fleet proxy"
  end

  test "failed detached startup preserves the Docker error and suppresses the banner" do
    fixture_bin = fixture_bin!()
    on_exit(fn -> File.rm_rf!(fixture_bin) end)

    write_executable!(fixture_bin, "docker", """
    #!/bin/sh
    echo "simulated Docker failure" >&2
    exit 42
    """)

    {output, status} = run_make(["up-d"], [{"PATH", fixture_bin}])

    assert status != 0
    assert output =~ "simulated Docker failure"
    refute output =~ "==> Browser origins"
  end

  test "legacy demo verbs delegate exclusively to canonical Make targets" do
    script = File.read!("scripts/demo")

    mappings = %{
      "doctor" => "doctor",
      "up" => "up-d",
      "reset" => "reset",
      "test" => "demo-test",
      "urls" => "url",
      "down" => "down"
    }

    arms =
      ~r/^  ([a-z]+)\)$/m
      |> Regex.scan(script, capture: :all_but_first)
      |> Enum.map(fn [verb] -> verb end)
      |> MapSet.new()

    assert arms == MapSet.new(Map.keys(mappings))

    Enum.each(mappings, fn {verb, target} ->
      assert script =~ "  #{verb})\n    exec make #{target}\n"
    end)

    refute script =~ "docker compose"
    refute script =~ "http://"
  end

  test "reset, nuke, and optional environment configuration stay fail-closed" do
    {reset, 0} = run_make(["-n", "reset"])
    {reseed, 0} = run_make(["-n", "reseed"])

    assert reset == reseed
    assert reset =~ "docker compose exec demo_app mix do ecto.drop, ecto.setup"

    fixture_bin = fixture_bin!()
    on_exit(fn -> File.rm_rf!(fixture_bin) end)
    docker_log = Path.join(fixture_bin, "docker.log")

    write_executable!(fixture_bin, "docker", """
    #!/bin/sh
    printf '%s\n' "$*" >> "$STUB_DOCKER_LOG"
    """)

    env = [{"PATH", fixture_bin}, {"STUB_DOCKER_LOG", docker_log}]
    {declined, 0} = run_make_with_input(["nuke"], "n", env)

    assert declined =~
             "NUKE will permanently delete this Relyra demo's database, build, dependency, Hex, and Mix volumes. Continue? [y/N]"

    assert declined =~ "The next boot is a cold rebuild."
    refute File.exists?(docker_log)

    {approved, 0} = run_make(["nuke"], [{"NUKE", "1"} | env])
    assert approved =~ "The next boot is a cold rebuild."
    assert File.read!(docker_log) == "compose down -v\n"

    env_example = File.read!(".env.example")

    Enum.each(
      ~w(PORT RELYRA_HOST DEMO_PROXY_NETWORK DEMO_ADMIN_USERNAME DEMO_ADMIN_PASSWORD KEYCLOAK_SARAH_PASSWORD),
      fn key -> assert env_example =~ ~r/^# #{key}=/m end
    )

    refute env_example =~ ~r/^[A-Z][A-Z0-9_]*=/m
    assert env_example =~ "demo-only"
    assert env_example =~ "not suitable for production"
  end

  test "fleet distinguishes error, empty, partial, and populated Docker states" do
    fixture_bin = fixture_bin!()
    on_exit(fn -> File.rm_rf!(fixture_bin) end)
    link_tool!(fixture_bin, "awk")
    link_tool!(fixture_bin, "sort")

    write_executable!(fixture_bin, "docker", """
    #!/bin/sh
    case "$STUB_DOCKER_MODE" in
      error)
        echo "Cannot connect to the Docker daemon" >&2
        exit 17
        ;;
      empty)
        exit 0
        ;;
      rows)
        printf '%s' "$STUB_DOCKER_OUTPUT"
        ;;
    esac
    """)

    path_env = [{"PATH", fixture_bin}]

    {error, error_status} = run_make(["fleet"], [{"STUB_DOCKER_MODE", "error"} | path_env])
    assert error_status != 0
    assert error =~ "ERROR fleet query — Cannot connect to the Docker daemon"
    assert error =~ "Next: docker info"
    refute error =~ "No Traefik-routed demo containers running."

    {empty, 0} = run_make(["fleet"], [{"STUB_DOCKER_MODE", "empty"} | path_env])
    assert empty == "No Traefik-routed demo containers running.\nNext: make proxy\n"

    long_ports = "127.0.0.1:12345678901234567890->4000/tcp"

    rows =
      "zeta\tcharlie\tUp 1 hour\t#{long_ports}\n" <>
        "alpha\tbravo\tUp 2 hours\t\n" <>
        "\talpha\t\t\n"

    {populated, 0} =
      run_make(
        ["fleet"],
        [{"STUB_DOCKER_MODE", "rows"}, {"STUB_DOCKER_OUTPUT", rows} | path_env]
      )

    assert populated =~ "Project  Name  Status  Ports"

    assert_in_order(populated, [
      "(missing)  alpha  (missing)  (missing)",
      "alpha  bravo  Up 2 hours  (missing)",
      "zeta  charlie  Up 1 hour  #{long_ports}"
    ])

    makefile = File.read!(@makefile_path)
    fleet_recipe = target_body(makefile, "fleet")
    assert fleet_recipe =~ "label=traefik.enable=true"
    refute fleet_recipe =~ "com.docker.compose.project=relyra"
  end

  test "doctor reports every dependency, port, and network state without suppression" do
    fixture_bin = fixture_bin!()
    on_exit(fn -> File.rm_rf!(fixture_bin) end)

    write_executable!(fixture_bin, "docker", """
    #!/bin/sh
    case "$*" in
      "version") echo "Docker version 99" ;;
      "compose version") echo "Docker Compose version 99" ;;
      "network inspect"*) echo "proxy" ;;
      *) exit 0 ;;
    esac
    """)

    write_executable!(fixture_bin, "lsof", """
    #!/bin/sh
    case "$*" in
      *iTCP:4000*) echo "beam.smp 12345 developer 99u IPv6 very-long-owner-detail-for-port-4000"; exit 0 ;;
      *iTCP:5432*) echo "postgres 5432 developer 10u IPv4 database-listener"; exit 0 ;;
      *iTCP:8080*) exit 1 ;;
    esac
    """)

    {output, status} = run_make(["doctor"], [{"PATH", fixture_bin}])

    assert status != 0

    assert_in_order(output, [
      "==> Dependencies",
      "OK docker",
      "OK docker compose",
      "==> Host ports",
      "WARN port 4000 occupied",
      "very-long-owner-detail-for-port-4000",
      "INFO port 5432 occupied",
      "Relyra does not publish Postgres; this listener is diagnostic only.",
      "OK port 8080 free",
      "==> Shared proxy network",
      "OK proxy network exists — proxy.",
      "==> Next steps",
      "Review the exact Next: commands above."
    ])
  end

  test "doctor uses nc fallback and never calls an unavailable probe free" do
    fixture_bin = fixture_bin!()
    on_exit(fn -> File.rm_rf!(fixture_bin) end)

    write_executable!(fixture_bin, "docker", """
    #!/bin/sh
    case "$*" in
      "version"|"compose version") exit 0 ;;
      "network inspect"*) echo "network missing" >&2; exit 1 ;;
      *) exit 0 ;;
    esac
    """)

    write_executable!(fixture_bin, "nc", """
    #!/bin/sh
    case "$*" in
      *4000) exit 0 ;;
      *) exit 1 ;;
    esac
    """)

    {nc_output, nc_status} = run_make(["doctor"], [{"PATH", fixture_bin}])
    assert nc_status != 0
    assert nc_output =~ "WARN port 4000 occupied — detected by nc."
    assert nc_output =~ "OK port 5432 free — Relyra does not publish Postgres"
    assert nc_output =~ "OK port 8080 free"
    assert nc_output =~ "WARN proxy network missing. Next: make proxy"

    File.rm!(Path.join(fixture_bin, "nc"))
    {unavailable, unavailable_status} = run_make(["doctor"], [{"PATH", fixture_bin}])
    assert unavailable_status != 0

    Enum.each([4000, 5432, 8080], fn port ->
      assert unavailable =~ "WARN port #{port} probe unavailable"
      refute unavailable =~ "OK port #{port} free"
    end)

    assert unavailable =~ "Relyra does not publish Postgres; this listener is diagnostic only."
    assert unavailable =~ "Next: inspect host ports manually or install lsof/netcat"
  end

  test "open selects a supported opener and otherwise keeps a copy-pasteable URL" do
    fixture_bin = fixture_bin!()
    on_exit(fn -> File.rm_rf!(fixture_bin) end)
    opener_log = Path.join(fixture_bin, "opener.log")

    write_executable!(fixture_bin, "open", """
    #!/bin/sh
    printf 'open:%s\n' "$*" >> "$STUB_OPENER_LOG"
    """)

    env = [
      {"PATH", fixture_bin},
      {"RELYRA_HOST", "alt.relyra.localhost"},
      {"STUB_OPENER_LOG", opener_log}
    ]

    {_, 0} = run_make(["open"], env)
    assert File.read!(opener_log) == "open:http://alt.relyra.localhost\n"

    File.rm!(Path.join(fixture_bin, "open"))
    File.rm!(opener_log)

    write_executable!(fixture_bin, "xdg-open", """
    #!/bin/sh
    printf 'xdg-open:%s\n' "$*" >> "$STUB_OPENER_LOG"
    """)

    {_, 0} = run_make(["open"], env)
    assert File.read!(opener_log) == "xdg-open:http://alt.relyra.localhost\n"

    File.rm!(Path.join(fixture_bin, "xdg-open"))
    File.rm!(opener_log)
    {fallback, 0} = run_make(["open"], env)

    assert fallback =~ "http://alt.relyra.localhost"
    assert fallback =~ "Next: open the URL manually or install xdg-utils"
    refute File.exists?(opener_log)
  end

  test "proxy inspects or creates only the configured shared network before startup" do
    fixture_bin = fixture_bin!()
    on_exit(fn -> File.rm_rf!(fixture_bin) end)
    docker_log = Path.join(fixture_bin, "docker.log")

    write_executable!(fixture_bin, "docker", """
    #!/bin/sh
    printf '%s\n' "$*" >> "$STUB_DOCKER_LOG"
    if [ "$1 $2" = "network inspect" ] && [ "$STUB_NETWORK" = "missing" ]; then
      exit 1
    fi
    """)

    env = [
      {"PATH", fixture_bin},
      {"DEMO_PROXY_NETWORK", "shared-proxy"},
      {"STUB_DOCKER_LOG", docker_log}
    ]

    {_, 0} = run_make(["proxy"], [{"STUB_NETWORK", "missing"} | env])

    assert File.read!(docker_log) ==
             "network inspect shared-proxy\n" <>
               "network create shared-proxy\n" <>
               "compose -f docker/traefik/compose.yml up -d\n"

    File.rm!(docker_log)
    {_, 0} = run_make(["proxy"], [{"STUB_NETWORK", "exists"} | env])

    assert File.read!(docker_log) ==
             "network inspect shared-proxy\n" <>
               "compose -f docker/traefik/compose.yml up -d\n"
  end

  test "launcher treats environment values as data instead of shell fragments" do
    fixture_bin = fixture_bin!()
    on_exit(fn -> File.rm_rf!(fixture_bin) end)
    injection_log = Path.join(fixture_bin, "injection.log")

    write_executable!(fixture_bin, "touch", """
    #!/bin/sh
    echo "environment value executed" > "$STUB_INJECTION_LOG"
    """)

    hostile_host = "safe.localhost\"; touch \"$STUB_INJECTION_LOG\"; echo \""

    {output, 0} =
      run_make(
        ["url"],
        [
          {"PATH", fixture_bin},
          {"RELYRA_HOST", hostile_host},
          {"STUB_INJECTION_LOG", injection_log}
        ]
      )

    refute File.exists?(injection_log)
    assert output =~ hostile_host
  end

  test "incomplete phases require automated acceptance instead of human UAT" do
    roadmap = File.read!(".planning/ROADMAP.md")

    violations =
      roadmap
      |> incomplete_phase_numbers()
      |> Enum.flat_map(&automation_policy_violations/1)

    assert violations == [],
           "Incomplete phases must shift acceptance left into deterministic CI:\n" <>
             Enum.map_join(violations, "\n", &"  - #{&1}")
  end

  defp documented_targets(makefile) do
    ~r/^## ([a-z0-9-]+):/m
    |> Regex.scan(makefile, capture: :all_but_first)
    |> Enum.map(fn [target] -> target end)
    |> MapSet.new()
  end

  defp incomplete_phase_numbers(roadmap) do
    ~r/^- \[ \] \*\*Phase ([0-9.]+):/m
    |> Regex.scan(roadmap, capture: :all_but_first)
    |> Enum.map(fn [phase] -> phase end)
  end

  defp automation_policy_violations(phase) do
    phase_dirs = Path.wildcard(".planning/phases/#{phase}-*")

    document_violations =
      for phase_dir <- phase_dirs,
          path <- Path.wildcard(Path.join(phase_dir, "*.md")),
          marker <- ["<human-check>", "## Manual-Only Verifications", "status: human_needed"],
          String.contains?(File.read!(path), marker),
          do: "#{path} contains #{inspect(marker)}"

    uat_violations =
      for phase_dir <- phase_dirs,
          path <- Path.wildcard(Path.join(phase_dir, "*-UAT.md")),
          do: "#{path} requires a UAT artifact"

    document_violations ++ uat_violations
  end

  defp run_make(args, env \\ []) do
    System.cmd(make_executable!(), args, env: env, stderr_to_stdout: true)
  end

  defp run_make_with_input(args, input, env) do
    shell_env =
      [{"MAKE_BIN", make_executable!()}, {"MAKE_INPUT", input} | env]

    System.cmd(
      "/bin/sh",
      ["-c", "printf '%s\\n' \"$MAKE_INPUT\" | exec \"$MAKE_BIN\" \"$@\"", "relyra-make" | args],
      env: shell_env,
      stderr_to_stdout: true
    )
  end

  defp make_executable! do
    System.find_executable("make") || flunk("GNU Make is required for the launcher contract")
  end

  defp fixture_bin! do
    path =
      Path.join(
        System.tmp_dir!(),
        "relyra-launcher-fixture-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(path)
    path
  end

  defp write_executable!(directory, name, contents) do
    path = Path.join(directory, name)
    File.write!(path, contents)
    File.chmod!(path, 0o755)
    path
  end

  defp link_tool!(directory, name) do
    source = System.find_executable(name) || flunk("#{name} is required for launcher fixtures")
    File.ln_s!(source, Path.join(directory, name))
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
