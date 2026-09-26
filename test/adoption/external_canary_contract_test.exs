defmodule Relyra.Adoption.ExternalCanaryContractTest do
  use ExUnit.Case, async: true

  @moduletag :evidence_contract

  alias Relyra.AdoptionEvidence

  @workflow_path ".github/workflows/real-idp-canary.yml"
  @runner_path "scripts/test_real_idp_canary.sh"
  @browser_path "demo/ledger_loop/test/browser/real_idp_canary.spec.ts"
  @playwright_config_path "playwright.real-idp.config.mjs"
  @demo_workflow_path ".github/workflows/demo-app-e2e.yml"

  test "EVID-03 has a deterministic mandatory owner and supplemental scheduled signal" do
    entries = AdoptionEvidence.entries()
    [contract] = AdoptionEvidence.deterministic_owners(entries, "EVID-03")
    scheduled = Enum.find(entries, &(&1.id == "evid-03-scheduled-real-idp-canary"))

    assert contract.id == "evid-03-deterministic-canary-contract"
    assert contract.evidence_kind == :security_corpus
    assert contract.owner == "test/adoption/external_canary_contract_test.exs"
    assert contract.selector == "evidence_contract"
    assert contract.lane == "ci.evidence"
    assert contract.state == :existing

    assert scheduled.requirement == "EVID-03"
    assert scheduled.evidence_kind == :external_canary
    assert scheduled.state == :existing
    assert scheduled.owner == @workflow_path
    assert scheduled.lane == "scheduled:real-idp-canary"

    assert :ok = AdoptionEvidence.validate_closure!(entries, ["EVID-03"])

    assert_raise ArgumentError, ~r/EVID-03.*deterministic owner/, fn ->
      AdoptionEvidence.validate_closure!([scheduled], ["EVID-03"])
    end

    assert :ok = AdoptionEvidence.validate_repository!(entries, File.cwd!())
  end

  test "scheduled workflow is independent and uploads only the bounded status artifact" do
    workflow = File.read!(@workflow_path)

    [triggers, _permissions_and_jobs] =
      String.split(workflow, "\npermissions:\n", parts: 2)

    assert triggers =~ "on:\n  schedule:"
    assert triggers =~ "\n  workflow_dispatch:"
    refute workflow =~ ~r/^\s*(pull_request|push):/m
    refute workflow =~ ~r/^\s+needs:/m
    assert workflow =~ ~r/^permissions:\n  contents: read$/m
    assert workflow =~ "environment: real-idp-canary"
    assert workflow =~ "REAL_IDP_CANARY_USERNAME: ${{ secrets.REAL_IDP_CANARY_USERNAME }}"
    assert workflow =~ "REAL_IDP_CANARY_PASSWORD: ${{ secrets.REAL_IDP_CANARY_PASSWORD }}"
    assert workflow =~ "REAL_IDP_CANARY_OWNER: ${{ vars.REAL_IDP_CANARY_OWNER }}"

    assert workflow =~
             "REAL_IDP_CANARY_CREDENTIAL_OWNER: ${{ vars.REAL_IDP_CANARY_CREDENTIAL_OWNER }}"

    assert workflow =~ "REAL_IDP_CANARY_RESPONDER: ${{ vars.REAL_IDP_CANARY_RESPONDER }}"
    assert workflow =~ "REAL_IDP_CANARY_RUNBOOK: ${{ vars.REAL_IDP_CANARY_RUNBOOK }}"

    assert workflow =~ "if: always()"
    assert workflow =~ "path: ${{ runner.temp }}/relyra-real-idp-canary-status.json"
    assert workflow =~ "if-no-files-found: error"
    assert workflow =~ "retention-days: 7"
    refute workflow =~ ~r/^\s+path:.*(?:playwright-report\/|test-results\/|\.zip|\.webm|\.png)/mi

    demo_workflow = File.read!(@demo_workflow_path)
    assert demo_workflow =~ "path: ${{ runner.temp }}/relyra-trace-visual-status.json"

    refute demo_workflow =~
             ~r/^\s+path:.*(?:playwright-report\/|test-results\/|\.zip|\.webm|\.png)/mi
  end

  test "origin checks precede credential entry and browser recordings stay disabled" do
    browser = File.read!(@browser_path)
    config = File.read!(@playwright_config_path)
    runner = File.read!(@runner_path)

    assert index(browser, "currentIdpUrl.origin !== idpOrigin") <
             index(browser, ".locator(usernameSelector).fill(username)")

    assert browser =~ "currentIdpUrl.protocol !== \"https:\""
    assert browser =~ "url.origin === spOrigin"
    assert browser =~ "page.locator(\"#workspace-title\")"
    assert browser =~ ~r/status = "(passed|unexpected_origin|idp_rejected|callback_failure)"/

    assert config =~ ~s(trace: "off")
    assert config =~ ~s(screenshot: "off")
    assert config =~ ~s(video: "off")

    assert runner =~ "REAL_IDP_CANARY_SP_LOGIN_URL"
    assert runner =~ "login.origin !== sp.origin"
    assert runner =~ "process.env.REAL_IDP_CANARY_IDP_ORIGIN"
    assert runner =~ "https:"
    assert runner =~ "configuration_incomplete"
    assert runner =~ "relyra-real-idp-canary-status.json"
    refute runner =~ ~r/console\.log|page\.content\(|storageState\(/
  end

  test "contract probe exercises missing config and provider failure without invoking npx" do
    temp =
      Path.join(System.tmp_dir!(), "relyra-canary-contract-#{System.unique_integer([:positive])}")

    bin = Path.join(temp, "bin")
    runner_temp = Path.join(temp, "runner-temp")
    marker = Path.join(temp, "npx-was-called")
    npx_stub = Path.join(bin, "npx")
    File.mkdir_p!(bin)
    File.mkdir_p!(runner_temp)
    File.write!(npx_stub, "#!/bin/sh\nprintf called > '#{marker}'\nexit 86\n")
    File.chmod!(npx_stub, 0o755)
    on_exit(fn -> File.rm_rf!(temp) end)

    path = System.get_env("PATH") || "/usr/bin:/bin"
    probe_path = "#{bin}:#{path}"

    {syntax_output, syntax_exit} =
      System.cmd("bash", ["-n", @runner_path], cd: File.cwd!(), stderr_to_stdout: true)

    assert syntax_exit == 0, syntax_output

    {output, exit_code} =
      System.cmd(
        "env",
        [
          "-i",
          "PATH=#{probe_path}",
          "HOME=#{System.user_home!()}",
          "RUNNER_TEMP=#{runner_temp}",
          "CANARY_NPX_MARKER=#{marker}",
          "bash",
          @runner_path,
          "--contract-probe"
        ],
        cd: File.cwd!(),
        stderr_to_stdout: true
      )

    assert exit_code == 0, output
    assert output =~ "contract probe passed"
    refute File.exists?(marker)
    refute output =~ ~r/https?:\/\/|password|username|samlrequest|assertion/i
  end

  test "ci.evidence owns the external canary contract in its own fresh test process" do
    mix_file = File.read!("mix.exs")
    [evidence_alias] = Regex.scan(~r/"ci\.evidence": \[(.*?)\n      \]/s, mix_file)

    assert Enum.at(evidence_alias, 1) =~
             "cmd mix test test/adoption/evidence_contract_test.exs test/adoption/external_canary_contract_test.exs test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors"

    assert Enum.count(String.split(Enum.at(evidence_alias, 1), "\n"), fn line ->
             String.contains?(line, "cmd mix test")
           end) == 1
  end

  defp index(source, fragment) do
    case :binary.match(source, fragment) do
      {position, _length} -> position
      :nomatch -> flunk("expected source fragment #{inspect(fragment)}")
    end
  end
end
