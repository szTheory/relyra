---
phase: "73"
slug: "twin-contract-and-baseline"
status: verified
threats_open: 0
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
| T-73-67 | Denial of Service | registered-test process fan-out | critical | mitigate | Closed by a caller-independent, content-addressed single-flight `ResourceId`, an inside-lock cache recheck, and the barrier-controlled simultaneous-miss regression. `plan_73_22_task_1` passed 1 test; the three unchanged `mix ci.evidence` runs and complete `mix ci.security` lane passed. | closed — caller-independent single-flight evidence |
| T-73-70 | Tampering | GitHub path-filter semantic mismatch | critical | mitigate | Closed by the unsupported-metacharacter corpus, including `.planning/STATE.md?`, and grammar-first rejection before governed-input comparison. `plan_73_18_task_1` passed 3 tests, all three unchanged sub-60-second `mix ci.evidence` runs passed 99 tests, and `mix ci.security` passed. | closed — fail-closed path grammar evidence |
| T-73-71 | Spoofing | symlink/untracked lexical owner provenance | medium | mitigate | Closed by component-wise non-symlink `File.lstat/1`, regular-leaf validation, and exact lexical `git ls-files --error-unmatch` tracking controls before discovery. `plan_73_18_task_2` passed 2 tests, all three unchanged sub-60-second `mix ci.evidence` runs passed 99 tests, and `mix ci.security` passed. | closed — exact owner provenance evidence |
| T-73-76 | Tampering | exported pure snapshot `governed_inputs` inventory | medium | mitigate | Closed by binding candidate governed inputs to the complete normalized stable capture inventory before reduction and rejecting omission, substitution, parent escape, absolute path, and reorder mutations. `plan_73_22_task_2` passed 1 test; the three unchanged `mix ci.evidence` runs and complete `mix ci.security` lane passed. | closed — governed inventory evidence |
| T-73-91 | Tampering | snapshot governed-input authority | high | mitigate | Recompute tracked governed inputs from the separately supplied repository root and compare both candidate lists before workflow reduction. | open — CR-01 |
| T-73-92 | Elevation of Privilege | Mix test argv | high | mitigate | Fully consume one closed test grammar, require a positive selected set, and reproduce and reject zero-test successful modes. | open — CR-02 |
| T-73-93 | Denial of Service | `jobs.security` dependency graph | high | mitigate | Reject every direct `needs` declaration on the mandatory security job and cover a skipped prerequisite. | open — CR-03 |
| T-73-94 | Tampering | PLAN task and acceptance parser | high | transfer | Keep open for Plan 73-25's closed task grammar and acceptance ownership repair. | open — CR-04 |
| T-73-95 | Repudiation | SUMMARY-add completion boundary | high | transfer | Keep open for Plan 73-25's completion-boundary classification repair. | open — CR-05 |
| T-73-96 | Tampering | merge commit changed surfaces | high | transfer | Keep open for Plan 73-25's explicit linear-history enforcement. | open — CR-06 |
| T-73-97 | Denial of Service | ExUnit include reduction | medium | mitigate | Share one OR/override selector predicate between live and snapshot paths and compare it with real commands. | open — WR-01 |
| DEP-73-01 | Tampering | Phoenix request handling dependency | high | mitigate | Upgraded Phoenix from 1.8.7 to 1.8.13 with its coupled transport dependencies in `ae1f0aa`; `mix ci.security` and `mix deps.audit` pass. | closed |
| DEP-73-02 | Tampering | Phoenix request handling dependency | medium | mitigate | The Phoenix 1.8.13 upgrade resolves `GHSA-63mc-hw7g-86rr`; the post-upgrade dependency audit passes. | closed |

The register contains 43 threats: 35 closed and 8 open. Six open threats are at or above the configured `high` threshold, so `threats_open: 6`; `T-73-12` and `T-73-97` remain visible as two open medium follow-ups below that threshold.

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
| 2026-09-11 | 36 | 33 | 3 (1 blocking, 2 non-blocking) | Post-Plan 73-19 correction for the later 2026-09-11T05:04:38Z review: T-73-67 reopened, T-73-76 registered, and the checked-in `ready_for_verification` `mix ci.evidence` lane observed 99 tests with 5 failures. |
| 2026-09-11 | 36 | 33 | 3 (1 blocking, 2 non-blocking) | Plan 73-23 evidence staging: `plan_73_21_task_1`, `plan_73_21_task_2`, `plan_73_22_task_1`, and `plan_73_22_task_2` each passed 1 test; three unchanged `mix ci.evidence` runs each passed 103 tests in 20s, 20s, and 21s; the complete unchanged `mix ci.security` lane passed (126s observed, with no timing ceiling). Final disposition reconciliation remains pending. |
| 2026-09-11 | 36 | 35 | 1 non-blocking | Plan 73-23 final reconciliation: `plan_73_21_task_1`, `plan_73_21_task_2`, `plan_73_22_task_1`, and `plan_73_22_task_2` each passed 1 test; three unchanged sub-60-second `mix ci.evidence` runs each passed 103 tests in 20s, 20s, and 21s; the complete unchanged `mix ci.security` lane passed. T-73-67 and T-73-76 close while T-73-12 remains an open medium follow-up below the blocking threshold. |
| 2026-09-11 | 36 | 35 | 1 non-blocking | ASVS L1 execute-phase post-hook recheck: the plan-authored register remains fully dispositioned, `threats_open: 0` at the configured high threshold, and T-73-12 remains visible as the sole open medium follow-up. |
| 2026-09-11 | 43 | 35 | 8 (6 blocking, 2 non-blocking) | Post-review correction for the 2026-09-11T19:23:38Z review: T-73-91 through T-73-97 registered open before source repair; CR-01 through CR-06 block closure and WR-01 remains a medium follow-up. |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [ ] `threats_open: 0` confirmed
- [ ] `status: verified` set in frontmatter

**Approval:** withdrawn after the 2026-09-11T19:23:38Z review confirmed CR-01 through CR-06 as blocker-class fail-open paths. T-73-12 and WR-01 remain visible medium follow-ups; fresh repair evidence and final reconciliation are still required.

## Plan 73-26 Current Proof Staging

PHASE73_STAGED_PROOF

The current repair evidence is staged while the six high findings and WR-01 remain open.
Disposition is intentionally unchanged until a later append-only reconciliation entry.

<!-- phase73-reconciliation-proof:start -->
```json
{
  "acceptance_task_ids": [
    "73-01-01",
    "73-01-02",
    "73-02-01",
    "73-02-02",
    "73-03-01",
    "73-03-02",
    "73-04-01",
    "73-04-02",
    "73-05-01",
    "73-05-02",
    "73-05-03",
    "73-06-01",
    "73-06-02",
    "73-07-01",
    "73-07-02",
    "73-08-01",
    "73-08-02",
    "73-09-01",
    "73-09-02",
    "73-10-01",
    "73-10-02",
    "73-11-01",
    "73-11-02",
    "73-12-01",
    "73-12-02",
    "73-13-01",
    "73-13-02",
    "73-13-03",
    "73-14-01",
    "73-14-02",
    "73-15-01",
    "73-15-02",
    "73-16-01",
    "73-16-02",
    "73-17-01",
    "73-17-02",
    "73-18-01",
    "73-18-02",
    "73-19-01",
    "73-19-02",
    "73-20-01",
    "73-20-02",
    "73-21-01",
    "73-21-02",
    "73-22-01",
    "73-22-02",
    "73-23-01",
    "73-23-02",
    "73-23-03",
    "73-24-01",
    "73-24-02",
    "73-24-03",
    "73-25-01",
    "73-25-02",
    "73-26-01",
    "73-26-02"
  ],
  "captured_at": "2026-09-11T22:20:30Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 26590,
      "exit_code": 0,
      "output_sha256": "63efcdfad52b5deebe31be118516c2879ebfa303e2d3b6c7639717145039ca85",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 116
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 25486,
      "exit_code": 0,
      "output_sha256": "310629c314a0d53c5c2a88c1c4afabe2c9b1b73e7b43bb44d5183944e477b1a3",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 116
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 28991,
      "exit_code": 0,
      "output_sha256": "c396e57c47f0735471d6ac0e10a0c059fd407a9d7b5ec00986b801a18c9429d6",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 116
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 1623,
      "exit_code": 0,
      "output_sha256": "9dc342a6f7fbf74826cb36a1d85171d35ed569fc8160025ad67c8f62b3ddcb10",
      "summaries": [
        {
          "excluded": 62,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1964,
      "exit_code": 0,
      "output_sha256": "d5e2363de002a72786f196f3fdf6375d9802601968045e9b98f389f66be66472",
      "summaries": [
        {
          "excluded": 51,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3065,
      "exit_code": 0,
      "output_sha256": "4ad17ff758077882ada07bc085ecd705bd56ec6de859941d1a4417639fcb489e",
      "summaries": [
        {
          "excluded": 50,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 3986,
      "exit_code": 0,
      "output_sha256": "2da7dd05ef3a1b09ecad612666a39b838449849a67085e40758523be517c267a",
      "summaries": [
        {
          "excluded": 60,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 3876,
      "exit_code": 0,
      "output_sha256": "d13cf11b516646ba7e911e58992167f43241f79cd0000f9810b7442bfd9bec29",
      "summaries": [
        {
          "excluded": 61,
          "failures": 0,
          "tests": 2
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "0ce52de9086df12894382683c0a41e8a82c3483593be0cc7090510faf796830d"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-24-PLAN.md",
      "sha256": "ed8c713aeb34af4a3538d2d11b3427e36264019095deefa8b582c3c0d2ad32f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-24-SUMMARY.md",
      "sha256": "fdc8e50d0bc425419aa3c669b5aaeccb6c05e7a1a0fc6a97ab75bbb5ddcbc257"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-25-PLAN.md",
      "sha256": "933f5e52a2988ea47132e28339d63ea39f2c2106fb87932c6ad02778f7ea865b"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-25-SUMMARY.md",
      "sha256": "572247fc6a5fcfe2f0411dc040a534286f5c1d2a7dfab0dd526f9b7b731f442f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-PLAN.md",
      "sha256": "5c8cb97358a0811d603e2fbc0e36290b0177c6ab96d53c497e07d6339a5af99e"
    },
    {
      "path": "mix.exs",
      "sha256": "b2afd5193ec1c54dec9777f989efa0f4524a2777a8c4ac3931b4d4af27ebe50d"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "107e178242014b7b2e84adddd25f2ce0a2e9e480109911eae9542caf7828d7f6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "28258bd1d8ad350f16607149d8f97ae29eb8caac7f8a71163e4829da50edfb3c"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "a1cc9cb0b69ade837a5169c615e7eb1e779eb298c27363b255e87b5f7f346f62"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "9b73b8cbe4f9ec126528836e10a1af2e0ad7f4fcdae50a2ea4fd81dcb5786b92"
    }
  ],
  "proof_set_id": "phase73-8f3da8af3cd49bac",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 143094,
    "exit_code": 0,
    "output_sha256": "288e9fa0fd2687cd82bed6d34fcc34c65d330a807144c3b2e69f1d06e399f8c2",
    "summaries": [
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 4
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 1
      },
      {
        "excluded": 3,
        "failures": 0,
        "tests": 9
      },
      {
        "excluded": 4,
        "failures": 0,
        "tests": 3
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 7
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 9
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 3
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 3
      },
      {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      }
    ]
  },
  "security_constituents": [
    {
      "command": "test test/conformance/sp_conformance_test.exs test/mix/tasks/relyra_conformance_test.exs --only conformance --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      }
    },
    {
      "command": "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 4
      }
    },
    {
      "command": "cmd mix test test/security/strict_default_proof_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 6
      }
    },
    {
      "command": "cmd mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 1
      }
    },
    {
      "command": "cmd mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus --warnings-as-errors",
      "summary": {
        "excluded": 3,
        "failures": 0,
        "tests": 9
      }
    },
    {
      "command": "cmd mix test test/security/xml/corpus_security_test.exs --only gate02_c14n --warnings-as-errors",
      "summary": {
        "excluded": 4,
        "failures": 0,
        "tests": 3
      }
    },
    {
      "command": "cmd mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 7
      }
    },
    {
      "command": "cmd mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      }
    },
    {
      "command": "cmd mix test test/security/xml_enc_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      }
    },
    {
      "command": "cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 9
      }
    },
    {
      "command": "cmd mix test test/security/metadata_attribute_injection_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 3
      }
    },
    {
      "command": "cmd mix test test/security/login_trace_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 3
      }
    },
    {
      "command": "cmd mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors",
      "summary": {
        "excluded": 0,
        "failures": 0,
        "tests": 5
      }
    }
  ],
  "source_digest": "sha256:52b09d8a9f43cdaeaafd5569888b3f11c8916f1f2feb1db367311d1bb95604e5",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

| Audit Date | State | Proof Set | Result |
|------------|-------|-----------|--------|
| 2026-09-11 | staged; findings remain open | `phase73-8f3da8af3cd49bac` | Five focused owners passed; three unchanged `mix ci.evidence` runs each selected 116 tests and passed in 26590ms, 25486ms, and 28991ms; unchanged `mix ci.security` mapped 13 positive ExUnit summaries and passed in 143094ms. |

## Plan 73-26 Final Reconciliation

PHASE73_FINAL_RECONCILIATION

The staged proof set `phase73-8f3da8af3cd49bac` is the sole source for these later
dispositions. The earlier open rows and correction audit remain unchanged above.

| Closure | Finding | Owning selector | Proof set | Final status |
|---------|---------|-----------------|-----------|--------------|
| T-73-91_CLOSED | CR-01 | `plan_73_24_task_2` | `phase73-8f3da8af3cd49bac` | closed |
| T-73-92_CLOSED | CR-02 | `plan_73_24_task_3` | `phase73-8f3da8af3cd49bac` | closed |
| T-73-93_CLOSED | CR-03 | `plan_73_24_task_2` | `phase73-8f3da8af3cd49bac` | closed |
| T-73-94_CLOSED | CR-04 | `plan_73_25_task_1` | `phase73-8f3da8af3cd49bac` | closed |
| T-73-95_CLOSED | CR-05 | `plan_73_25_task_2` | `phase73-8f3da8af3cd49bac` | closed |
| T-73-96_CLOSED | CR-06 | `plan_73_25_task_2` | `phase73-8f3da8af3cd49bac` | closed |
| T-73-97_CLOSED | WR-01 | `plan_73_24_task_3` | `phase73-8f3da8af3cd49bac` | closed — implemented |

The final register contains 43 threats: 42 closed and 1 open. Historical medium
`T-73-12` remains visibly open below the configured high threshold; zero high or
critical ASVS Level 1 blockers remain.

### Final Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks remain documented in the Accepted Risks Log
- [x] `threats_open: 0` confirmed at the configured high threshold
- [x] `status: verified` set only after the shared staged proof passed

**Approval:** verified from canonical proof set `phase73-8f3da8af3cd49bac`; CR-01
through CR-06 and WR-01 are repaired, while T-73-12 remains the sole visible open
medium follow-up.
