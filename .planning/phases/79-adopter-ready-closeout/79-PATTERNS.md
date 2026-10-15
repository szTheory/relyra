# Phase 79: Adopter-Ready Closeout - Pattern Map

**Mapped:** 2026-09-29  
**Files analyzed:** 4 likely deliverables/owners; filenames for new evidence artifacts remain plan-selected  
**Analogs found:** 4 / 4

The phase context and research do not prescribe exact filenames for closeout evidence. The first two entries below are likely phase artifacts; the governance test and optional collector are conditional on whether planning chooses to extend executable evidence. Do not treat these filenames as locked.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/79-adopter-ready-closeout/79-INVENTORY.md` (plan-selected name) | report / operational evidence | transform | `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` | role-match |
| `.planning/phases/79-adopter-ready-closeout/79-RESIDUAL-RISKS.md` (may be combined with inventory) | report / risk ledger | transform | `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` | role-match |
| `test/governance/milestone_scope_test.exs` (conditional modification) | test | transform / request-response | same file's baseline and remote-batch contracts | exact |
| `scripts/check_phase79_closeout.sh` (only if plan selects a reusable collector) | utility | request-response / file-I/O | `scripts/check_phase78_clean_state.sh` | role-match |

## Pattern Assignments

### `.planning/phases/79-adopter-ready-closeout/79-INVENTORY.md` (report, transform)

**Analog:** `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` (tracked; confirmed with `git ls-files`).

The baseline shows how to make a dated observation auditable: title and scope, explicit evidence date, structured findings, source/provenance in each row, and separate remote-mutation boundary. Preserve this layout style, but make Phase 79 observations fresh and identify collection timestamp, repository/branch, and main SHA. Keep PR/issue/branch/workflow/protection observations bounded and redaction-safe. Do not copy Phase 73's dated counts as current evidence.

**Finding ledger pattern** (lines 16-29):

```markdown
## Findings Ledger

| Finding ID | Severity | Category | Finding | Reproducible Evidence | Disposition | Owner | Target Phase | Approval Class | Blocker State | Revisit Date |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PIPE-73-001 | High | CI | required-check drift leaves the desired Fleet gate outside live main protection | Desired: `security (27, 1.19.5)`, `security (28, 1.19.5)`, and `fleet-proxy-e2e`. Current: only the two security checks; Branch Protection Apply is `disabled_inactivity`. [VERIFIED: `scripts/setup_branch_protection.sh` plus read-only GitHub API queries, 2026-09-09] | Route the exact remote repair batch to Phase 79; Phase 73 performs no GitHub mutation. | Phase 79 release owner | Phase 79 | remote_github blocking approval | release-blocker | Before v1.11 release |
```

**Provenance and safety pattern** (lines 47-53):

```markdown
## Remote Mutation Boundary

Phase 73 made no remote GitHub mutation. The exact Phase 79 repair batch is: obtain explicit `remote_github` approval; re-enable the `Branch Protection Apply` workflow if it remains disabled; run its owner-controlled `./scripts/setup_branch_protection.sh main` path with the repository administration secret; then read back strict protection and confirm exactly the two security matrix contexts plus `fleet-proxy-e2e`. Rollback is an owner-approved reapplication of the previously captured live protection document. No baseline test depends on network access.
```

Use a report section/table for observed timestamp and SHA, page-completeness/access gaps, required checks versus external canaries, and the local expected-protection output. A remote API permission error is an evidence gap, not a claim of absent protection.

### `.planning/phases/79-adopter-ready-closeout/79-RESIDUAL-RISKS.md` (report, transform)

**Analog:** `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` (tracked; same excerpt above).

The baseline ledger is the closest risk-report schema. Retain finding identity, severity, evidence, owner, approval class, disposition, and revisit point. Revalidate every retained Phase 73 item and incorporate STATE deferred items and WINDOWS open gaps (including Phase 76 concurrency gaps). Add the phase's needed adopter-value, demand, and maintenance-cost assessment. An unresolved automation window is not automatically a release blocker; status and rationale must be explicit.

**Disposition rules to preserve** (lines 7-14):

```markdown
## Severity and Disposition Policy

The only allowed severities are Critical, High, Medium, Low, and Informational.

- High and Critical findings are release blockers until remediated and regression-tested. A resolved historical finding remains visible with its proof.
- Medium findings require an explicit written disposition before release.
- Low and Informational findings may be deferred only while they retain an owner and revisit date.
- `release-blocker`, `disposition-required`, `deferred`, and `resolved` are the only blocker states in this baseline.
```

### `test/governance/milestone_scope_test.exs` (test, transform / request-response)

**Analog:** the same tracked file, `test/governance/milestone_scope_test.exs`.

This is the established deterministic owner for adoption/governance contracts and is already included in `mix ci.evidence`. Extend its existing test helpers and assertions only if Phase 79 adds a machine-validated evidence schema; keep live GitHub calls out of ExUnit and use small redacted fixtures. The existing suite tests malformed input and missing fields with precise diagnostics rather than relying on a human review.

**Exact-batch authorization excerpt** (lines 1418-1438):

```elixir
test "remote GitHub approval owns an exact reversible batch and read-back" do
  %{plan: clean, root: root} = remote_plan_fixture()
  assert plan_scope_violations(clean, [], root) == []

  for {field, diagnostic} <- [
        {"current_state", "current_state"},
        {"desired_state", "desired_state"},
        {"mutation_commands", "mutation_commands"},
        {"affected_checks", "affected_checks"},
        {"preflight_command", "preflight_command"},
        {"rollback_commands", "rollback_commands"},
        {"read_back_command", "read_back_command"},
        {"resume_signal", "resume signal"}
      ] do
    incomplete = remove_remote_field(clean, field)
    assert_plan_violation(incomplete, "remote_github", diagnostic, root)
  end

  without_resume = Regex.replace(~r/\s*<resume-signal>.*?<\/resume-signal>/s, clean, "")
  assert_plan_violation(without_resume, "remote_github", "resume signal", root)
end
```

**Baseline validation excerpt** (lines 2389-2407):

```elixir
test "baseline parser is anchored, non-vacuous, and rejects duplicate exact headings" do
  baseline = File.read!(@baseline_path)

  incidental =
    String.replace(
      baseline,
      "## Findings Ledger",
      "The phrase Findings Ledger is incidental here.\n\n### Findings Ledger\n\n## Findings Ledger",
      global: false
    )

  assert baseline_rows(incidental) == baseline_rows(baseline)

  duplicated = baseline <> "\n## Findings Ledger\n\n| decoy |\n| --- |\n| row |\n"
  assert_violation(duplicated, "document", "Findings Ledger duplicate heading")
end
```

New assertions should bind records to a collection timestamp and current main SHA, reject incomplete pagination or unknown API states, require risk owner/evidence/disposition/revisit fields, and ensure read-only collection contracts cannot cross into mutation. Follow the existing ExUnit style and wire any new deterministic owner into the existing `mix ci.evidence` lane. Do not query shared GitHub state in tests.

### `scripts/check_phase79_closeout.sh` (utility, request-response / file-I/O; conditional)

**Analog:** `scripts/check_phase78_clean_state.sh` (tracked; confirmed with `git ls-files`).

Only create a collector if planning determines executable local evidence is needed. The Phase 78 script is the source-bound evidence pattern: strict shell settings, explicit modes, bounded input, schema checks, UTC timestamp, refusing accidental overwrite, and atomic output. Phase 79's remote collection should remain read-only and avoid token/environment dumps. Reuse GitHub CLI for API requests; do not implement a new client or invoke the branch-protection apply path.

**Argument/mode and provenance pattern** (lines 1-13, 16-53):

```bash
#!/usr/bin/env bash
set -uo pipefail

readonly RECEIPT_REL='.planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json'
readonly MAX_OUTPUT_BYTES=16777216

usage() {
  cat <<'USAGE'
Usage:
  scripts/check_phase78_clean_state.sh --otp 27|28 --output <private-temp-file>
  scripts/check_phase78_clean_state.sh --assemble <otp27.json> <otp28.json> --output <receipt.json>
  scripts/check_phase78_clean_state.sh --source-digest <git-checkout>
USAGE
}

source_digest() {
  python3 - "$1" "$RECEIPT_REL" <<'PY'
import hashlib
import os
import subprocess
import sys

root = os.path.realpath(sys.argv[1])
receipt = sys.argv[2]
tracked = subprocess.check_output(["git", "-C", root, "ls-files", "-z"]).split(b"\0")
manifest = []
for raw in tracked:
    if not raw:
        continue
    path = raw.decode("utf-8")
    full = os.path.join(root, path)
    if not os.path.isfile(full):
        raise SystemExit("source manifest contains a missing or non-regular file")
```

For a collector, make read operations explicit, record observation status and target SHA, paginate all list endpoints, and write only allowlisted metadata. `setup_branch_protection.sh --print-expected-json` is the existing read-only expected-state source; its default path is a PUT and must not be used as an inventory operation.

## Shared Patterns

### Fresh evidence and provenance

**Source:** `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md`, lines 3-5 and 47-53; `.planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json` (source-bound precedent).  
**Apply to:** inventory, main readiness, local cleanliness, and residual-risk artifacts.

Timestamp each observation; identify the target SHA and source; distinguish current observations from historical receipts. Report access or pagination failures as evidence gaps. Redact tokens, environment dumps, and unrelated API fields.

### Read-only expected state / separate mutation gate

**Source:** `scripts/setup_branch_protection.sh`, lines 18-23 and 46-78 (tracked; confirmed with `git ls-files`).

```bash
REQUIRED_CHECKS=(
  "security (27, 1.19.5)"
  "security (28, 1.19.5)"
  "fleet-proxy-e2e"
)

case "${1:-}" in
  --print-expected)
    print_expected_text
    exit 0
    ;;
  --print-expected-json)
    expected_json
    exit 0
    ;;
esac

BRANCH="${1:-main}"
```

Use only `--print-expected` or `--print-expected-json` for inventory. Any real remote operation must remain its own exact, plan-local batch with current/desired state, preflight, rollback, read-back, and explicit approval; acceptance comes from read-back, not approval.

### Ownership-aware local cleanliness

**Source:** `test/governance/milestone_scope_test.exs`, lines 2195-2263, plus Git inventory commands described in `79-RESEARCH.md`.

Classify tracked modifications, untracked files, ignored/generated artifacts, branches, and registered worktrees by ownership before cleanup. Preserve user-owned `.tool-versions`. A source-bound receipt proves only its own source identity; it does not establish current main readiness.

## No Analog Found

No close analog is needed for a fixture-only GitHub observation schema beyond the existing governance test owner. No new product/SAML code is implied by this feature-neutral phase.

## Metadata

**Analog search scope:** `.planning/phases/73-*`, `.planning/phases/78-*`, `scripts/`, `test/governance/`, `mix.exs`, `.github/workflows/security-gates.yml`  
**Files scanned:** 5 implementation/evidence analogs; all named analog paths passed the tracked-source check with `git ls-files`.  
**Pattern extraction date:** 2026-09-29
