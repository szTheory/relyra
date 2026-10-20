case Relyra.TestGsdTools.resolve() do
  {:ok, _path} ->
    :ok

  {:error, {:gsd_tools_unavailable, message}} ->
    IO.puts(
      "Relyra.TestGsdTools: #{message}; tests tagged :requires_gsd_tools are reported as skipped"
    )
end

# Phase 83 mutation lane: mutare runs the baseline suite inside a git-less
# sandbox COPY of the project. A handful of governance/adoption META-tests assert
# against the live git checkout and repo layout (milestone SHAs, workflow
# hygiene, evidence receipts) and so fail there through no fault of the code
# under mutation. When `RELYRA_MUTATION_SUITE` is set, those `:non_hermetic_sandbox`
# suites are excluded so the baseline is green; they still run in every ordinary
# lane (mix qa, mix ci.security, ci-gate). This scopes mutation to the security
# core only — never a relaxation of any gate.
mutation_suite_excludes =
  if System.get_env("RELYRA_MUTATION_SUITE") in ["1", "true"] do
    [:non_hermetic_sandbox]
  else
    []
  end

# The Phase 73 replay re-runs whole lanes; `mix ci.phase73.reconciliation` owns it.
ExUnit.start(
  exclude:
    [
      :pending,
      :integration,
      :external_idp,
      :phase78_clean_state_receipt,
      :phase_73_reconciliation_replay
    ] ++ mutation_suite_excludes
)

Relyra.TestSupport.MigrationCase.bootstrap!()

# Async tests sign redirect queries with FakeIdP.keypair/0; concurrent first access
# used to race on :persistent_term.put/2 and yield :invalid_signature flakes.
_ = Relyra.TestSupport.FakeIdP.keypair()
