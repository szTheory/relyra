---
phase: 72-documentation
verified: 2026-08-27T18:15:00Z
status: gaps_found
score: 19/20 must-haves verified
behavior_unverified: 0
overrides_applied: 0
next_action: "Gaps found. Plan the fixes, then re-run execute-phase before shipping."
next_command: "/gsd:plan-phase 72 --gaps"
re_verification:
  previous_status: gaps_found
  previous_score: 9/13
  gaps_closed:
    - "The detailed evaluator README now describes FakeIdP's Sarah subject and persisted LedgerLoop LoginReceipt truthfully."
    - "Fleet and optional Keycloak now use the executable, fail-closed public make keycloak launcher."
  gaps_remaining: []
  regressions:
    - "PORT override recovery is inaccurate: doctor probes hard-coded 4000 and the guide retains fixed localhost:4000 URLs."
gaps:
  - truth: "The guide provides accurate, executable port-conflict recovery for the configured Solo listener."
    status: failed
    reason: "Compose honors PORT, but doctor always checks and classifies port 4000; the guide tells a reader to use PORT=<free-port> then continues to prescribe localhost:4000."
    artifacts:
      - path: "Makefile"
        issue: "doctor calls check_port 4000 at line 215 and only recognizes 4000 as the demo port at lines 194-196, ignoring the exported PORT value."
      - path: "guides/docker_dev_dx.md"
        issue: "Lines 44-45 advertise a port override while lines 55, 62, and 96 hard-code localhost:4000 instead of routing the reader through make url for the configured PORT."
      - path: "test/docs/demo_guide_drift_test.exs"
        issue: "No fixture exercises PORT=4101 make doctor or verifies that the recovery path emits and uses the overridden loopback URL."
    missing:
      - "Make doctor probe the configured PORT and classify the demo listener by role, not literal port 4000."
      - "Add a deterministic launcher fixture for PORT override recovery."
      - "Tell overridden-port users to run make url with the same PORT and use its emitted loopback URL."
---

# Phase 72: Documentation Verification Report

**Phase Goal:** A new reader can go zero→login using only the guide, and existing demo/README routing points at the new Make targets and Fleet path in house voice.
**Verified:** 2026-08-27T18:15:00Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The canonical guide accurately covers Solo/Fleet, caching, URL map, recovery, Keycloak hostname, and house voice. | ✗ FAILED | Port-conflict recovery is inaccurate under the documented `PORT` override; this composite DOC-01 contract cannot be met. |
| 2 | Demo README, published router, and root README route readers to Make-first Docker/Fleet evaluation while retaining Local Mix and Day-1. | ✓ VERIFIED | README, `guides/demo.md`, and root README links/ordering pass the focused router contract. |
| 3 | A reader following the guide can complete Solo/FakeIdP and reproduce the Sarah receipt. | ✓ VERIFIED | Focused guide contracts and the real FakeIdP flow test pass; the flow persists Sarah's `LoginReceipt`. |
| 4 | Fleet and optional Keycloak come after the Solo receipt and remain follow-ons. | ✓ VERIFIED | Guide lines 72-125 and README optional-profile section preserve the ordering. |
| 5 | Documented Solo/Fleet/Keycloak/Traefik origins match the public launcher. | ✓ VERIFIED | `make keycloak` uses base + proxy Compose files, `--profile keycloak`, provisioner wait, loopback-resolved descriptor validation, then `make url`; fixture contracts pass. |
| 6 | The guide explains bind mounts, Linux-only named volumes, lock-hash dependency resolution, and BuildKit caches. | ✓ VERIFIED | Guide lines 127-145 state all four mechanisms and match the existing Docker path. |
| 7 | Recovery is graduated and gives a correct supported response to port conflicts, reset/reseed, and nuke. | ✗ FAILED | The destructive labels and ordering are correct, but the first recovery branch fails for a non-default configured port. |
| 8 | Proof language keeps assertion verification separate from mapping, session receipt, and authorization ownership. | ✓ VERIFIED | Guide lines 65-70 and README ownership table assign mapping, LoginReceipt, and authorization to LedgerLoop. |
| 9 | The guide uses gameplan, persona/JTBD, receipt evidence, and Canonical Lock Set voice. | ✓ VERIFIED | `adopter_voice_test.exs` passes with the guide's gameplan and receipt structure. |
| 10 | `demo/ledger_loop/README.md` is an accurate Make-first evaluator entry point retaining Local Mix. | ✓ VERIFIED | It documents `sarah@northstar.example.com`, seeded Sarah mapping, LoginReceipt, Local Mix, and `make keycloak`. |
| 11 | `guides/demo.md` is a concise, HexDocs-safe router to the repository guide and demo README. | ✓ VERIFIED | Both required absolute GitHub links are present and link smoke tests pass. |
| 12 | Root README adds Docker/Fleet and Day-2 routes without displacing library Day-1. | ✓ VERIFIED | Docker evaluation follows the complete Start Here sequence. |
| 13 | Local Mix stays supported and Fleet/Keycloak are explicitly Solo follow-ons. | ✓ VERIFIED | README contains the full Local Mix path and makes both Docker routes follow-ons. |
| 14 | The bounded gap-closure exception changed only the public launcher and its deterministic coverage, not Compose/provisioning/app/API/security/package surfaces. | ✓ VERIFIED | Phase commits show Plan 03 changed only `Makefile` and its test; Plan 04 only docs/test. |
| 15 | `make keycloak` starts proxy + profile, waits for provisioning, validates the public descriptor, and only then prints routes. | ✓ VERIFIED | `Makefile:135-152`; the real recipe is exercised by the fixture test at lines 123-162. |
| 16 | `make keycloak` fails closed for prerequisite and descriptor failures. | ✓ VERIFIED | Fixture test at lines 164-202 proves nonzero provisioning/descriptor failures and no route banner. |
| 17 | Launcher evidence uses owned fixtures and environment-derived host handling without ambient Docker. | ✓ VERIFIED | `run_make/2` fixtures execute the actual Make recipe; focused suite passed 28 tests. |
| 18 | The evaluator README uses FakeIdP's actual Sarah NameID and real receipt outcome, with no stale unresolved narrative. | ✓ VERIFIED | Cross-artifact contract reads controller/flow test; focused real flow test at `fake_idp_flow_test.exs:63` passed. |
| 19 | Both detailed docs route optional Keycloak through `make keycloak`, not proxy + Solo Compose. | ✓ VERIFIED | Focused docs contract passes and both sections describe profile, provisioning, and public descriptor validation. |
| 20 | Docs preserve Solo as the complete first journey and the host-owned receipt boundary after gap closure. | ✓ VERIFIED | Solo ordering, exact receipt sentence, and ownership language are asserted and present. |

**Score:** 19/20 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `guides/docker_dev_dx.md` | Complete Make-first Docker guide | ⚠️ HOLLOW | Exists (186 lines), substantive, linked and statically tested; its port-override data flow diverges from the launcher. |
| `demo/ledger_loop/README.md` | Detailed Make-first evaluator route with Local Mix | ✓ VERIFIED | Substantive, linked to guide, and bound to real Sarah/receipt evidence. |
| `guides/demo.md` | Published-doc-safe router | ✓ VERIFIED | Substantive, absolute source links verified. |
| `README.md` | Day-2 Docker/Fleet route preserving Day-1 | ✓ VERIFIED | Substantive and ordered after Start Here. |
| `Makefile` | Public `keycloak` launcher and recovery semantics | ⚠️ PARTIAL | Keycloak target is substantive, wired, and fixture-proven; `doctor` is not wired to the exported `PORT`. |
| `test/docs/demo_guide_drift_test.exs` | Deterministic cross-artifact documentation contracts | ⚠️ PARTIAL | Exists (852 lines), substantive, wired, and passes, but ordered-text matching is brittle and PORT recovery lacks a fixture. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `guides/docker_dev_dx.md` | `Makefile` | public targets, URLs, doctor/recovery semantics | PARTIAL | Commands exist, but guide `PORT` recovery and `doctor` do not carry the configured port end-to-end. |
| `Makefile` | `docker-compose.proxy.yml` | `KEYCLOAK_COMPOSE` plus `--profile keycloak` | WIRED | Lines 12-13 and 135-139 compose the base/proxy graph and profile. The automated pattern probe misses the multi-line variable expansion, not the actual wiring. |
| `Makefile` | `keycloak_provisioner` | wait before public readiness claim | WIRED | Line 139 waits before descriptor loop and URL banner. |
| `Makefile` | public Keycloak descriptor | `curl --noproxy` + `--resolve` + exact entityID | WIRED | Lines 141-152 implement bounded validation; success/failure fixtures pass. |
| Demo README | FakeIdP controller and flow test | Sarah subject and LoginReceipt outcome | WIRED | Test reads all three files and the real focused flow test passes. |
| Routers | canonical Docker guide | relative/absolute Markdown routes | WIRED | Static router and link suites pass. |

### Data-Flow Trace (Level 4)

| Artifact | Data / claim | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Solo guide proof | FakeIdP → Sarah → `LoginReceipt` | Controller + database-backed flow test | Yes | ✓ FLOWING |
| Keycloak guide proof | `make keycloak` → proxy/profile/provisioner/descriptor | Make recipe + owned fixtures | Yes | ✓ FLOWING |
| Port-conflict recovery | `PORT` → Compose mapping → doctor → guide URL | `docker-compose.override.yml` honors `${PORT:-4000}`; `doctor` probes literal 4000 | No | ✗ DISCONNECTED |
| Documentation ordering contracts | ordered prose tokens | `assert_in_order/2` | Incomplete for repeated tokens | ⚠️ BRITTLE |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Documentation, voice, and Markdown contracts | `mix test test/docs/demo_guide_drift_test.exs test/docs/adopter_voice_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` | 28 tests, 0 failures | ✓ PASS |
| Actual FakeIdP Sarah receipt path | `(cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs:63 --warnings-as-errors)` | 1 test, 0 failures | ✓ PASS |
| Formatting | `mix format --check-formatted` | exit 0 | ✓ PASS |
| Configured port diagnosis | `make -n doctor PORT=4101` | rendered recipe contains `check_port 4000` and no `check_port "$${PORT}"` | ✗ FAIL |

### Probe Execution

Step 7c: SKIPPED — no Phase 72 probe is declared and no `scripts/**/tests/probe-*.sh` probe exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DOC-01 | `72-01`, `72-03`, `72-04` | Accurate house-voice Solo/Fleet guide with cache, URLs, troubleshooting, receipts, and runnable Keycloak follow-on | ✗ BLOCKED | Keycloak, Solo receipt, cache, ownership, and most recovery work pass, but the required port-conflict troubleshooting is false for `PORT` overrides. |
| DOC-02 | `72-02`, `72-04` | Accurate Make/Fleet routing across demo README, published router, and root README with Local Mix retained | ✓ SATISFIED | Router, Local Mix, Sarah narrative, ownership, and executable Keycloak routing are present and covered by focused tests. |

All declared Phase 72 IDs (`DOC-01`, `DOC-02`) are accounted for. No orphaned Phase 72 requirement was found. Phase 72 is the last milestone phase, so no later phase clearly defers this gap.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `Makefile` | 194-196, 215 | hard-coded demo port in configurable launcher | 🛑 BLOCKER | The documented `PORT=<free-port>` recovery cannot be diagnosed accurately. |
| `guides/docker_dev_dx.md` | 44-45, 55, 62, 96, 151-152 | override advice followed by fixed default URLs | 🛑 BLOCKER | A reader following the guide after a port conflict can be sent to an unrelated service. |
| `test/docs/demo_guide_drift_test.exs` | 838-850 | matcher restarts each lookup at byte zero | ⚠️ WARNING | Valid future documentation with a repeated token can falsely fail its ordering contract. |

No `TBD`, `FIXME`, or `XXX` debt markers were found in Phase 72 artifacts.

### Prohibition Checks

| Prohibition | Status | Evidence |
| --- | --- | --- |
| Do not claim Relyra owns browser session or authorization. | ✓ VERIFIED | Guide and README explicitly assign mapping, LoginReceipt persistence, and authorization to LedgerLoop. |
| Do not present reset/reseed/nuke as ordinary non-destructive restarts. | ✓ VERIFIED | Guide and README label reset/reseed destructive and nuke confirmed deletion. |
| Do not present demo/guide as Hex runtime or replace Day-1. | ✓ VERIFIED | `guides/demo.md` and root README preserve source-only and Day-1 boundaries. |
| Do not make Keycloak a Solo prerequisite or hide failed Keycloak prerequisites. | ✓ VERIFIED | Guide labels it optional; fixture tests prove fail-closed no-banner paths. |

### Gaps Summary

The previous blockers are genuinely closed: the new Keycloak launcher is executable and fail-closed, and the Sarah/receipt narrative now agrees with real flow behavior. However, DOC-01 explicitly includes port-conflict troubleshooting. The runner supports `PORT` overrides, while the diagnostic and documentation remain hard-coded to `4000`; therefore a reader cannot reliably recover from the very port conflict the guide claims to solve. This is a blocking, actionable documentation/launcher gap. The ordering-helper finding is a warning to fix with the same targeted closure so the deterministic docs gate remains reliable.

---

_Verified: 2026-08-27T18:15:00Z_
_Verifier: the agent (gsd-verifier)_
