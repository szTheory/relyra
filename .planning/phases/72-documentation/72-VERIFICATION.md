---
phase: 72-documentation
verified: 2026-08-27T17:15:07Z
status: gaps_found
score: 9/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The detailed LedgerLoop evaluator route accurately describes the deterministic FakeIdP success path and its reproducible receipt."
    status: failed
    reason: "The README says FakeIdP emits evaluator@example.com and cannot map a seeded identity, but the controller emits sarah@northstar.example.com and the exercised end-to-end test proves a LoginReceipt is inserted for Sarah."
    artifacts:
      - path: "demo/ledger_loop/README.md"
        issue: "Lines 82-103 state a false principal and a false unresolved outcome."
      - path: "test/docs/demo_guide_drift_test.exs"
        issue: "The static router test does not compare the prose to FakeIdP's emitted subject or receipt behavior."
    missing:
      - "Replace the evaluator@example.com narrative with the Sarah success path and receipt outcome."
      - "Add deterministic coverage tying the documented success path to the controller/flow contract."
  - truth: "Fleet and optional Keycloak are accurately documented as runnable follow-on proofs through the public Make-first workflow."
    status: failed
    reason: "The guide and README prescribe make proxy plus make up-build, but both recipes use the solo Compose command. The keycloak and keycloak_provisioner services require the keycloak profile and proxy overlay, and no public Make target starts them."
    artifacts:
      - path: "guides/docker_dev_dx.md"
        issue: "Lines 83-121 advertise the Keycloak origin without a command that can make it available."
      - path: "demo/ledger_loop/README.md"
        issue: "Lines 196-213 present the same incomplete Keycloak follow-on."
      - path: "Makefile"
        issue: "up-build invokes docker compose up --build; the only profile invocation is the test-only demo-test target, without the proxy overlay."
    missing:
      - "Expose and document a public Make-first Keycloak/Fleet command that uses docker-compose.proxy.yml and --profile keycloak, waits for provisioning, and then validates the public route."
      - "Add an executable launcher contract for that command; do not rely only on prose-token assertions."
---

# Phase 72: Documentation Verification Report

**Phase Goal:** A new reader can go zero→login using only the guide, and existing demo/README routing points at the new Make targets and Fleet path in house voice.
**Verified:** 2026-08-27T17:15:07Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The canonical guide fully and accurately documents Solo/Fleet, caching, URL map, recovery, Keycloak hostname, and house voice. | ✗ FAILED | The prose is substantive and uses the Canonical Lock Set voice, but its Keycloak follow-on has no runnable command; the advertised public origin is unreachable after its documented commands. |
| 2 | Demo README, published router, and root README route readers to Make-first Docker/Fleet evaluation while retaining Local Mix and Day-1. | ✗ FAILED | Links, targets, Local Mix, and Day-1 ordering exist, but the detailed README gives a false FakeIdP success principal and repeats the unrunnable Keycloak route. |
| 3 | A reader following only the new guide can complete Solo/FakeIdP and reproduce the receipt. | ✓ VERIFIED | Guide lines 32-70 provide prerequisites, `make doctor`, `make up-build`, `/login/test`, FakeIdP, trace, and receipt. The actual flow test passed and inserts a `LoginReceipt` for Sarah. |
| 4 | Fleet and optional Keycloak occur after the Solo receipt and are labelled follow-ons. | ✓ VERIFIED | `guides/docker_dev_dx.md:72-121` orders and labels them correctly; this does not cure the missing Keycloak launcher. |
| 5 | Guide Make targets and Solo/Fleet/Keycloak/Traefik origins accurately match the launcher. | ✗ FAILED | Solo commands and origins match. `make proxy` plus `make up-build` cannot activate the Fleet overlay or Keycloak profile. |
| 6 | The guide explains bind mounts, Linux-only named volumes, lock-hash dependency resolution, and BuildKit caches. | ✓ VERIFIED | Guide lines 123-141 match `docker-compose.yml` volumes and the documented cache contract. |
| 7 | Recovery is graduated and labels reset/reseed/nuke as destructive. | ✓ VERIFIED | Guide lines 143-181 match `Makefile:44-69`; reset/reseed and nuke are explicitly destructive. |
| 8 | Proof language preserves Relyra verification versus LedgerLoop mapping, session receipt, and authorization ownership. | ✓ VERIFIED | Guide lines 65-70 and `session_adapter.ex:24-36` agree; no Relyra-owned session/authorization claim found. |
| 9 | The guide uses the required gameplan, persona/JTBD framing, receipt evidence, and calm/exact/operator-friendly house voice. | ✓ VERIFIED | Guide lines 3-28 and 70 use the required structure and evidence language; `adopter_voice_test.exs` passed. |
| 10 | `demo/ledger_loop/README.md` is an accurate detailed Make-first evaluator entry point retaining Local Mix. | ✗ FAILED | Local Mix and Docker targets exist, but README lines 82-103 contradict the controller and successful flow regarding the emitted principal and receipt. |
| 11 | `guides/demo.md` remains concise and uses HexDocs-safe absolute links to the repository guide and demo README. | ✓ VERIFIED | Lines 12-24 contain both required absolute GitHub links and correctly mark them source-only. |
| 12 | Root README adds Docker/Fleet and Day-2 routes without displacing library Day-1. | ✓ VERIFIED | `README.md:37-61` keeps Getting Started before the separately headed Docker evaluator route. |
| 13 | Local Mix remains supported; Fleet and Keycloak are explicitly presented as Solo follow-ons. | ✓ VERIFIED | `demo/ledger_loop/README.md:56-72,196-213` retains Local Mix and labels follow-ons; Keycloak's runnable wiring is separately failed above. |

**Score:** 9/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `guides/docker_dev_dx.md` | Complete Make-first Docker guide | ⚠️ HOLLOW | Exists (181 lines), is substantive, and is statically tested, but the Keycloak command/data flow is disconnected from the profile required by Compose. |
| `demo/ledger_loop/README.md` | Detailed Make-first evaluator route with Local Mix | ⚠️ HOLLOW | Exists and links correctly, but its principal/outcome narrative contradicts executable demo behavior. |
| `guides/demo.md` | Published-doc-safe router | ✓ VERIFIED | Substantive source-only router with both absolute links. |
| `README.md` | Day-2 Docker/Fleet route preserving Day-1 | ✓ VERIFIED | Substantive and ordered after Getting Started. |
| `test/docs/demo_guide_drift_test.exs` | Deterministic documentation contract | ⚠️ PARTIAL | Exists (700 lines), substantive, wired, and passes; its assertions only inspect documentation literals and explicitly require no documented Keycloak profile command, so it cannot establish the advertised runtime behavior. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `guides/docker_dev_dx.md` | `Makefile` | Public Make commands and origins | PARTIAL | All documented normal targets exist, but `proxy` only starts Traefik and `up-build` is solo Compose. No command enables `--profile keycloak` with the proxy overlay. |
| `guides/docker_dev_dx.md` | `session_adapter.ex` | Ownership-safe receipt | WIRED | Guide wording agrees with `LoginReceipt` insertion and ownership fields. |
| `test/docs/demo_guide_drift_test.exs` | `guides/docker_dev_dx.md` | `File.read!/1` ordered assertions | WIRED | Static contract executes and passed; it is not a runtime topology proof. |
| `demo/ledger_loop/README.md` | `guides/docker_dev_dx.md` | Relative guide link | WIRED | Relative link resolves, but both documents repeat the unavailable Keycloak path. |
| `guides/demo.md` | Repository guide and demo README | Absolute GitHub links | WIRED | Both required links are present. |
| `README.md` | `guides/docker_dev_dx.md` | Evaluator/Day-2 routing | WIRED | Link is present outside the Day-1 sequence. |
| `test/docs/demo_guide_drift_test.exs` | All three routers | Static file reads | WIRED (static only) | Tests pass but do not validate controller identity or Compose profile activation. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable / Claim | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Docker guide Solo path | FakeIdP → `LoginReceipt` | `FakeIdPController.conn_fields/0`; `fake_idp_flow_test.exs` | Yes — emits Sarah and inserts receipt | ✓ FLOWING |
| Docker guide / demo README Keycloak path | Keycloak public origin after documented Make commands | `Makefile` → Compose services | No — solo `up-build` excludes the profile and overlay | ✗ DISCONNECTED |
| Detailed demo README success narrative | FakeIdP principal | `FakeIdPController.conn_fields/0` | No — docs say evaluator@example.com; code emits Sarah | ✗ HOLLOW |
| Drift test | Documentation contents | `File.read!/1` | Static literals only | ⚠️ STATIC |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Documentation static contracts | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | 19 tests, 0 failures | ✓ PASS — static only |
| Actual Solo FakeIdP receipt path | `(cd demo/ledger_loop && mix test test/ledger_loop_web/fake_idp_flow_test.exs:63 --warnings-as-errors)` | 1 test, 0 failures; assertion checks `LoginReceipt` for `sarah@northstar.example.com` | ✓ PASS |
| Brand and Markdown-link contracts | `mix test test/docs/adopter_voice_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` | 5 tests, 0 failures | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 72 declares no probe and `scripts/**/tests/probe-*.sh` yielded no project probes.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DOC-01 | `72-01-PLAN.md` | Accurate house-voice Solo/Fleet guide with cache, URLs, troubleshooting, and receipts | ✗ BLOCKED | Core Solo proof is correct, but the guide's documented Keycloak proof is not runnable through its stated Make workflow. |
| DOC-02 | `72-02-PLAN.md` | Accurate Make/Fleet routing across demo README, published router, and root README with Local Mix retained | ✗ BLOCKED | Router links and Local Mix are present, but the detailed demo README gives a false successful FakeIdP identity/outcome and routes to the unavailable Keycloak proof. |

All requirement IDs declared in Plan frontmatter (`DOC-01`, `DOC-02`) are accounted for. No Phase 72 requirement is orphaned. No later milestone phase specifically addresses either gap, so neither is deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `demo/ledger_loop/README.md` | 82-103 | Contradictory hard-coded FakeIdP success principal | 🛑 Blocker | Directly misleads the detailed evaluator path and receipt expectation. |
| `guides/docker_dev_dx.md` | 83-121 | Documented command sequence does not activate advertised Keycloak route | 🛑 Blocker | Follow-on proof cannot be completed from the guide. |
| `test/docs/demo_guide_drift_test.exs` | 550-552 | Static test enforces absence of a Keycloak profile command | 🛑 Blocker | Passing test preserves the missing wiring instead of detecting it. |

No `TBD`, `FIXME`, or `XXX` debt markers were found in Phase 72 artifacts.

### Prohibition Checks

| Prohibition | Status | Evidence |
| --- | --- | --- |
| Relyra must not be presented as owning browser session or downstream authorization. | ✓ VERIFIED | Guide lines 65-68 and README ownership table lines 225-240 expressly assign mapping, session establishment, and authorization to LedgerLoop. |
| Reset, reseed, and nuke must not be presented as ordinary non-destructive restart. | ✓ VERIFIED | Guide lines 157-168 and README lines 168-184 label refresh/nuke destructive. |
| Repository demo/guide must not be presented as Hex package surface or displace Day-1. | ✓ VERIFIED | `guides/demo.md:3-5,22-24` and `README.md:55-61` explicitly preserve source-only and Day-1 boundaries. |

### Gaps Summary

The phase’s static docs tests pass, but they do not prove the operational claims they freeze. Two material contradictions remain: the detailed evaluator README describes an identity the FakeIdP does not emit, and all documented Keycloak follow-ons omit the Compose profile/overlay necessary to start and provision Keycloak. These are implementation-and-documentation gaps, not deferred future work, so Phase 72 has not achieved its documentation goal.

---

_Verified: 2026-08-27T17:15:07Z_
_Verifier: the agent (gsd-verifier)_
