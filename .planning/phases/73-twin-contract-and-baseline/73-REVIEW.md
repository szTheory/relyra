---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-09T21:43:18Z
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
  critical: 9
  warning: 1
  info: 0
  total: 10
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-09T21:43:18Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The Phase 73 gap-closure work fixes the initially reported literal bypasses, and the current `mix ci.evidence` lane passes 41 tests. The replacement parsers still fail open at several adjacent boundaries, however. Direct probes confirmed that shell command substitution, zero-test filters, non-executable selector owners, conditional workflow steps, checkpoint-shaped task types, negated approvals, contradictory scope values, unapproved remote commands, and nonexistent provenance paths are all accepted. These are requirement-contract failures in EVID-02, GOV-01, GOV-02, and QUAL-01 rather than style concerns.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 [BLOCKER]: Automated-command validation accepts shell execution and zero-test commands

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:340-365`
**Issue:** Environment assignments are stripped before shell metacharacters are checked, so `EVIL=$(id) mix ci.evidence` returns `:ok`. Direct test parsing also recognizes only the separated `--only value` form and ignores exclusion filters: both `mix test test/governance/milestone_scope_test.exs --only=no_such_selector --warnings-as-errors` and `mix test test/governance/milestone_scope_test.exs --exclude evidence_contract --warnings-as-errors` return `:ok`, even though they select zero evidence-contract tests. An acceptance-bearing task can therefore close with a command that executes unreviewed shell content or no proof at all.
**Fix:** Reject shell metacharacters before removing environment assignments, or parse assignments with a closed value grammar that excludes `$`, backticks, substitutions, and quoting. Parse Mix options in both `--option value` and `--option=value` forms, account for `--exclude`, and determine the effective selected test set rather than counting tests in named files independently of filters.

### CR-02 [BLOCKER]: Selector ownership crosses module boundaries and mistakes tag values for selectors

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:406-447`
**Issue:** `selected_test_count!/2` scans one file-wide AST accumulator. Once it sees any matching `@moduletag`, it counts every `test` node anywhere in the file, including tests in other untagged modules; `selector_in_tag?/2` also treats any atom in the tag arguments as the selector, so `@moduletag other: :evidence_contract` is considered an `evidence_contract` tag. A probe containing an empty value-tagged module plus an untagged, non-ExUnit module with a `test` call returned a selected count of 1 even though it is not an executable selected test.
**Fix:** Track module boundaries and ExUnit modules while walking the AST, interpret tag keys and key/value selectors using ExUnit semantics, and associate test-level tags only with their actual next test. Prefer executing the isolated owner with the exact filter and asserting a parsed non-zero run count if faithful static interpretation cannot be guaranteed.

### CR-03 [BLOCKER]: Conditional evidence steps are certified as mandatory

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:565-583`
**Issue:** The workflow validator rejects only a tiny set of literal false values and accepts every other `if:` expression as enabled. Replacing the Evidence contract step condition with `${{ github.event_name == "workflow_dispatch" }}` still made `mandatory_security_step?/3` return `true`, although the step would be skipped for pull requests and main pushes. Expression forms of truthy `continue-on-error` are similarly outside the closed checks. EVID-02 can regress to optional evidence while its contract remains green.
**Fix:** Require the security job and Evidence contract step to have no `if:` condition (or prove a deliberately supported condition is true on every required event), and reject any non-literal `continue-on-error` value rather than assuming unknown expressions are false. Validate required event/path behavior per trigger, not only the presence of `pull_request` and a `main` token.

### CR-04 [BLOCKER]: Any checkpoint-prefixed task bypasses risk, scope, and acceptance enforcement

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:1005-1008`
**Issue:** Multiple validators exempt tasks with `String.starts_with?(task.type, "checkpoint")`, but the parser never enforces a closed task-type vocabulary. A probe changed the normal task to `type="checkpoint-bypass"` and directed it to implement `KMS-01` and change `Relyra.start_login/3`; `plan_scope_violations/1` returned `[]`. The task skipped risk metadata, deterministic verification, and forbidden-capability checks, while orphan-checkpoint validation also ignored it because that path recognizes only the exact `checkpoint:decision` type.
**Fix:** Validate task types against an explicit allowed set. Exempt only exact authorization types such as `checkpoint:decision`, and make unknown checkpoint-like types a violation before any other analysis. Use the same exact predicate in risk, mutation, verification, forbidden-capability, and orphan-checkpoint logic.

### CR-05 [BLOCKER]: Negated text is accepted as a matching approval decision

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:1101-1105`
**Issue:** `matching_checkpoint_index/2` searches the entire task body with `String.contains?/2`. Changing `<decision>approval_class: public_api</decision>` to `<decision>not approval_class: public_api</decision>` still produced no violations. Incidental or explicitly negated prose can therefore masquerade as the named decision that is supposed to authorize a governed mutation.
**Fix:** Parse exactly one `<decision>` element into closed structured fields, require an exact positive `approval_class` value plus an explicit approval action/decision identifier, and reject duplicate, surrounding, or negated free-form values. Add negative and incidental-text fixtures.

### CR-06 [BLOCKER]: Scope assertions remain substring-based and accept contradictory mutation intent

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:1050-1064`
**Issue:** Although per-task risk metadata now uses a closed enum, plan-level scope still treats a value as negative whenever it merely contains `unchanged`, `none`, `no change`, or `no mutation`. A probe using `public_api: unchanged; mutation required` returned no violations. This leaves the original contradictory-scope bypass open and allows ambiguous assertions to suppress the required mutation/checkpoint path.
**Fix:** Give each approval class a closed set of exact normalized scope values, reject multi-token or contradictory values, and require a mutation assertion to correspond to a mutation task and matching checkpoint. Do not use substring membership for authorization state.

### CR-07 [BLOCKER]: Governed-source inference is disconnected from active-plan enforcement

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:1189-1210`
**Issue:** `changed_surface_classes/3` is called only by its self-test; `plan_scope_violations/1` never receives or inspects actual before/after content or the git diff. Active-plan validation trusts task-declared files/actions, and it skips a plan entirely as soon as a same-name SUMMARY exists (`executed_plan?/1`). A plan can omit or misstate a changed published API/security seam—or add a premature summary—and no independent surface check triggers approval, contrary to the Phase 73 decision and summary claiming before/after governed-surface inference.
**Fix:** Feed the actual scoped diff into governance validation, map changed published signatures/protected seams to required approval classes, and reconcile those classes with each plan's exact risk metadata and prior checkpoint. Do not treat SUMMARY existence alone as proof that pre-mutation approval was enforced; validate completed plan artifacts or a durable approval record too.

### CR-08 [BLOCKER]: Remote batches permit additional unapproved commands

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:1317-1392`
**Issue:** Remote mutation, rollback, preflight, and read-back commands are approved when they merely contain the expected repository/branch substring. Appending `&& gh api -X DELETE repos/szTheory/relyra` to the otherwise valid mutation command still produced no violations. The purported exact reversible batch can therefore contain arbitrary additional remote mutations or shell operations beyond what the checkpoint describes.
**Fix:** Parse each command with a closed command/argument grammar, reject shell control operators and multiple commands, and compare the complete operation, method, endpoint, input, repository, branch, and affected checks against the approved batch. Validate rollback and read-back as exact structured operations rather than substring-bearing text.

### CR-09 [BLOCKER]: Baseline provenance accepts nonexistent or unrelated repository paths

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:1836-1858`
**Issue:** A verification reference is accepted whenever one backticked token starts with an allowed directory prefix. Replacing the first finding's source with `.planning/no-such-evidence.md` left `baseline_violations/1` equal to `[]`. The validator neither proves the path exists nor that a command is an executable non-zero owner, so fabricated provenance satisfies QUAL-01's fail-closed evidence contract.
**Fix:** Resolve repository references under the repository root, require them to exist as regular tracked files, and validate command references through the same closed automated-command/owner semantics used for acceptance evidence. Reject references that contain only an allowed-looking prefix without a real source or runnable check.

## Warnings

### WR-01 [WARNING]: The advisory remediation widened four additional dependency locks

**File:** `/Users/jon/projects/relyra/mix.lock:2`
**Issue:** The Phoenix 1.8.7 to 1.8.13 security upgrade also moves Bandit 1.11.1 to 1.12.5, Phoenix PubSub 2.2.0 to 2.3.0, Thousand Island 1.4.3 to 1.5.0, and WebSock Adapter 0.5.9 to 0.6.0. The security context documents the Phoenix remediation, but this broader batch increases compatibility and regression surface beyond the named dependency without per-package intent or focused evidence.
**Fix:** Either re-resolve with only Phoenix unlocked while retaining compatible child versions, or explicitly document the coupled upgrade batch and add focused transport/pubsub compatibility evidence for the four additional version changes.

---

_Reviewed: 2026-09-09T21:43:18Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
