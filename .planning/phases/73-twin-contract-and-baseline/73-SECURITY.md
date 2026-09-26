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

## Post-Review Correction — 2026-09-24

The later review reopened CR-01 through CR-07. This correction supersedes the live
verified status above until the repaired repository has a newly captured and replayed
proof. All seven high-severity findings are open before repair evidence is accepted.

| Threat | Finding | Severity | Current state |
|--------|---------|----------|---------------|
| T-73-98 | CR-01 proof identity | high | open |
| T-73-99 | CR-02 typed report state | high | open |
| T-73-100 | CR-03 workflow event ownership | high | open |
| T-73-101 | CR-04 security inventory | high | open |
| T-73-102 | CR-05 mandatory replay owner | high | open |
| T-73-103 | CR-06 duplicate task children | high | open |
| T-73-104 | CR-07 descendant plan assignment | high | open |

Current register: 50 threats, 42 closed, 8 open. Seven high-threshold blockers
remain open; historical medium T-73-12 remains a separate non-blocking follow-up.

## Plan 73-30 — Current Proof Staging

PHASE73_STAGED_PROOF

The newly captured canonical proof is staged after the current-review correction. Live
security and validation state remains open until the mandatory reconciliation replay passes.

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02"
  ],
  "captured_at": "2026-09-24T04:30:46Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 38977,
      "exit_code": 0,
      "output_sha256": "f940e52413e19d66d24d8b74cbff68f139d7cc7d7fdf5e90e94af45f02eb74a7",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 122
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39661,
      "exit_code": 0,
      "output_sha256": "7a242848a213fcfa5477f7de454e0bf70b8161b37eaf538bd4717a0ef017c07b",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 122
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 41466,
      "exit_code": 0,
      "output_sha256": "66391cafe80bace5b20516f8814bb80f365b123743a78f394a0bd93d6b97e0d9",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 122
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 1406,
      "exit_code": 0,
      "output_sha256": "a672e8ec3deaed18c1392e07aaab7dd13ea7b4cef17c17d19fa914d0a2514b52",
      "summaries": [
        {
          "excluded": 66,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1564,
      "exit_code": 0,
      "output_sha256": "5574a8de06fbc83ea8bc6bda02c53400ec1526fdde16b5ae49166b946a630de5",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2726,
      "exit_code": 0,
      "output_sha256": "d12d7c41907e2a3b3112ab254e4ebe500f27fc28d42b64ac2c7e3ade03c6bc6d",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 4840,
      "exit_code": 0,
      "output_sha256": "5ec665a3f653c1ba8e2e69b59f14444dd8042f972bc7a9f0eb6aecf958303be7",
      "summaries": [
        {
          "excluded": 64,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 4559,
      "exit_code": 0,
      "output_sha256": "382fe994724881fa4c1494043a1bbdb4a916a97b3112f2b0dda22663092cc7ac",
      "summaries": [
        {
          "excluded": 65,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 955,
      "exit_code": 0,
      "output_sha256": "2214842ed0286b42e16d61e9bceb3322ca4ad74bacb4e438371d1679c2f42c93",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 819,
      "exit_code": 0,
      "output_sha256": "8cc3d07385a412b229f3eb90efdc207e1c043a2bc3696b0419cfc08af131ad6b",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1288,
      "exit_code": 0,
      "output_sha256": "ff3d8ee37eb9724d5a3862a4725701922f4e08dca3efeefa540348f376de33f6",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1460,
      "exit_code": 0,
      "output_sha256": "706003ea54f02f6e8f8b0d66bdbe027ab5512eaec95cb8aeeff9c90d4f6897ec",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 3790,
      "exit_code": 0,
      "output_sha256": "503a17b3faafc0e62319c5e38d517ed6d43058ecd8e5f0a867ae7f5c3e226f0c",
      "summaries": [
        {
          "excluded": 64,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 3836,
      "exit_code": 0,
      "output_sha256": "9cafbe55750e95243523ad2675d1170f6394d390e3b09547c335da7fbab4d5d6",
      "summaries": [
        {
          "excluded": 66,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1045,
      "exit_code": 0,
      "output_sha256": "9ba07832bb4917e4d50e4d7dfcd4489aac7514d3027043619121de71585ad80a",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1351,
      "exit_code": 0,
      "output_sha256": "dea93f27d048c948a27e314895f8161d30b6eeaa2dbfbb623ff49bf914cf40bf",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "e96ed1b4baf41f3dac929e35b423686deb3f90bc150bb5611f60518c2a81b340"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "8ee29befe29b02b8d28b8628d303c30e6a3ce587ba773bc56544ff98e2a127f6"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "7a6713a0da819da2405711cc23e379d7e0d3a790ccaa0bb5e5ed99ade784f181"
    }
  ],
  "proof_set_id": "phase73-ee03f81466f07b09",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 143778,
    "exit_code": 0,
    "output_sha256": "3a5c308fa8e4ce49ad612cb7ea019d2d90a006c66b2fc7fc6f883b41769de170",
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
  "source_digest": "sha256:04d52027714bf48aea66382540480802c9ed81f91526ce4f09d71c29e8950a99",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

| Metric | Current staged result |
|--------|-----------------------|
| Proof set | `phase73-ee03f81466f07b09` |
| Focused owners | 13/13 positive |
| Mandatory evidence | 3/3 unchanged runs; 122 tests each; 38977ms, 39661ms, 41466ms |
| Security composition | `mix ci.security`; 13/13 positive constituent summaries; 143778ms |
| Nyquist compliant | no — staged proof precedes final reconciliation |

## Plan 73-30 — Final Security Reconciliation

PHASE73_FINAL_RECONCILIATION

| Threat | Finding | Severity | State | Closure evidence |
|--------|---------|----------|-------|------------------|
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-ee03f81466f07b09` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-ee03f81466f07b09` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-ee03f81466f07b09` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-ee03f81466f07b09` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-ee03f81466f07b09` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-ee03f81466f07b09` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-ee03f81466f07b09` |
T-73-104_CLOSED

Current register: 50 threats: 49 closed and 1 open. Historical medium T-73-12 remains
visible and is below the configured high threshold. There are zero high or critical blockers.

Proof set: `phase73-ee03f81466f07b09`; all closure rows reference the same captured and replayed proof.


## Plan 73-31 — Current Proof Refresh

Refresh chronology: the tracked inventory covers 31 plans and 66 automated acceptance owners. This proof was captured from current governed sources and replayed through all focused selectors, three bounded evidence runs, and the pinned security lane.

## Post-Review Correction — 2026-09-24

Plan 73-31 current refresh; prior September 24 records and finding chronology remain preserved.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02"
  ],
  "captured_at": "2026-09-24T13:17:19Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 53816,
      "exit_code": 0,
      "output_sha256": "68d1c26c3320b67edcb6f9a68f79a1dcbcb65972ba4168c832eee5aed88bf871",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 124
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 53930,
      "exit_code": 0,
      "output_sha256": "b64a9cfd86a7e970a1f462661093535d711afac2e532d99d0b60fe08dfab8b6e",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 124
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 53488,
      "exit_code": 0,
      "output_sha256": "4ca1673a118e9c33e033255ea8f9973f2ed57d146961c9762ce9a0f86c58b261",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 124
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 1681,
      "exit_code": 0,
      "output_sha256": "f9091efdbef76a5f9dcd3844e49c43108f44abe4d34844c29aae56e26e52c440",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2016,
      "exit_code": 0,
      "output_sha256": "f3accce6f80c4b80d24493bb8a8838408321337fc2f9953efec74208c73ba977",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3285,
      "exit_code": 0,
      "output_sha256": "60e5e9cdffea6a277bb002df7d801a8eb442c9e3a575ebac90c6c36ac6b4168f",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 5300,
      "exit_code": 0,
      "output_sha256": "2843b62ba4db479540d6cbb98a5b0dab284a2b02e04cd6c094553ad404ae64fd",
      "summaries": [
        {
          "excluded": 66,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 4558,
      "exit_code": 0,
      "output_sha256": "fbef545ed305222055570bacb4b6148cf682f7349ad5401d13b3c900d9b98689",
      "summaries": [
        {
          "excluded": 67,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1301,
      "exit_code": 0,
      "output_sha256": "d4bfcc6e9b2316c7e125d13af7d3ebdb6395ac80f42a80216ac8eeb67c825fab",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1306,
      "exit_code": 0,
      "output_sha256": "1f182d74cb0ef4af9202a64036024719516b79c72b8b1880bf3544d56262832e",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1418,
      "exit_code": 0,
      "output_sha256": "9f3bec9ed6305539fd15bd281012eb89ba124db9230e352dd466b62436474e6d",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1464,
      "exit_code": 0,
      "output_sha256": "b392f838409944be4bb8f418e3fc507bf5f4f2ebc74bcf95e16879b4c5f0d6fd",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 3354,
      "exit_code": 0,
      "output_sha256": "50b3dcf17edad3d262d529d5ad16368e771b2f505f824acb9c2bb06b8391a50f",
      "summaries": [
        {
          "excluded": 66,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 3590,
      "exit_code": 0,
      "output_sha256": "6d0f41328f0416af007fd50df44b72612332e64b30580e83160d5e0ef7c8c582",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1295,
      "exit_code": 0,
      "output_sha256": "b2634a5ba776b1236fda1632444b76455a939a436f5d5e99c90f533c50658a76",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1367,
      "exit_code": 0,
      "output_sha256": "0356f18c12802f6805e63013077958e20ade46769ac614d0132128cf54f0d9d0",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 1684,
      "exit_code": 0,
      "output_sha256": "0c2d2cdec0a4e9a3ef1c2565d6bd024e6598e93276188547d0e4942b2a9f3800",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 4639,
      "exit_code": 0,
      "output_sha256": "87f4d667d4c069ca0abe026001fb5fcba61da9b6d216211ebe6cb39ba32202e7",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "9dc6f2286916246d0d005d371b327e73fac37dc79d4c22b475a1c7c5c5eeb657"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "a5709822901f688b4b48ff8522349685c90b4e25968e4fd46b2724269fd435a1"
    }
  ],
  "proof_set_id": "phase73-2fc3c2eaf9548744",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 104348,
    "exit_code": 0,
    "output_sha256": "b52913e34c6ace2f902d23ec5c63b19f6af761a606b523617f3492bafdcf6f54",
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
  "source_digest": "sha256:71750cf9d7e6ee9d541645682cb2a39c1309119395ba76e3ce4f28f3fc10ecdf",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

## Plan 73-31 — Final Security Reconciliation

PHASE73_FINAL_RECONCILIATION

| Threat | Finding | Severity | State | Closure evidence |
|--------|---------|----------|-------|------------------|
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; refreshed current proof `phase73-2fc3c2eaf9548744` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; refreshed current proof `phase73-2fc3c2eaf9548744` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; refreshed current proof `phase73-2fc3c2eaf9548744` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; refreshed current proof `phase73-2fc3c2eaf9548744` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; refreshed current proof `phase73-2fc3c2eaf9548744` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; refreshed current proof `phase73-2fc3c2eaf9548744` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; refreshed current proof `phase73-2fc3c2eaf9548744` |
T-73-104_CLOSED

Current register remains 50 threats: 49 closed and 1 open. Historical medium T-73-12 remains visible below the configured high threshold; zero high or critical blockers.

Proof set: `phase73-2fc3c2eaf9548744`; all seven closure rows reference this recomputed and replayed current proof.


## Plan 73-32 — Current Proof Refresh

Refresh chronology: 32 tracked plans, 68 automated acceptance owners, and 17 positive focused selectors. Three separate mandatory evidence runs completed successfully in 50986ms, 52467ms, 58389ms; the unchanged security lane recorded 13 positive constituents. The current report state is tied to proof `phase73-e76f4d404296add9`.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02"
  ],
  "captured_at": "2026-09-24T15:29:58Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 50986,
      "exit_code": 0,
      "output_sha256": "8e575f5117b76c18fa8bb3a1f27a35d9cb2ad8e5f9b7ccfc49fea8b8c102b4fe",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 125
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 52467,
      "exit_code": 0,
      "output_sha256": "e693bf469e1f9870184b0815c829a6d90afbe6f6391ada5e6cf425b60103628a",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 125
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 58389,
      "exit_code": 0,
      "output_sha256": "141bdb514ead80476e321329cff3bf66ca114a9b3d38824e1f393fb68d07888a",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 125
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2067,
      "exit_code": 0,
      "output_sha256": "4887fc8614d019ab45c16bb78dd0effb246a5dffda68f8ec6286a6a0935fa3c6",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2596,
      "exit_code": 0,
      "output_sha256": "9787bd2f3bfb6c9ce918fe730ab7fecf6468b571f64c3c89eb5027f219265595",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4191,
      "exit_code": 0,
      "output_sha256": "5e309dd87dc6e79506c7ead9e8950c295296d94d61449bd80975b45f65d4b4ae",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 7510,
      "exit_code": 0,
      "output_sha256": "06ca2776e73a8a3adb90892ac1c49ffbe1bb230eb6368dbf5496530baa2f6206",
      "summaries": [
        {
          "excluded": 67,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6536,
      "exit_code": 0,
      "output_sha256": "e0a485cc39443dd725d1a54a4932c3878c30705931b9ed81290266330d8d5ad3",
      "summaries": [
        {
          "excluded": 68,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1662,
      "exit_code": 0,
      "output_sha256": "eae6f19f5b42aa7f63386ec126d4cba2096e7b5a010825219a37faa9203d668b",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1512,
      "exit_code": 0,
      "output_sha256": "81d9d8532fbc4a12e17ddba5c3b45f71d336503dbd49a0ca01c40c6779dceb5b",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1758,
      "exit_code": 0,
      "output_sha256": "d1057beb03f2a519b236dc622390847d9d1fccf811e43d2d12714a9bab4394f3",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1926,
      "exit_code": 0,
      "output_sha256": "122f482336b2846a3e20ac05010073ee59356bd0aea3b493774d6d8d5b28f0b9",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5157,
      "exit_code": 0,
      "output_sha256": "596cef6ee28bdadfef7aaf229d86aa3fbf9f2da6deaf8cb0a92a935154768b2a",
      "summaries": [
        {
          "excluded": 67,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4624,
      "exit_code": 0,
      "output_sha256": "2f9651449ef71e38c76fc892e862250cda0eb2643f4393cb1ee0bba702c3fd56",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1644,
      "exit_code": 0,
      "output_sha256": "3e3f05105a7549473ab1c13fdf8844abb967beed3bcfdc71969127d48c3e57ad",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1631,
      "exit_code": 0,
      "output_sha256": "3f527a436dd79fed887d81465f0dd610d50c744984359ead464ac5b0c5cb414a",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2218,
      "exit_code": 0,
      "output_sha256": "d3c37f0fcd2e9ac6b1ef4cbb9c42f463ab0047705fb300ceb6781da09f27e495",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 6793,
      "exit_code": 0,
      "output_sha256": "c5c46613a94c3edb135d05a16c0d2e27e96055ec157105f0102efeabc8db5cdd",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 25686,
      "exit_code": 0,
      "output_sha256": "652c43d97d7550213a85971f1671dd5c2565742f8ac7d66908bf1b0aa7f1a6bb",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2105,
      "exit_code": 0,
      "output_sha256": "b414f581fb4c9a24a8edff81b9725c301e418479ecd6ed115acfd29544c709e8",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "34d8d4b99756413b190a06e5c2c2ebbe1125f9f3156023a0bb58f02158ccdfe4"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "048d96d9ab0694a38a176de6122af29a7f0bc26e0a3654272d8984df1aea83b8"
    }
  ],
  "proof_set_id": "phase73-e76f4d404296add9",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 105696,
    "exit_code": 0,
    "output_sha256": "566c2ba5846b6d7a1562a695e1044ce3de13dff94d0eb2d4809f4a94bbe48861",
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
  "source_digest": "sha256:f3d5d9905300267690652c266472b1b5e88b621989940283d4149dec414cfdf3",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

## Plan 73-32 — Final Security Reconciliation

PHASE73_FINAL_RECONCILIATION

| Threat | Finding | Severity | State | Closure evidence |
|--------|---------|----------|-------|------------------|
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-e76f4d404296add9` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-e76f4d404296add9` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-e76f4d404296add9` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-e76f4d404296add9` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-e76f4d404296add9` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-e76f4d404296add9` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-e76f4d404296add9` |
T-73-104_CLOSED

Current register remains 50 threats: 49 closed and 1 open. Historical medium T-73-12 remains visible below the configured high threshold; zero high or critical blockers.

Proof set: `phase73-e76f4d404296add9`; all seven closure rows reference this captured source-bound proof.

## Plan 73-33 — Current Lifecycle Reconciliation

The completed Phase 73 / planning Phase 74 identity passed the current lifecycle owner.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02"
  ],
  "captured_at": "2026-09-24T18:13:09Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 41203,
      "exit_code": 0,
      "output_sha256": "68c65187fe6eff0161d8519cac4e13bd634e84d3a58ea070e6122189357f9deb",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 38631,
      "exit_code": 0,
      "output_sha256": "75b7416f25884e0e77e1c8b1df6b4a39482c252ff9b0d60d79deb3ace333740e",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 32368,
      "exit_code": 0,
      "output_sha256": "27a20581e9f02954d1b556a70049cae31f267f481b665b77d8ed124ad0e9953e",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2270,
      "exit_code": 0,
      "output_sha256": "49e4755a89c6407c417b38be3282ecbd16948bce819b2af88416b7508cd63ed1",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2696,
      "exit_code": 0,
      "output_sha256": "625047f7e671904c5f30406a94441165387bbeccd34b4f4a0574a6f7f9c2cd23",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4212,
      "exit_code": 0,
      "output_sha256": "50a0451bf672960ff9e5ecb0136b4519875312389a3e421c47834984e4b26aff",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 7344,
      "exit_code": 0,
      "output_sha256": "5bc8fe936e468bb9d6c69a66c5ea010e7b572f278925ebccd02016c5e196541b",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 5992,
      "exit_code": 0,
      "output_sha256": "6e664dc23717e0d1d8705b921012ede29fd280810af89860752efa0f782a7f96",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2331,
      "exit_code": 0,
      "output_sha256": "c4b46661f277c9dbcad2cd8c26887e9d2d3565f16126c9b864acfcb6f52837dd",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 2233,
      "exit_code": 0,
      "output_sha256": "8acb078befe74c14833ab9876c204d78e0a24dc9f9f3116b0999d5ac018dbd80",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2004,
      "exit_code": 0,
      "output_sha256": "7152ad7e722578e46a82cfedace2101986354fefc0104d123b114790811d3192",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1927,
      "exit_code": 0,
      "output_sha256": "f7267f178f5ff954a5f77a6e256757b933dbb2b449dd26e4335379e21c9c969d",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5032,
      "exit_code": 0,
      "output_sha256": "eb71e6676b05d028c55199fda269b2953943a6ae495ab2a8199e7d2e03ed1b58",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6629,
      "exit_code": 0,
      "output_sha256": "1120e85a16778052c2da74f30bef815e3bbced89507a82b472841b257d579223",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1845,
      "exit_code": 0,
      "output_sha256": "e0e453b43bd57daa54ab81f2a645ccc05afc32ffb060364b9e3eb0198d06dacf",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2799,
      "exit_code": 0,
      "output_sha256": "298432ad4c10dcd49ec76f839435ad7ccc27ef1cfb97fa2e793cf3ea581a33e0",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2515,
      "exit_code": 0,
      "output_sha256": "ba8d2b5980cf4187170ff8ddcad275abb603beabaa6778abffa6c81302191c6c",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7141,
      "exit_code": 0,
      "output_sha256": "eb989547756d15dec12b2efc66eb438366b77e10272cd13f23bf8b0dd4d4d5df",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 2571,
      "exit_code": 0,
      "output_sha256": "b27bf6e9ede38491d3ea4ff7f4dd76451bab12ff3031f75915bf521245cee2ad",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2550,
      "exit_code": 0,
      "output_sha256": "057d217438e466476d56d812f3d36f2a71eba380289b636c9f8908592e9e3f7d",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2659,
      "exit_code": 0,
      "output_sha256": "97058a06ad01d128284634adf528beea90baa4aa03af31bf71783e1e98d8136f",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2641,
      "exit_code": 0,
      "output_sha256": "3e3acac7df724b0d89090cff24a7eb57fae27c9fbf92325556894c6d0598be60",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "f8807ee4598c0948f4629c55347c82fb903b2b855104ecc8b9d6a66df324f93f"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "08a246b4b8816f503aa7a6189df1421dd57ae9230987b5aeea41283050cb9969"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "e64834e8ae87d2d25d10d41825ff331ef911ca8b34163eee82567a03652ec8c1"
    }
  ],
  "proof_set_id": "phase73-75f9745703c89de4",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 144696,
    "exit_code": 0,
    "output_sha256": "64e9816e10ac8a37086c5b938217d4068f436e3e868a412649429f88df4096db",
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
  "source_digest": "sha256:8574e598fc7b225b258a6c33ba27abf0e126a1a60adae0704d3c3958cf987201",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION

| Threat | Finding | Severity | State | Closure evidence |
|--------|---------|----------|-------|------------------|
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-75f9745703c89de4` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-75f9745703c89de4` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-75f9745703c89de4` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-75f9745703c89de4` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-75f9745703c89de4` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-75f9745703c89de4` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-75f9745703c89de4` |
T-73-104_CLOSED

Current register remains 50 threats: 49 closed and 1 open. Historical medium T-73-12 remains visible below the configured high threshold; zero high or critical blockers.

Proof set: `phase73-75f9745703c89de4`; all seven closure rows reference this captured source-bound proof.

## Plan 73-33 — Active Main Reconciliation

The merged main checkout passed the mandatory lifecycle evidence lane while Phase 73 was active. The source-bound proof was freshly captured after the lifecycle and provenance corrections.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02"
  ],
  "captured_at": "2026-09-24T19:27:01Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 52208,
      "exit_code": 0,
      "output_sha256": "8b199d556f8ec6f50e7305a7a4859199cadf68f4ddf0743aa1d0c37d62a008f1",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 51104,
      "exit_code": 0,
      "output_sha256": "95e31a2c38a9f21d93a6fb442a0d09d760a32ee508a58c66539c72ce98424e22",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 50273,
      "exit_code": 0,
      "output_sha256": "fb092c37c29c8a010eee987d8465340fa7f8e625f406978b5ba5f7a25ad7db68",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2203,
      "exit_code": 0,
      "output_sha256": "0a2c638d77f56f1ce75df1d5fe47e0f1f461a3325931e1cf39ef59c0f96832e1",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2584,
      "exit_code": 0,
      "output_sha256": "c1b82cf46d7c8a0b90e4bf3545c6799f55b5068af1b23fe1a24631e1e88009b5",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4441,
      "exit_code": 0,
      "output_sha256": "bec16212c929594ce9ec3ab08ce940f9eba8b207daca6fe9ee9ce09a350d2030",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 6876,
      "exit_code": 0,
      "output_sha256": "549a5beef30a75fb51eabb50a6cb35d2e9902ec7ad71abee9e4562ae4b3fbc20",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6267,
      "exit_code": 0,
      "output_sha256": "4ffd8dea22ae56a1ec09317ce30cac9d454d1f5fcf8587473b13a914c196ebbd",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1692,
      "exit_code": 0,
      "output_sha256": "23fb792e30ffc28affbd32799a13565c2e7ba094ddeae510ba7d9bae12824123",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1514,
      "exit_code": 0,
      "output_sha256": "2723cab3ecb6005e6da05f0b4de631af73726069bed6166073ecd9bbc1d50bda",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1764,
      "exit_code": 0,
      "output_sha256": "aa1ce67b1ff48750eca08822db802437a2a6a897437e384568f139ca55af8400",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1794,
      "exit_code": 0,
      "output_sha256": "0b3d09ede733371f43456f1ef64304575ff1be3cb9572114514d66c403869759",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4243,
      "exit_code": 0,
      "output_sha256": "bfcfed8b7a06b38663096fb451b6e07e499b122ca8999930f3db6ad037fdbd09",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4791,
      "exit_code": 0,
      "output_sha256": "c326055f6353074219f5b6bf2b1f1dc01cbb091f5550b4161bdd6dccf58264ce",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1728,
      "exit_code": 0,
      "output_sha256": "f8d8dabae272e44286c5fc2720f121cc60606e34a74590babbe5ccfdd7883d2d",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1666,
      "exit_code": 0,
      "output_sha256": "4f820c6c144d2447f31e473d509f3509549ae40d66d88b88b8d0691fa22e0a46",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2289,
      "exit_code": 0,
      "output_sha256": "e9e9c8cb40fe4f9ca7ef4c2fc7a1e97e4c35609906aa701f8dcc5556c5a95c3e",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 5971,
      "exit_code": 0,
      "output_sha256": "3147669a936403f8965b56ea627ff7892ae7c7f2d197e6491f709ea88fa93399",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 19610,
      "exit_code": 0,
      "output_sha256": "2f5d39128d315efef2a25ad572759a7ff39de0fef647c22e32c3038a5ed88524",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2194,
      "exit_code": 0,
      "output_sha256": "900abf5ed11057260fc2b3e2364d1f34924566790331b384f0d9f5b6b0e303cc",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2178,
      "exit_code": 0,
      "output_sha256": "7a373169e286dce944520fc813f47c54b998b718f0ff479d0fc35790e9fa0a7f",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2223,
      "exit_code": 0,
      "output_sha256": "a64fe34ac4beda59edf6b56995c8cc6ba4a6d411acc86c9eb77279a85f296bae",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "c2a4c8d1513dda0fb6e16d938a5cfac869a6179f89aef2a940aca8fc2369bffa"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "551964c6d8667154f06db632e479e9f449ce7597b87b3e4e4adcfb725764fff1"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "e64834e8ae87d2d25d10d41825ff331ef911ca8b34163eee82567a03652ec8c1"
    }
  ],
  "proof_set_id": "phase73-c5d6c300740e329c",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 141726,
    "exit_code": 0,
    "output_sha256": "53ecbd409cef22f04ddfab32d33f7d758d716e89a9aee356d552022c9a06c93e",
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
  "source_digest": "sha256:c3032c796563369580aa50cb2196503588a933ee400332c6e543637307e7e8dd",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION

| Threat | Finding | Severity | State | Closure evidence |
|--------|---------|----------|-------|------------------|
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-c5d6c300740e329c` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-c5d6c300740e329c` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-c5d6c300740e329c` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-c5d6c300740e329c` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-c5d6c300740e329c` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-c5d6c300740e329c` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-c5d6c300740e329c` |
T-73-104_CLOSED

Current register remains 50 threats: 49 closed and 1 open. Historical medium T-73-12 remains visible below the configured high threshold; zero high or critical blockers.

Proof set: `phase73-c5d6c300740e329c`; all seven closure rows reference this captured source-bound proof.


## Security staged source refresh — 2026-09-25

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02"
  ],
  "captured_at": "2026-09-25T02:32:59Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 27726,
      "exit_code": 0,
      "output_sha256": "53a01eef3b9d3d478809e602bd1260cb47e9128c866a28106cf51a17a57a499c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39358,
      "exit_code": 0,
      "output_sha256": "3be234570c4a252b8573e611a8b93aefc50fc452dc2277e716ec79e77a24fc39",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 42992,
      "exit_code": 0,
      "output_sha256": "af21f8e7a107700799da79d98da9d40151e98a720510933aa49cf979908dab5c",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2304,
      "exit_code": 0,
      "output_sha256": "701a56808efa1d56a92481d59e60f03667233fe171d22b17f74364d5c2c393e6",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2299,
      "exit_code": 0,
      "output_sha256": "adb07c7f5dd95d3b86af7dfaa24fd6b48153e222741a6190eff13a8b53076623",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3617,
      "exit_code": 0,
      "output_sha256": "28cd475100fb89a13c86626daae1a994ccc725a8a3c5d420655e911ffffe72b6",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 4545,
      "exit_code": 0,
      "output_sha256": "54fbebf7901897d62b1e95e8c7621affa8ee3f04cff0e27a000c6d9da74a3e22",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 6336,
      "exit_code": 0,
      "output_sha256": "ee59552ec19ad9b33e1e9d629f61c54f4c5ee2118cbd2fe99d3215e9c1f0e206",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2235,
      "exit_code": 0,
      "output_sha256": "dd8b73ef6d9d9d6726706e2124a3d951fd259cab0a29855adddfa69adfe0165f",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 2020,
      "exit_code": 0,
      "output_sha256": "c2ef8fbda7129d58832007e6c4094c2f4af791cd81be93847ba2529f2dafa49d",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2286,
      "exit_code": 0,
      "output_sha256": "d260e3b9023f650c47625ca3cbae3541df2845a08fbb4cdf60c49bbccbf23f28",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1854,
      "exit_code": 0,
      "output_sha256": "b04108cd32bb9d8fd1fa81eb9b2ac7f905b160af1830e2b36a9bb7a1c4b3662b",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4914,
      "exit_code": 0,
      "output_sha256": "01ef72e32ad15328214dcd729c7930081ffa78ef0560bb99948cdb81ad542659",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 6056,
      "exit_code": 0,
      "output_sha256": "ad7f742b18d38e9b14cb0dab145622b479df6c5bb98bb51de4e50f378bda5c0f",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 2911,
      "exit_code": 0,
      "output_sha256": "0f57d91701a4d24666bdd3ff322a25c9fe9a6ecca99131ae7944b6c5bb117416",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2228,
      "exit_code": 0,
      "output_sha256": "87d3ad5e9fd7bae5f35758433fea904378f84a1d134881c85720b44b85519b32",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2739,
      "exit_code": 0,
      "output_sha256": "81175654031fa2e297814ac0a3f0f3ee583086603591d083a4b90a904c9266c0",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 8321,
      "exit_code": 0,
      "output_sha256": "5f5d98de0ac948c5bd16520b610137d598fff3d74f4c182743c5c3969f630eb7",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 3539,
      "exit_code": 0,
      "output_sha256": "ea9088a98b112b05d23662749d46ba1ac53de489ae100078dbeb979e3bacfd01",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 1745,
      "exit_code": 0,
      "output_sha256": "d8c0620454cf7dd5bfc7d8e41d16eeab3a4a6cca93b910b9fa1441125e988c1c",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 1789,
      "exit_code": 0,
      "output_sha256": "9ce934e6f29c8b5bd74e833e74da6b2185a8723fa095d42f41906e2dcb4194d0",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 1967,
      "exit_code": 0,
      "output_sha256": "a5e8e9f6a176700a0e5ac79061779e4dbacf8a3372f6f68a078c5f30b48a5f34",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "dc1def34352f26ec42e0e1cfbe4089de068d3b64879a2e8af1820bfd4d965f48"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "e64834e8ae87d2d25d10d41825ff331ef911ca8b34163eee82567a03652ec8c1"
    }
  ],
  "proof_set_id": "phase73-4c6282e831f7ae0c",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 115743,
    "exit_code": 0,
    "output_sha256": "182b975c737648a65e24a10b348f4e266939a1f7ce41dee7600f0c9ae68c99f4",
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
  "source_digest": "sha256:e863094268dfe934b9e6aecd4c46f144e7a21a60adaac5c7657fee50c3db0925",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->


## Security final reconciliation refresh — 2026-09-25

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02"
  ],
  "captured_at": "2026-09-25T02:40:58Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 45120,
      "exit_code": 0,
      "output_sha256": "3f06d7ddf285cbaa98aaedb2d916920011851b54884c3ac65235d32b03aa3530",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 39455,
      "exit_code": 0,
      "output_sha256": "ad0a7b4e9e51a34a70438d6dc531e4ccec428de9ce2a0cb710a291056e652469",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 36102,
      "exit_code": 0,
      "output_sha256": "15257952118b14d0819bc2a41293c96936be6ac017c3283bc028bb5e02629972",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 127
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 1888,
      "exit_code": 0,
      "output_sha256": "16286f93028cf14d6306a0a7135748c3ffaed2fd871687544309a9cab07f726b",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2146,
      "exit_code": 0,
      "output_sha256": "84a4623eace4e8df62e5a9dfa4d56c09910057a54b66ddba1ed605422742ba80",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3375,
      "exit_code": 0,
      "output_sha256": "6b09cb569cbb38f47d52a39d44e759b7e7b787194c90daf16a1e23b60cf421d7",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 4258,
      "exit_code": 0,
      "output_sha256": "81239a7af6e019970639f918d35ec65ccb285d8902dc2dee38b7af10af343b72",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 4765,
      "exit_code": 0,
      "output_sha256": "6871a83ad2c5bf3af7c9a2b289901a4565c858ad520dff6205ce72b01b3310d3",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1677,
      "exit_code": 0,
      "output_sha256": "d0bd00b224df1c5b3e3c5f7547c3d3f8ff09d7f698d95d21c91ffc4f319f114f",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 2279,
      "exit_code": 0,
      "output_sha256": "17fdf4f802a3d89638cd8449df51f8d6801e559d4b9bf12ac4727c0353877524",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2779,
      "exit_code": 0,
      "output_sha256": "f3cdc17f0f70044781a6b2d8cea7b797ba4620bcda0d3ed9ac2b59856b351a02",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1898,
      "exit_code": 0,
      "output_sha256": "f654bfb60ba139f5cdf6b69d46150e1e9d4ebe943ccb64473556f309c114cf80",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4267,
      "exit_code": 0,
      "output_sha256": "9fc3f21c44d46d6cdd0c70e4bd0e3749efc4a6c91bfb058dbc6fdcb5ce08a85b",
      "summaries": [
        {
          "excluded": 69,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4708,
      "exit_code": 0,
      "output_sha256": "00e44e4763c53aa4512c39bc83d17bb5932ef72c775d501553457e387098967e",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1659,
      "exit_code": 0,
      "output_sha256": "a4130fd56d9c623b1216e76eebf4d820f9e73c0bf7d625cc472652d597ffee7e",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1690,
      "exit_code": 0,
      "output_sha256": "1946fe6546d815bdbbecfccf3761604781c06ec39e0692ca4fc55040e48c4758",
      "summaries": [
        {
          "excluded": 4,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2022,
      "exit_code": 0,
      "output_sha256": "1a2992ada52600dc623c2499f47505682889fa3820373576bed9c82f5e42fa91",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 5496,
      "exit_code": 0,
      "output_sha256": "104360930c38786d535d1cc14a3d9428189cfb1fac076ddb85c143e9b39196d4",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 3862,
      "exit_code": 0,
      "output_sha256": "d7f371c6b7e009da5b2efebbb0554b8376949509634d2169fc24321dda8c0d96",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2641,
      "exit_code": 0,
      "output_sha256": "c6d42f9d0ce2f98bc58805d8811d65d88a2173cc756000953cc4f01de618fa51",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2831,
      "exit_code": 0,
      "output_sha256": "2abf197cb3b003d007bb1caf9d8fcb9fb27e39900595bf0e8fdd243a2e4b2ad5",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2845,
      "exit_code": 0,
      "output_sha256": "3ecb56c72d0b5ec9a2fdeb09181dd32f98db2e42b43aa7ed3cf6fbdc51944e33",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": "mix.exs",
      "sha256": "1837f4133a7f89b8ea1b8de04ec2a194bbdc764ece211b587f383cca80fdf9b0"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "dc1def34352f26ec42e0e1cfbe4089de068d3b64879a2e8af1820bfd4d965f48"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "9809b0e20c881e34703c2c5fd337f3ef67deedc8aab91eba1b0a86fd6d3e2664"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "e9702593930ddd264bc5f7e4aa639de1c7ed28919128aa92a95d61333e3625e3"
    }
  ],
  "proof_set_id": "phase73-97ec1aec53d80f53",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 108335,
    "exit_code": 0,
    "output_sha256": "305b9e41a93a69856d53354719e550632451b5a037eb6b82a44375c1512d6d9a",
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
  "source_digest": "sha256:d8da0a9bc3b8a12d2ded7968eb1399bff18dc1bf2f5d41e681e934705466685d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-97ec1aec53d80f53` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-97ec1aec53d80f53` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-97ec1aec53d80f53` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-97ec1aec53d80f53` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-97ec1aec53d80f53` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-97ec1aec53d80f53` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-97ec1aec53d80f53` |
T-73-104_CLOSED
50 threats: 49 closed and 1 open


## Plan 73-34 current proof staging — 2026-09-25

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-25T16:34:17Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 38671,
      "exit_code": 0,
      "output_sha256": "5a06dab95041c2fe7eda37f56b413514f9b462b422c4d962bd644ca756765102",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 34650,
      "exit_code": 0,
      "output_sha256": "3e4f13bbb38393710884e41989f1f7b3e648806b4f0cc61e7e8e47d754beff88",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 38339,
      "exit_code": 0,
      "output_sha256": "c513e66833547e54691c43abaf00a620b61ce2743f76dd4e2656f8c878019b86",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4293,
      "exit_code": 0,
      "output_sha256": "6ac920a2e457e1f82ee6d634c556dd0c30bd609f0d9f9082c5aed284fcd26d6b",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2619,
      "exit_code": 0,
      "output_sha256": "3c4340722b8e30050196878781786efcbfb2e5318318dbb8b547bb91215e09ec",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 4132,
      "exit_code": 0,
      "output_sha256": "04931b397dac3b235da2c12b4fdd14b283807f8e3fc8a57352910ff04fca085f",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9625,
      "exit_code": 0,
      "output_sha256": "ed22d84cd28e1dc0cb4483fde7fe1626c5299a27a303869c1e0caeb8bfc353dc",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 7827,
      "exit_code": 0,
      "output_sha256": "8405c8c520ab04ec5d7b4c3c8e76396dbbfbeead5021ef4604c4f49e7336b517",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1682,
      "exit_code": 0,
      "output_sha256": "e00198a5654c1a0ee7ce14da0db142a34a39ad1424065f71d435bd39d30538c4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1643,
      "exit_code": 0,
      "output_sha256": "942caca0ad10c2d09718334e6ba5fb17ee6f665bb7816df696c2e56ee247d166",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1853,
      "exit_code": 0,
      "output_sha256": "70318eb823e377ba6ad6b69264021f3bd023d83cfa5210e3d9c61f62c3bff5b7",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1957,
      "exit_code": 0,
      "output_sha256": "508ec4e95c204d49945f9d1f114749e041f4ff13529b735f6311a43bc0c33060",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 6195,
      "exit_code": 0,
      "output_sha256": "0ec480793be01eae25e934b99889130070c347e42aafcf6bb7414a0607f45e44",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7882,
      "exit_code": 0,
      "output_sha256": "7514d00a0528448c9ced093ed3f079b568589082156ea14e0ed815ccb717e1ee",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 2915,
      "exit_code": 0,
      "output_sha256": "a0f5698c46ebff4dbeffe6e0c1f3ca715aba43e81e62dce93018c114a4c9cc09",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2416,
      "exit_code": 0,
      "output_sha256": "34c3de2d551a29955b11a396141141be93c0faf17fb19d57aa26b032f766b63a",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 5053,
      "exit_code": 0,
      "output_sha256": "8d4f085f4e0d4fbd90406506ec6c78008f5e078a3743a676a6ed879a1dbbba47",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 8514,
      "exit_code": 0,
      "output_sha256": "1310b200f41783a26e822fa4e50c6ab58cc6cd552010e1e223ebfca8052ab59c",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 4403,
      "exit_code": 0,
      "output_sha256": "a7509a5fb9879c0699b8d6074214fa25af91fe0443920ef1fce8ef9becdffeb7",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4538,
      "exit_code": 0,
      "output_sha256": "9e88a045973bae5c16b9795af1a4da45025657f716bda8d7012f45abd9192669",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 4079,
      "exit_code": 0,
      "output_sha256": "61801e189ab3097157c13497b97da5b5357a7032eec393eb95f70ec763607452",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4151,
      "exit_code": 0,
      "output_sha256": "853719c46097a901c8116fb40d936251683bda34c4dc9e32dc25df3e14d73420",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4283,
      "exit_code": 0,
      "output_sha256": "fad943c445db882e81dcf3e294c72e95c25c57b4e34843f5a480f457f34aad2a",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1749,
      "exit_code": 0,
      "output_sha256": "b5e9e2b61214ebf2f4c93b5c811f9fb7b2db075c2ca2baa056ac3d6134b7c8a8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "38ea25697d97c7f57442ddc992ce964c372228cfb8eb3286c24b4db82d6d62b3"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "ce595740cf8391aeb0c4b2331e847b3cf336ca75026148dc2777dc6ea189a8c4"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-617a876eb05a67c6",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 110713,
    "exit_code": 0,
    "output_sha256": "b2f20f46ad73a63c770975fa18a4f000488fa3638654e1ec1b84e88855a272aa",
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
  "source_digest": "sha256:f4f8af09339a52469d2c2f86ede436aee261cb419d4677f06e58856908681c2d",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->


## Plan 73-34 final source-bound reconciliation — 2026-09-25

PHASE73_FINAL_RECONCILIATION
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-617a876eb05a67c6` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-617a876eb05a67c6` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-617a876eb05a67c6` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-617a876eb05a67c6` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-617a876eb05a67c6` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-617a876eb05a67c6` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-617a876eb05a67c6` |
T-73-104_CLOSED
50 threats: 49 closed and 1 open


## Plan 73-34 current-source reconciliation — 2026-09-26

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-26T01:50:50Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 25773,
      "exit_code": 0,
      "output_sha256": "d5dda485896d7860a91f7897a1dd2febb41a020cd06cd861e8e13b7723096294",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 27066,
      "exit_code": 0,
      "output_sha256": "6c8df25efdfcc92e2906984a95a01c134d72e7475b7e10fa6588d08b6b8698b8",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 23892,
      "exit_code": 0,
      "output_sha256": "e22ec7fa124f62ffbdc2a6f003848b1b2733f552ee8459b29336cb718ccd2605",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 128
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 2744,
      "exit_code": 0,
      "output_sha256": "ac9ced213f7fae2cfbacc7e4212d102eb6a548dd70ef7a19164dd19413f45c20",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 1824,
      "exit_code": 0,
      "output_sha256": "b270714ab92b527b572dea95a41b6da9e2b4c29b876e6a47a805f92321206697",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 2948,
      "exit_code": 0,
      "output_sha256": "d32b88d30a49aece2c0f3bdbb6acd8d221d994b817c3e39b2d8060b16b0ead96",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 4813,
      "exit_code": 0,
      "output_sha256": "40130e7538a7df970f4df5e481353442f87d9db6d1b8d562d13d81c01d7ff731",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 5039,
      "exit_code": 0,
      "output_sha256": "b818f0cda88b9aa3c7f4f53bae0a9230bdc55c3ef90e425a4e1def3de460cf03",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1233,
      "exit_code": 0,
      "output_sha256": "cedaf9dfaa61265539943c506d4d65e2fc13fe8082af7b548d8a0b41cba1678b",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1086,
      "exit_code": 0,
      "output_sha256": "8e9443e8cfe7515fe6404db4d92da3352fa8b39c3e28686ca64399b32d4c4324",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1308,
      "exit_code": 0,
      "output_sha256": "f622ac8d3366ae709aafa24cc42cab40a3c859119eff301f5fac18e1d2348bf7",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1312,
      "exit_code": 0,
      "output_sha256": "bf307e6fdfaee82e45aefb048bb9e8dabce2bc9a566f2e24c6d7ebcee9e64a62",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 4235,
      "exit_code": 0,
      "output_sha256": "4038fc0bb6f78f2d8459ddea2b01237ddb612d965686bce410833bf32bb203f2",
      "summaries": [
        {
          "excluded": 70,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 4901,
      "exit_code": 0,
      "output_sha256": "6313d38cab820191adaaf13e629b62a01bb6a4ab6f280ca19000f1a4b879bbd5",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1279,
      "exit_code": 0,
      "output_sha256": "16f165c434f0f82333bdaa9099efacc18df48c5736e64025ecd509965607ceb6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1407,
      "exit_code": 0,
      "output_sha256": "2a904e62e99864b7d043cd922a14dbe4efb12a6537874a930471ebfce4fade79",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 2892,
      "exit_code": 0,
      "output_sha256": "fa1a2826dd4d965e362a3e6365ebdd7548e204e5c4f52d24a4e8d7f5fd5e5c17",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 5237,
      "exit_code": 0,
      "output_sha256": "783922da7350d47789fb868f1f9c98f76ef5662427002ed9c78dac47744bc789",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 4733,
      "exit_code": 0,
      "output_sha256": "0ddb0f15ec1669c770c31d1efc94ef5d8b47faafcfe36224c0a69c839c77df9c",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 2895,
      "exit_code": 0,
      "output_sha256": "13033f478927f2ca4f73a0e57b01c4e7e4f0abe23e4ef90574d5123e082ca7bd",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 2831,
      "exit_code": 0,
      "output_sha256": "5af38ed3fea44ecbfbf4ff4accfb9dfad878f1c748a8f2eb9bde436b285c8fd5",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 2937,
      "exit_code": 0,
      "output_sha256": "f6d8fda846f23fea042344382fd6cfaa5fd82dce4cc2b9126a06e2b51fe58b0a",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3064,
      "exit_code": 0,
      "output_sha256": "f128e2b4bb1591cb1bf3f1bcc1cd6a583f05620e4da9ed3e5c0161656b34604c",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1281,
      "exit_code": 0,
      "output_sha256": "20c806d29019023af199ebf28ba904eed60188c635c8dba30a35f80d5d8209d4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "38ea25697d97c7f57442ddc992ce964c372228cfb8eb3286c24b4db82d6d62b3"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "57c6f54b96ae7d3e8275ae2a423b67d16bfb43bf6ddfd11a1e1f8c18229d2b13"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "8d938b262aea20643fbd5f182c5fda5125034cae305435648548c51b54723855"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-a262324179815839",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 103972,
    "exit_code": 0,
    "output_sha256": "083c020c42297fb8223fa9b4918b82b8fd29f62a0426b6fc7e5a2fca52a31ea1",
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
  "source_digest": "sha256:553eb055dc08af8f2213e08b3870a3b0edace0a95aa8568850e484691d7b9f69",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-a262324179815839` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-a262324179815839` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-a262324179815839` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-a262324179815839` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-a262324179815839` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-a262324179815839` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-a262324179815839` |
T-73-104_CLOSED
50 threats: 49 closed and 1 open


## Current-source refresh — 2026-09-26

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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-26T13:50:15Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 40393,
      "exit_code": 0,
      "output_sha256": "75b203c8123749abd96fc1b49910948a243a872024257573f0b6c6468ca22667",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 129
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 34173,
      "exit_code": 0,
      "output_sha256": "1abd7c67f09bb27d083e4efa2807ee3179f26dae55fd9d6270e6c212a4be08c3",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 129
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 37214,
      "exit_code": 0,
      "output_sha256": "da5e73355daad8c4da5dee18492567c392e14bdc71eec2a824ffe5c01900b652",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 129
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 4488,
      "exit_code": 0,
      "output_sha256": "fac7edeb0e53a27494bdc7eee012a88dcd0a695aa289e8255fcc324a83793805",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 3373,
      "exit_code": 0,
      "output_sha256": "b2f4464dbae7e421bd03469e5045aea906d70cb5d0de7fb4db32feb9cc10744a",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 5469,
      "exit_code": 0,
      "output_sha256": "bb7f93e55a00f09ee8115d5b31b7d1e179cbf1f66e652e396eea48aac9a1a034",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 9711,
      "exit_code": 0,
      "output_sha256": "609e827bd04e9d7d037623d61bc0a657e592d21e9f4cb1d3d8882de7f6b8582c",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 8566,
      "exit_code": 0,
      "output_sha256": "5dded42f3e0801b3162eb7435b1ee02f026211f0d5dc5db798b887f7fc9a7a26",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 2088,
      "exit_code": 0,
      "output_sha256": "1838ca0fdbd5fc0ecee960687af58462db932d7e35a2c5c16710ba1c2c5f72c8",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1901,
      "exit_code": 0,
      "output_sha256": "05a0757701a674e1590c32a136970142a0cd5857decd2845cacb44941631841f",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 2226,
      "exit_code": 0,
      "output_sha256": "e1ccd3685951c0346aa165cf352791554f2182a8ec0e3defb90e22f38c39aece",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 2294,
      "exit_code": 0,
      "output_sha256": "2fe92c75d737f724d8ef8d59deaa7e79d717f239e11c4a3b1fb9d6f338a2490e",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 7382,
      "exit_code": 0,
      "output_sha256": "910352519159e2d7a71f074bb2e41b89416ba917bd3cf13f007ccd88102a7a8d",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 7030,
      "exit_code": 0,
      "output_sha256": "8b89cf28fcd816bac34984ff2209746c80441d32484fc081bb46aa85991627ac",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 2135,
      "exit_code": 0,
      "output_sha256": "d0fca9b2fb891dc31990f634fb03d674aa495266d7ac6774b0b8184fe1d624ec",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 2044,
      "exit_code": 0,
      "output_sha256": "a533dcc7e17b51a3fd386166712fa8b0c4d1dee845be311753439d356c835ce4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3559,
      "exit_code": 0,
      "output_sha256": "6276e9ec61a74a3c687797f9da9847a21df7f3d623c8fd61e4e21a5256bf4a01",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 7988,
      "exit_code": 0,
      "output_sha256": "d4ff67d9a127fe1a40b48f3fb08f712b7803780cc6d672305bf192b89df00af1",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 5981,
      "exit_code": 0,
      "output_sha256": "d987aadd38135505759314713a8387ba80f3da5d53bdf40e74057753c72b1202",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 4034,
      "exit_code": 0,
      "output_sha256": "4292935239a582bce846be76d86d92a64efccd1cf949706a8433f088721da5d8",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3945,
      "exit_code": 0,
      "output_sha256": "2bba8cee8dd6fe2a97cc47264e03a75325703b2374e1c6dfc62a1d80941915d0",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 4272,
      "exit_code": 0,
      "output_sha256": "32b49188e6f7acc97b7f084d7047d3cc53ec50fd89ece024ae2676204662c35e",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 4252,
      "exit_code": 0,
      "output_sha256": "aeb6c06772823225a2163f9474585730d39ff028e939365d040cbf64e411beac",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 2056,
      "exit_code": 0,
      "output_sha256": "b160dd5c6b0835bc512267f36ed2cf557d060a30cdee3cd556ede58f2836be49",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "38ea25697d97c7f57442ddc992ce964c372228cfb8eb3286c24b4db82d6d62b3"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "7587a7a3dbb041d5777e611c75015d45c6dddce6dbde429fb7dbfbbe12608cf6"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "9ca79825ec77335284be61d9a4a12027114ddc6ce4b64100c0d937171cd791ee"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "28a2d37b8b824a9d38863a40cc3c0805f2e7801008464eba0344b0966f8f8eea"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-a3162f0b909873a3",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 104233,
    "exit_code": 0,
    "output_sha256": "d9bab50870b0dd686d3c04b8a9ecbca1ceba232bb8d44a90f4bd27a93fbf51fa",
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
  "source_digest": "sha256:bdda7021aec660dbf1a6ba1e0ec1aedadee10af022659d2eac653abc4694b2c5",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->

PHASE73_FINAL_RECONCILIATION
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-a3162f0b909873a3` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-a3162f0b909873a3` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-a3162f0b909873a3` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-a3162f0b909873a3` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-a3162f0b909873a3` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-a3162f0b909873a3` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-a3162f0b909873a3` |
T-73-104_CLOSED
50 threats: 49 closed and 1 open

Phase 76 current-source replay refreshed the exact evidence-owner manifest after the EVID-03 deterministic owner and Phase 77 planning handoff.

PHASE73_STAGED_PROOF
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
    "73-26-02",
    "73-27-01",
    "73-27-02",
    "73-28-01",
    "73-28-02",
    "73-29-01",
    "73-29-02",
    "73-30-01",
    "73-30-02",
    "73-31-01",
    "73-31-02",
    "73-32-01",
    "73-32-02",
    "73-33-01",
    "73-33-02",
    "73-34-01",
    "73-34-02"
  ],
  "captured_at": "2026-09-26T15:26:44Z",
  "evidence_runs": [
    {
      "command": "mix ci.evidence",
      "duration_ms": 29879,
      "exit_code": 0,
      "output_sha256": "9808333b99a37aeb09929cdd68d0ecd20e450146f8cca1efa0e0374826631115",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 134
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 26907,
      "exit_code": 0,
      "output_sha256": "6078e9ce42354ee776a8d9b6feaa1efd5f6e2e7a450d91f801eeab7c17cb4a10",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 134
        }
      ]
    },
    {
      "command": "mix ci.evidence",
      "duration_ms": 31445,
      "exit_code": 0,
      "output_sha256": "3e61a2af3809ccbbcca5b42031c78d3375b8e7d6af5f543ade527b8738cd4339",
      "summaries": [
        {
          "excluded": 0,
          "failures": 0,
          "tests": 134
        }
      ]
    }
  ],
  "focused": [
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
      "duration_ms": 3331,
      "exit_code": 0,
      "output_sha256": "fd8d93dd88f0a776c3d3d38af21a1aa7688e28ee58af0c2544c6517504ac4ecb",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
      "duration_ms": 2216,
      "exit_code": 0,
      "output_sha256": "6a6ab1f19787e7803faef6e1d3bfb6b28f19462c9bf62c670ee24497f277cedf",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
      "duration_ms": 3227,
      "exit_code": 0,
      "output_sha256": "235456bb6c6ab792f4e89bdc8e44ee1e19696d9984de27322e85be00f161f3bb",
      "summaries": [
        {
          "excluded": 52,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
      "duration_ms": 8179,
      "exit_code": 0,
      "output_sha256": "45e63efdd39611ee68bf601d4c091956b3b4cc66a24fd5d20f41030204ce5ac4",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
      "duration_ms": 7148,
      "exit_code": 0,
      "output_sha256": "5a1d5d2d376d0f6c81a7de9bf855703c26f8315c8a0150dd64aec1bfcc66dee3",
      "summaries": [
        {
          "excluded": 72,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
      "duration_ms": 1469,
      "exit_code": 0,
      "output_sha256": "191a1c0f28c56db0c35a7ae68d98954d103b383092d070cf299921582f301dd6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
      "duration_ms": 1307,
      "exit_code": 0,
      "output_sha256": "ea288be40dbfe0d95a6c18abea3a37ee3536c84f7f51d63f0bf7241edc6badd6",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
      "duration_ms": 1449,
      "exit_code": 0,
      "output_sha256": "4ccef9e9bfba00efd7c0bc643cca758a34f5732977d38002fb6cc593060541e5",
      "summaries": [
        {
          "excluded": 54,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
      "duration_ms": 1553,
      "exit_code": 0,
      "output_sha256": "35839e2b3f0896e0a47302071b884c8c47604fe60ca507822978b23486e9a12a",
      "summaries": [
        {
          "excluded": 53,
          "failures": 0,
          "tests": 2
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
      "duration_ms": 5654,
      "exit_code": 0,
      "output_sha256": "0e8fa576aed9c40d55301c02d9fc56773c1843bb675dc0c22a1a416e8a3d4375",
      "summaries": [
        {
          "excluded": 71,
          "failures": 0,
          "tests": 3
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
      "duration_ms": 5433,
      "exit_code": 0,
      "output_sha256": "8236e356b3eafc30c3d9a46ef98aada50fc5535e8568ee52fd479a3201a52666",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
      "duration_ms": 1256,
      "exit_code": 0,
      "output_sha256": "1f0f287cc43e88775d39837714f5e5fa171e3e78facee887ac7197d84706c1b4",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
      "duration_ms": 1235,
      "exit_code": 0,
      "output_sha256": "84a34489b2a6fb71199298703d880147d70f3a91900876ed1c17452064ec087c",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
      "duration_ms": 3360,
      "exit_code": 0,
      "output_sha256": "a9fcb5111359ec57cada4aac332f14f5e2b5fa6e4daca1bc0d5de6f50815dea3",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
      "duration_ms": 6883,
      "exit_code": 0,
      "output_sha256": "a4b28418b8005192b50e5326a5dfe1a863abf7841d2364dfed05409afe259c07",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
      "duration_ms": 3351,
      "exit_code": 0,
      "output_sha256": "864f0f4f1b6ef120eb4ccf88cd0b55e595fb068ab35ac9f76ef7fdd1ab4a7822",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
      "duration_ms": 3229,
      "exit_code": 0,
      "output_sha256": "02eb7d617b5cef21f517cef814b30bde954dc61ef87787cb547437acfcbffa0b",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
      "duration_ms": 3246,
      "exit_code": 0,
      "output_sha256": "8247fd4b88224a772c3657912acd37151d50cb9e55ad2d51acb80c4e84b363ee",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
      "duration_ms": 3409,
      "exit_code": 0,
      "output_sha256": "bacc6d2c3031bd0d68b8d9f6aab8ff6386724b2277ec3ae94721809cd52ad33f",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
      "duration_ms": 3286,
      "exit_code": 0,
      "output_sha256": "e8b4b2d3cfa2b5b8873785a845f3717ec08010ce2888d5e2928d232798ec119b",
      "summaries": [
        {
          "excluded": 73,
          "failures": 0,
          "tests": 1
        }
      ]
    },
    {
      "command": "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors",
      "duration_ms": 1288,
      "exit_code": 0,
      "output_sha256": "56cf8e85e311ce32bd0ca44b1de45d40eaf02f09bb4a1c702b464fcf8dd1efa2",
      "summaries": [
        {
          "excluded": 5,
          "failures": 0,
          "tests": 1
        }
      ]
    }
  ],
  "governed_sources": [
    {
      "path": ".github/workflows/security-gates.yml",
      "sha256": "66e47d987c8c7bf511e29846d4df579432187b9e6c015243dfe0ffddafea4294"
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
      "path": ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
      "sha256": "70ad68b62a5947d43d9af9fd4e676aca32c3d41ffb332a57f86565076a860fb1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
      "sha256": "d92597b15545919bf57ce26209469fe3b970430655dffd9191b898003fc6fa4f"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
      "sha256": "2f9fc5e0f34b0bff529cb6d5ab8a250666b66b904d5fd509ea873a71fb1bb151"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
      "sha256": "4b9f9618dca71c6f02007fcf30a62f017bd1c0209a173622f2b366496c7ac0bc"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
      "sha256": "4888e59ec3fd117f724332c6261686d630450c09b6922ae9808b2eeea8750376"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
      "sha256": "425d31d711ad18ea12e5c03e46caeeeb2df656b753ead497b22835b21c0a0b18"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
      "sha256": "35c8f9b2cace2c58b147f7a87078023c2c3ffcdfdbd8308d60f6d9dc45b5a1f1"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
      "sha256": "3c6eb4f77952254c81733920605dbc2a96ad60b83e046b7aac04ef0330c164c7"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
      "sha256": "d124b19266e1466dc5e6265f21016b54431d3011a13061b819336d1eaa860ef8"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
      "sha256": "da428853a772eb022c69e02aea1c7e19c8d3c59d99513b3fa7a90da989898ab6"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
      "sha256": "071adc74350810aed0a63ac006a28358cd00048894be17de429c2e36bbb496c9"
    },
    {
      "path": ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
      "sha256": "721f879104e2b5e66ceec2b19b48df46da74515f3ba7c47af8d78d94716d6d42"
    },
    {
      "path": "mix.exs",
      "sha256": "7ae782c9d18e1896bd6caafca5f20d2d8ab0ba790c26ea1516a6e2c1f6c86c04"
    },
    {
      "path": "test/adoption/evidence_contract_test.exs",
      "sha256": "47effba90918219fb6b2943c066523d39ff99213d7da97d5a6b5ab22d48ea4e4"
    },
    {
      "path": "test/governance/milestone_scope_test.exs",
      "sha256": "f1f0bcdc008c3bfc58946b5507464aef0993ea87e53448699ef588fef62080ef"
    },
    {
      "path": "test/governance/phase_73_reconciliation_test.exs",
      "sha256": "a0b5567aafb2ef54c1c1ddd744cec3846e2ebfbb73501e011a6da5e12339fbbe"
    },
    {
      "path": "test/support/adoption_evidence.ex",
      "sha256": "e666f75e8c2e9a3f3dcb6b54875844ec91f288ba9d368afce1459c2339ab1b9d"
    },
    {
      "path": "test/support/phase_73_reconciliation.ex",
      "sha256": "52a5945850ec98d512db13bc0d66f8ef72c912bc7436220b58e5b6e92171975a"
    }
  ],
  "proof_set_id": "phase73-a47d8b7a24e35bcf",
  "schema": "phase73-reconciliation-proof",
  "security": {
    "command": "mix ci.security",
    "duration_ms": 138348,
    "exit_code": 0,
    "output_sha256": "8e6998e33417758163155a31dc5490025612327c2d9c40e191464e4440a0c092",
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
  "source_digest": "sha256:5e58f96124d2637cbd0de48e75bc699d873f8e06bad111ed1e542eb6da1ceac6",
  "version": 1
}
```
<!-- phase73-reconciliation-proof:end -->
PHASE73_FINAL_RECONCILIATION
| T-73-98 | CR-01 | high | closed | Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2; proof `phase73-a47d8b7a24e35bcf` |
T-73-98_CLOSED
| T-73-99 | CR-02 | high | closed | Plan 73-27; plan_73_27_task_1; proof `phase73-a47d8b7a24e35bcf` |
T-73-99_CLOSED
| T-73-100 | CR-03 | high | closed | Plan 73-28; plan_73_28_task_1; proof `phase73-a47d8b7a24e35bcf` |
T-73-100_CLOSED
| T-73-101 | CR-04 | high | closed | Plan 73-27; plan_73_27_task_2; proof `phase73-a47d8b7a24e35bcf` |
T-73-101_CLOSED
| T-73-102 | CR-05 | high | closed | Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1; proof `phase73-a47d8b7a24e35bcf` |
T-73-102_CLOSED
| T-73-103 | CR-06 | high | closed | Plan 73-29; plan_73_29_task_1; proof `phase73-a47d8b7a24e35bcf` |
T-73-103_CLOSED
| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-a47d8b7a24e35bcf` |
T-73-104_CLOSED
50 threats: 49 closed and 1 open
