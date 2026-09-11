---
phase: "73"
slug: "twin-contract-and-baseline"
status: issues_found
threats_open: 1
asvs_level: 1
block_on: high
created: "2026-09-09"
---

# Phase 73 — Security

> Verification of the plan-authored threat register plus dependency-audit findings observed during closeout.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Planning requirements → evidence registry | Human-authored completion state becomes executable evidence metadata. | Requirement ownership and completion state |
| Evidence registry → Mix alias → required workflow | Repository metadata becomes a merge-gating result. | Test selectors, commands, and workflow triggers |
| Repository observations → committed baseline | Ephemeral measurements become durable maintainer input. | Quality findings, CI provenance, and safe failure summaries |
| PLAN intent → autonomous executor | Scope declarations authorize or reject risky mutations. | Approval classes, ordered tasks, and requirement ownership |
| Locked dependencies → security gate | Published package advisories determine whether closeout may advance. | Package versions and advisory identifiers |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-73-01 | Tampering | owner/selector/alias/workflow chain | high | mitigate | AST alias parsing, complete owner-chain checks, negative fixtures, and required workflow step (`test/support/adoption_evidence.ex:310`, `test/adoption/evidence_contract_test.exs:139`, `.github/workflows/security-gates.yml:80`). | closed |
| T-73-02 | Spoofing | external-canary and planned rows | high | mitigate | Closed vocabularies and deterministic-owner filtering with planned/canary rejection tests (`test/support/adoption_evidence.ex:15`, `test/adoption/evidence_contract_test.exs:53`). | closed |
| T-73-03 | Information Disclosure | evidence diagnostic metadata | medium | mitigate | Exact metadata schema and populated ownership/reset/diagnostic checks; inspected ledger data contains no authentication payloads or secrets (`test/support/adoption_evidence.ex:17`, `test/adoption/evidence_contract_test.exs:39`). | closed |
| T-73-04 | Denial of Service | workflow path filters | medium | mitigate | Planning-path bypass rejection and workflow triggers that ignore only `prompts/**` (`test/support/adoption_evidence.ex:310`, `.github/workflows/security-gates.yml:3`). | closed |
| T-73-05 | Tampering | findings ledger | high | mitigate | Stable IDs, required lifecycle fields, duplicate/enum/evidence/severity checks (`73-BASELINE.md:18`, `test/governance/milestone_scope_test.exs:255`). | closed |
| T-73-06 | Repudiation | CI timing and required-check claims | medium | mitigate | Dated snapshot, per-row provenance, and explicit sample-not-trend assertions (`73-BASELINE.md:5`, `test/governance/milestone_scope_test.exs:310`). | closed |
| T-73-07 | Information Disclosure | live CI and failure evidence | high | mitigate | Redaction-safe storage policy and sensitive-payload rejection (`73-BASELINE.md:53`, `test/governance/milestone_scope_test.exs:474`). | closed |
| T-73-08 | Denial of Service | baseline parser | low | accept | Small tracked maintainer Markdown, exact-section parsing, and repeated-heading controls (`test/governance/milestone_scope_test.exs:383`). | closed — accepted |
| T-73-09 | Elevation of Privilege | checkpoint ordering | high | mitigate | Missing, late, non-blocking, wrong-class, cross-plan, and ordered-enforcement controls (`test/governance/milestone_scope_test.exs:59`, `test/governance/milestone_scope_test.exs:678`). | closed |
| T-73-10 | Repudiation | remote mutation authorization | high | mitigate | Exact reversible batch fields and missing-detail fixtures (`test/governance/milestone_scope_test.exs:84`, `test/governance/milestone_scope_test.exs:725`). | closed |
| T-73-11 | Tampering | deferred capability scope | high | mitigate | Roadmap ownership and disguised-capability fixtures plus implementation-region validation (`test/governance/milestone_scope_test.exs:143`, `test/governance/milestone_scope_test.exs:770`). | closed |
| T-73-12 | Denial of Service | governance parser false positives | medium | mitigate | Anchored parsing and legal-negative controls exist, but explicit repeated-plan-token and archived-plan passing fixtures were not found. | open — below high threshold (non-blocking) |
| T-73-36 | Elevation of Privilege | verification command grammar | high | mitigate | Anchored non-shell grammar produces one executable argv and rejects comments, redirects, expansion, quoting, globbing, escaping, and command composition; Plan 73-09 task-1 evidence passes. | closed |
| T-73-37 | Spoofing | Mix alias and ExUnit owner | high | mitigate | Actual alias resolution applies ordered include/exclude filters and requires a positive effective ExUnit selection for every owner; Plan 73-12 empty-selection and sibling-owner controls pass (`test/support/adoption_evidence.ex:397`, `test/adoption/evidence_contract_test.exs:563`). | closed |
| T-73-38 | Tampering | workflow job/step fallibility | high | mitigate | Evidence ownership requires unconditional, non-fallible job and step configuration with closed fallibility values; Plan 73-09 task-2 evidence passes. | closed |
| T-73-39 | Denial of Service | GitHub path filters | high | mitigate | Positive `paths` filters are rejected for both mandatory events, and ignored paths are checked against fixed plus Git-discovered governed inputs; Plan 73-12 restrictive-filter controls pass (`test/support/adoption_evidence.ex:860`, `test/adoption/evidence_contract_test.exs:789`). | closed |
| T-73-40 | Information Disclosure | isolated owner probe | low | accept | The probe receives only repository paths and selector metadata, executes no test body or network operation, and now isolates foreign Mix evaluation in a child process. | closed — accepted |
| T-73-41 | Tampering | active phase discovery | high | mitigate | PROJECT, ROADMAP, REQUIREMENTS, and STATE must establish one consistent, non-empty active milestone and executable plan frontier; Plan 73-10 task-1 evidence passes. | closed |
| T-73-42 | Elevation of Privilege | schema dispatcher | high | mitigate | Schema selection is bound to validated milestone/phase/path identity with only the three immutable legacy-plan exceptions; weakened current-plan fixtures fail closed. | closed |
| T-73-43 | Repudiation | completed execution provenance | high | mitigate | Ordered exact-scope commits are always derived from Git before an optional manifest is treated as an exact equality audit; Plan 73-13 omission, addition, reorder, duplicate, ambiguity, reachability, and boundary controls pass (`test/governance/milestone_scope_test.exs:230`, `test/governance/milestone_scope_test.exs:3552`). | closed |
| T-73-44 | Spoofing | SUMMARY Task Commits | high | mitigate | SUMMARY hashes are equality-checked against the Git-derived trusted commit set but never select the authoritative set; omission/addition/duplicate fixtures pass. | closed |
| T-73-45 | Denial of Service | repository parsers | low | accept | Inputs remain bounded tracked planning files and isolated Git fixtures with deterministic fail-closed diagnostics and no network access. | closed — accepted |
| T-73-46 | Tampering | remote-batch field parser | high | mitigate | Occurrence-preserving parsing requires one closed, non-empty scalar/list representation per field before reduction; duplicate and unparsed-field adversaries pass. | closed |
| T-73-47 | Spoofing | payload/script provenance | high | mitigate | Script-backed authorization validates indexed executable identity and a separately tracked normalized static result without launching plan-selected code; Plan 73-13 ambient-authority controls pass (`test/governance/milestone_scope_test.exs:522`, `test/governance/milestone_scope_test.exs:3089`). | closed |
| T-73-48 | Elevation of Privilege | desired/rollback state binding | high | mitigate | Branch-protection normalization retains the complete ten-field state and enforces exact safe invariants for every accepted non-declared control in both mutation and rollback comparisons; Plan 73-13 field mutation controls pass (`test/governance/milestone_scope_test.exs:478`, `test/governance/milestone_scope_test.exs:2971`). | closed |
| T-73-49 | Repudiation | reviewed script revision | high | mitigate | Script working content must match its indexed object ID, preventing post-review mutation; changed-after-index adversaries pass. | closed |
| T-73-50 | Information Disclosure | script validation | medium | mitigate | Superseded by removal of the script-backed authorization surface: mutation and rollback accept only tracked declarative `gh api --input` payload operations whose complete normalized states match the approved batch. `plan_73_15_task_1` and the mandatory `mix ci.evidence` lane pass. | closed — script surface removed |
| T-73-51 | Denial of Service | mandatory workflow event filters | high | mitigate | Closed by the occurrence-preserving event grammar: push accepts only one positive `main` branch in exact order, pull requests cannot declare restrictive activity filters, and duplicate events/direct keys plus unsupported event controls fail before path and owner reduction. `plan_73_14_task_1`, `plan_73_14_task_2`, and the mandatory `mix ci.evidence` lane pass. | closed — CR-06 |
| T-73-52 | Elevation of Privilege | script/result authorization binding | high | mitigate | Closed by removing script and static-result authorization: mutation and rollback cross the parser only as tracked declarative `gh api --input` operations whose complete normalized payload state matches the declared desired or current state. `plan_73_15_task_1` and the mandatory `mix ci.evidence` lane pass. | closed — CR-07 |
| T-73-53 | Repudiation | post-SUMMARY completed-plan provenance | high | mitigate | Closed by resolving one full exact-`HEAD` review endpoint, requiring the SUMMARY-add boundary to be its ancestor, and classifying every ordered exact-scope descendant while restricting SUMMARY and manifest equality audits to pre-boundary tasks. `plan_73_15_task_2` and the mandatory `mix ci.evidence` lane pass. | closed — CR-08 |
| T-73-67 | Denial of Service | registered-test process fan-out | critical | mitigate | Reopened by the later `73-REVIEW.md` review at 2026-09-11T05:04:38Z: `registered_test_tags!/2` locks on a caller-specific identity, so concurrent cache misses can launch duplicate probes. Require a caller-independent single-flight lock, a repeated cache check inside that lock, and a barrier-controlled simultaneous-miss regression proving discovery runs exactly once. | open — blocking |
| T-73-70 | Tampering | GitHub path-filter semantic mismatch | critical | mitigate | Closed by the unsupported-metacharacter corpus, including `.planning/STATE.md?`, and grammar-first rejection before governed-input comparison. `plan_73_18_task_1` passed 3 tests, all three unchanged sub-60-second `mix ci.evidence` runs passed 99 tests, and `mix ci.security` passed. | closed — fail-closed path grammar evidence |
| T-73-71 | Spoofing | symlink/untracked lexical owner provenance | medium | mitigate | Closed by component-wise non-symlink `File.lstat/1`, regular-leaf validation, and exact lexical `git ls-files --error-unmatch` tracking controls before discovery. `plan_73_18_task_2` passed 2 tests, all three unchanged sub-60-second `mix ci.evidence` runs passed 99 tests, and `mix ci.security` passed. | closed — exact owner provenance evidence |
| DEP-73-01 | Tampering | Phoenix request handling dependency | high | mitigate | Upgraded Phoenix from 1.8.7 to 1.8.13 with its coupled transport dependencies in `ae1f0aa`; `mix ci.security` and `mix deps.audit` pass. | closed |
| DEP-73-02 | Tampering | Phoenix request handling dependency | medium | mitigate | The Phoenix 1.8.13 upgrade resolves `GHSA-63mc-hw7g-86rr`; the post-upgrade dependency audit passes. | closed |

Zero threats remain open at or above the configured `high` blocking threshold, so `threats_open: 0`. `T-73-12` remains visible as an owned, open medium follow-up below that threshold; the blocking count does not erase or reclassify it.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-73-01 | T-73-08 | The parser consumes small, tracked maintainer Markdown and already bounds section matching and repeated headings. Revisit with parser-boundary and repeated-heading evidence during Phase 77 cleanup. | Project owner | 2026-09-09 |
| AR-73-02 | T-73-40 | The isolated owner probe receives repository paths and selector metadata only, executes no test body or network request, and evaluates foreign Mix projects in a child process. | Plan-authored disposition | 2026-09-10 |
| AR-73-03 | T-73-45 | Governance parsing is limited to bounded tracked planning files and isolated Git fixtures with deterministic failure behavior and no network access. | Plan-authored disposition | 2026-09-10 |

---

## External Dependency Findings

| Advisory | Locked Version | Severity | Status | Follow-up |
|----------|----------------|----------|--------|-----------|
| `GHSA-6983-jfq8-485w` | Phoenix 1.8.13 | high | closed | Resolved by `ae1f0aa`; full `mix ci.security` passed on 2026-09-09. |
| `GHSA-63mc-hw7g-86rr` | Phoenix 1.8.13 | medium | closed | Resolved by the same reviewed upgrade; `mix deps.audit` reports no unignored vulnerabilities. |

These dependency findings are not reclassified as accepted risks and are not conflated with the plan-authored `T-73-01`–`T-73-12` register.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-09 | 14 | 11 | 3 | GSD security auditor |
| 2026-09-09 | 14 | 13 | 1 non-blocking | OpenAI Codex after dependency remediation |
| 2026-09-09 | 14 | 13 | 1 non-blocking | ASVS L1 gap-closure recheck (registry short-circuit) |
| 2026-09-09 | 14 | 13 | 1 non-blocking | ASVS L1 post-execution recheck; no new summary threat flags |
| 2026-09-10 | 29 | 28 | 1 non-blocking | ASVS L1 final gap-closure recheck; Plans 73-09–11 register and 70-test evidence lane |
| 2026-09-10 | 29 | 22 | 7 | Post-review correction; five high-severity threats reopened from confirmed CR-01–CR-05 bypasses |
| 2026-09-10 | 29 | 27 | 2 non-blocking | ASVS L1 gap-closure verification; CR-01–CR-05 closed by Plans 73-12–13 and the 82-test evidence lane |
| 2026-09-10 | 32 | 27 | 5 | Post-gap review correction; CR-06–CR-08 opened as three blocking high-severity threats alongside two medium follow-ups |
| 2026-09-10 | 32 | 31 | 1 non-blocking | ASVS L1 final reconciliation; CR-06–CR-08 closed only after the Plan 73-14/15 focused selectors and 91-test `mix ci.evidence` lane passed |
| 2026-09-11 | 35 | 31 | 4 (2 blocking, 2 non-blocking) | Post-review correction for T-73-67/T-73-70/T-73-71; closing evidence pending |
| 2026-09-11 | 35 | 34 | 1 non-blocking | Final reconciliation for T-73-67/T-73-70/T-73-71; four focused selectors, three sub-60-second mix ci.evidence runs, and mix ci.security passed |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified at the configured ASVS L1 threshold after T-73-67, T-73-70, and T-73-71 were closed by their four focused selectors, three sub-60-second mix ci.evidence runs, and mix ci.security. `threats_open: 0` means no open threat at or above the configured high blocking threshold; T-73-12 remains visible and owned as an open medium follow-up below that threshold.
