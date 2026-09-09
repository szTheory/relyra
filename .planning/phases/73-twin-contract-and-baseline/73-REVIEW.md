---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-09T19:14:28Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/security-gates.yml
  - mix.exs
  - mix.lock
  - test/adoption/evidence_contract_test.exs
  - test/governance/milestone_scope_test.exs
  - test/support/adoption_evidence.ex
findings:
  critical: 8
  warning: 2
  info: 0
  total: 10
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-09T19:14:28Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The Phoenix lock now resolves to 1.8.13 and the focused `mix ci.evidence` lane passes 29 tests, but the new evidence and governance contracts contain several fail-open parsing paths. Most accept token-shaped prose rather than proving the structured condition they claim to enforce, so a plan, owner, workflow, or baseline can produce a green result without satisfying the corresponding requirement.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 [BLOCKER]: Closure accepts malformed rows without validating the ledger

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:288-307`
**Issue:** `validate_closure!/2` calls `deterministic_owners/2` directly and never calls `validate_entry!/1` or `validate_entries!/1`. A partial row such as `%{requirement: "EVID-01", state: :existing, evidence_kind: :bogus}` returns `:ok`; this was reproduced with `MIX_ENV=test mix run`. Unknown evidence classes, missing IDs, and missing ownership fields can therefore close a completed requirement through the public helper.
**Fix:** Validate every supplied row before evaluating closure, then require a known deterministic evidence kind. If full-ledger coverage is intentionally not required for subset closure, use `Enum.each(entries, &validate_entry!/1)` rather than `validate_entries!/1`, and add the malformed partial-row case to the contract tests.

### CR-02 [BLOCKER]: Selector ownership is satisfied by inert source text

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:328-341`
**Issue:** Owner validation searches raw source with a regex for `@tag` or `@moduletag`. The same text in a comment, string, or a module containing no tests passes. Combined with ExUnit's successful zero-test exit, a named selector can still be a hollow owner despite the diagnostic claiming it "matches zero tests" only when the token is absent.
**Fix:** Parse the owner AST and associate the tag with at least one `test` definition, or execute each owner/selector in an isolated subprocess and assert that ExUnit reports a non-zero selected-test count. Add commented-tag, string-tag, and tagged-empty-module controls.

### CR-03 [BLOCKER]: Workflow ownership does not prove that the evidence lane is mandatory

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:358-389`
**Issue:** `workflow_command?/2` accepts any line whose text is `run: mix ci.evidence`. It does not bind the command to the `security` job or the named `Evidence contract` step and does not reject `if: false`, `continue-on-error: true`, or a disabled job. The companion test's line scanner has the same enabled-state gap, so a permanently skipped or non-blocking step can satisfy EVID-02.
**Fix:** Parse the workflow structure and require the command under `jobs.security.steps` with the expected name, no false condition, and no `continue-on-error`; also assert the job itself is enabled on the required PR/push triggers. Add disabled-step and continue-on-error fixtures.

### CR-04 [BLOCKER]: Risky mutations are invisible unless the plan self-reports an exact marker

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:635-723`
**Issue:** A mutation is detected only when its action contains `approval_class: <class>`, while negative scope declarations are accepted via substring matches such as `none` or `unchanged`. A task can say "Change `Relyra.start_login/3`" without that marker and pass under `public_api: unchanged`; values such as `not unchanged; mutation required` also count as negative. This defeats the stated approval-before-mutation guarantee.
**Fix:** Replace free-form substring inference with exact structured task metadata whose risk field is mandatory on every task and parsed as a closed enum. Add post-execution diff checks for published API signatures and named security seams, and add fixtures for an unmarked public-API mutation and negated words such as `not unchanged`.

### CR-05 [BLOCKER]: Remote “exact batch” approval is only a keyword checklist

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:725-748`
**Issue:** A remote checkpoint passes when its body merely contains seven phrases and any non-empty resume signal. The current clean fixture itself contains no actual command, current value, desired value, preflight, rollback command, or read-back command—only the labels. Text such as `exact commands omitted` therefore authorizes the remote mutation.
**Fix:** Define structured fields for each remote-batch element, require non-placeholder values, parse command lists, and validate that rollback/read-back target the same affected checks. Add explicit placeholder-only and mismatched-target fixtures.

### CR-06 [BLOCKER]: Any text containing `mix ` is treated as deterministic acceptance

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:751-768`
**Issue:** Verification passes for commands such as `mix help`, `mix deps.get`, or `echo mix test`, and only one such token is required across all non-checkpoint tasks. It neither proves that every acceptance criterion has an executable owner nor that the command selects a non-zero test set. A plan can therefore replace real verification with a non-testing Mix command and stay green.
**Fix:** Parse allowed verification command forms, require a test/check alias with warnings-as-errors for every task carrying acceptance criteria, and validate selector ownership through the evidence ledger. Add `mix help`, zero-test selector, and one-verified/multiple-unverified-task fixtures.

### CR-07 [BLOCKER]: Forbidden capabilities can be smuggled through negation keywords

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:770-815`
**Issue:** `negative_capability_reference?/2` treats a sentence as safe if it contains any of `do not`, `must not`, `forbid`, or `reject`. Sentences such as `Do not delay; implement KMS-01` or `Do not reject implementation of SIGNED-META-01` are accepted. `governance_policy_action?/1` similarly exempts an entire action once it finds a policy-shaped phrase, even if the same action also directs implementation.
**Fix:** Move exclusions into a structured exact list outside implementation-bearing task regions and reject every occurrence in task name/files/action regardless of nearby natural-language negation. If policy-test tasks need identifiers, give them a dedicated structured fixture field rather than exempting the whole action.

### CR-08 [BLOCKER]: Baseline evidence validation does not require verification evidence

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:1137-1142`
**Issue:** Splitting on `[VERIFIED:` and checking only whether the prefix is empty means any non-empty prose with no verification marker passes. The positive test only checks that the aggregate evidence text contains one marker somewhere. Consequently, individual findings can lose their command/source provenance while the baseline remains valid.
**Fix:** Require every row to contain a non-empty description followed by a syntactically complete `[VERIFIED: ...]` reference, validate the reference's allowed command/source shape, and add a row-level missing-marker control.

## Warnings

### WR-01 [WARNING]: “Populated” evidence fields accept whitespace-only values

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:256-279`
**Issue:** Field validation rejects only `nil` and the exact empty string. Whitespace-only IDs, jobs, outcomes, fixture ownership, reset boundaries, and diagnostics are accepted; the test repeats the same `!= ""` weakness. This permits visually empty planned rows and weak diagnostics in the canonical ledger.
**Fix:** Require binaries and reject `String.trim(value) == ""` for every textual field; add whitespace-only cases for identity and diagnostic fields.

### WR-02 [WARNING]: The Phoenix remediation widened four additional lock entries

**File:** `/Users/jon/projects/relyra/mix.lock:2`
**Issue:** Alongside Phoenix 1.8.7 → 1.8.13, the lock diff upgrades Bandit 1.11.1 → 1.12.5, Phoenix PubSub 2.2.0 → 2.3.0, Thousand Island 1.4.3 → 1.5.0, and WebSock Adapter 0.5.9 → 0.6.0. All prior versions satisfy the new Phoenix dependency ranges visible in the lock entry, so this expands the compatibility surface beyond the targeted advisory remediation without an explicit plan item.
**Fix:** Re-resolve with only Phoenix unlocked while retaining compatible child locks, or document and separately verify the four transitive upgrades as an intentional dependency batch.

---

_Reviewed: 2026-09-09T19:14:28Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
