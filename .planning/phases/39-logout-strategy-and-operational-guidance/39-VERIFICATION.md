---
phase: 39-logout-strategy-and-operational-guidance
verified: 2026-05-27T16:43:40Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
---

# Phase 39: Logout Strategy & Operational Guidance Verification Report

**Phase Goal:** Operators understand when to deploy SLO and how to mitigate browser-level cookie constraints.
**Verified:** 2026-05-27T16:43:40Z
**Status:** passed
**Re-verification:** No — retroactive closure-phase verification per Phase 40.1 D-07/D-10

## Goal Achievement

### Observable Truths

| # | Truth                                                                                                                                                                                       | Status     | Evidence                                                                                                                                                                                                                                                  |
|---|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | ROADMAP SC1 (a): `guides/recipes/logout.md` is published as the operator-facing SLO reference.                                                                                              | ✓ VERIFIED | `test -f guides/recipes/logout.md` exits 0; `wc -l guides/recipes/logout.md` reports 154 lines (≈155 per Plan 40.1-02 expectation). Title at line 1: "Logout Strategy And Operational Guidance".                                                          |
| 2 | ROADMAP SC1 (b): Guide covers ITP, Firefox ETP, and Chrome Privacy Sandbox by name (the exact vocabulary operators need to push back on rigid compliance checklists per Phase 39 D-02).     | ✓ VERIFIED | `grep -c -E 'ITP\|ETP\|Privacy Sandbox' guides/recipes/logout.md` returns 5 (≥3 distinct matches required by 39-VALIDATION quick-run). All three terms appear in section 1 (Compliance Trap) at lines 56-62 with vendor-specific bullets.                  |
| 3 | ROADMAP SC2: Guide provides an absolute-timeout fallback strategy as the true security boundary when front-channel SLO silently fails.                                                      | ✓ VERIFIED | `grep -F 'Absolute Timeout' guides/recipes/logout.md` returns 1 match at line 141; section 4 ("The Real Security Boundary") at lines 133-154 documents the dual-layer pattern: SLO is the optimization, local timeouts are the guarantee (line 153-154). |
| 4 | 39-CONTEXT D-03/D-04: Guide mandates stateful/durable server-side sessions as a strict prerequisite for SLO (stateless Plug cookies explicitly disqualified).                              | ✓ VERIFIED | `grep -F 'stateful' guides/recipes/logout.md` returns ≥1 match (3 matches at lines 5, 37, 84); section 2 ("Mandatory Stateful Sessions") at lines 74-89 mandates PostgreSQL/Ecto/Redis and rejects stateless encrypted Plug cookies for SLO use.          |
| 5 | 39-CONTEXT D-02/D-05: Guide names the "Compliance Trap" framing (auditor expectations vs. architectural reality of IdP-iframe + cross-origin cookie blocking).                              | ✓ VERIFIED | `grep -F 'Compliance Trap' guides/recipes/logout.md` returns 1 match (the H2 header at line 43); section 1 at lines 43-72 documents the IdP-iframe / hidden-redirect model and exactly why it fails in modern browsers (ITP / ETP / Privacy Sandbox).     |
| 6 | 39-CONTEXT D-07 + 39-01-SUMMARY pattern: Guide explicitly discourages the IdP-polling anti-pattern (SAML has no standard `/userinfo` endpoint).                                            | ✓ VERIFIED | `grep -F 'IdP polling' guides/recipes/logout.md` returns 1 match at line 147 inside section 4: "Do not attempt to build 'IdP polling' (where your SP periodically pings the IdP)…" — matches 39-01-SUMMARY decision "discouraging IdP polling".            |
| 7 | mix.exs wiring: Guide is registered in ExDoc `extras:` AND gated by a `ci.docs` `cmd test -f` presence guard (audit's CI Gate Coverage row 1; v1.4-MILESTONE-AUDIT.md:127).                | ✓ VERIFIED | `grep -n 'guides/recipes/logout.md' mix.exs` returns line 133 (extras list) AND line 157 (`cmd test -f guides/recipes/logout.md` in the `ci.docs` alias). Both wiring points present and active in the current build.                                     |
| 8 | SessionAdapter mapping is documented (section 3 "Session Index Mapping") and references the `Relyra.SessionAdapter` behaviour by full module name. **Note on code-example arity drift** — see Gaps Summary. | ✓ VERIFIED | `grep -F 'Relyra.SessionAdapter' guides/recipes/logout.md` returns ≥1 match (4 matches at lines 32, 93, 101, 102); section 3 at lines 91-127 describes `index_session/4` and `terminate_by_session_index/4` as the linkage seam. **The code-example argument-shape fidelity to `lib/relyra/session_adapter.ex:19-31` is the BLOCKER 1 audit finding; resolution is routed to Phase 40.1 Plan 05.** |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact                       | Expected                                                                                            | Status     | Details                                                                                                                                            |
|--------------------------------|-----------------------------------------------------------------------------------------------------|------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `guides/recipes/logout.md`     | Operator SLO guide with sections 1-4 (Compliance Trap, Stateful Sessions, Session Index Mapping, Real Security Boundary) + SessionAdapter mapping example + Relyra owns / Host owns ownership split. | ✓ VERIFIED | 154 lines. Title at line 1; Relyra-owns/Host-owns ownership split at lines 24-41; four numbered H2 sections at lines 43, 74, 91, 133 (Compliance Trap → Stateful Sessions → Session Index Mapping → Real Security Boundary). |
| `mix.exs`                      | ExDoc `extras:` registration + `ci.docs` `cmd test -f` presence guard (the Phase 39 DOCS-04 CI gate).        | ✓ VERIFIED | Extras entry at line 133 (`"guides/recipes/logout.md"`); ci.docs presence guard at line 157 (`"cmd test -f guides/recipes/logout.md"`). Both lines verified in mix.exs as shipped to the v1.4 milestone.                       |

### Key Link Verification

| From                                | To                                | Via                                                                       | Status   | Details                                                                                                                          |
|-------------------------------------|-----------------------------------|---------------------------------------------------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------|
| `mix.exs` `extras:`                 | `guides/recipes/logout.md`        | Append in `docs/0` extras list                                            | ✓ WIRED  | mix.exs:133. ExDoc renders the guide on hex publish; appears in HexDocs sidebar alongside the other recipes.                     |
| `mix.exs` `ci.docs`                 | `guides/recipes/logout.md`        | `cmd test -f` presence guard                                              | ✓ WIRED  | mix.exs:157. `ci.docs` fails closed if the file is ever removed/renamed without an accompanying mix.exs update.                  |
| `guides/recipes/logout.md`          | `Relyra.SessionAdapter`           | Direct behaviour-module name reference in the guide prose + code example  | ✓ WIRED  | Line 93 ("implement the `Relyra.SessionAdapter` behaviour"); line 32 (Relyra-owns bullet citing the seam); lines 101-102 (`@behaviour Relyra.SessionAdapter`). |

### Data-Flow Trace (Level 4)

| Artifact                        | Data Variable | Source              | Produces Real Data | Status     |
|---------------------------------|---------------|---------------------|--------------------|------------|
| `guides/recipes/logout.md`      | n/a           | Static markdown     | n/a (doc artifact) | ✓ FLOWING  |

n/a — Phase 39 is a documentation-only phase. No runtime data flow is introduced by this phase (mirroring the doc-only treatment in `21.2-VERIFICATION.md`).

### Behavioral Spot-Checks

| Behavior                                                                                       | Command                                                                              | Result                                                                | Status |
|------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|-----------------------------------------------------------------------|--------|
| Logout guide file exists                                                                       | `test -f guides/recipes/logout.md`                                                   | exit 0                                                                | ✓ PASS |
| Required browser-vocabulary terms present (39-VALIDATION.md quick-run command)                 | `grep -c -E 'ITP\|ETP\|Privacy Sandbox' guides/recipes/logout.md`                    | 5 matches (≥3 required)                                               | ✓ PASS |
| mix.exs presence-guard line exists (the DOCS-04 ci.docs gate)                                 | `grep -nF 'cmd test -f guides/recipes/logout.md' mix.exs`                            | 1 match at line 157                                                   | ✓ PASS |
| mix.exs extras-list registration exists                                                        | `grep -nF '"guides/recipes/logout.md"' mix.exs`                                      | 1 match at line 133                                                   | ✓ PASS |
| `mix ci.docs` end-to-end (the DOCS-04 acceptance gate; presence guard at mix.exs:157 must pass)| `mix ci.docs`                                                                        | exit 0; all presence guards pass (logout.md guard at line 157 passes) | ✓ PASS |

### Probe Execution

| Probe                                                                       | Command         | Result | Status |
|-----------------------------------------------------------------------------|-----------------|--------|--------|
| `mix ci.docs` (the DOCS-04 end-to-end gate; runs the `cmd test -f` chain plus the docs drift test) | `mix ci.docs`   | exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description                                                                                                                                                          | Status      | Evidence                                                                                                                                                                                       |
|-------------|------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| DOCS-04     | 39-01-PLAN  | Publish `guides/recipes/logout.md` detailing when to enable SLO, session-model implications, 3rd-party cookie caveats, and absolute-timeout fallbacks.               | ✓ SATISFIED | `39-01-SUMMARY.md` records both tasks complete (commits `ae8dac5` docs + `180f141` chore). Guide exists at `guides/recipes/logout.md` (154 lines, 4 H2 sections). `mix.exs` wires it into both `extras:` (line 133) and `ci.docs` presence guard (line 157). Code-example arity drift (BLOCKER 1) tracked in Gaps Summary; resolution routed to Phase 40.1 Plan 05. |

No orphaned requirements. REQUIREMENTS.md maps exactly DOCS-04 to Phase 39, and 39-01-PLAN.md is the sole plan claiming it.

### Anti-Patterns Found

| File                         | Line | Pattern                              | Severity | Impact                                                                |
|------------------------------|------|--------------------------------------|----------|-----------------------------------------------------------------------|
| `guides/recipes/logout.md`   | —    | No TODO/FIXME/HACK/placeholder/stub  | —        | Clean. Production documentation; no debt markers.                     |
| `mix.exs`                    | —    | Append-only extras + ci.docs edits   | —        | No debt markers. Phase 30 hollow-gate invariant for `ci.security` untouched by Phase 39. |

**No anti-patterns introduced by Phase 39.** The code-example arity drift in section 3 (BLOCKER 1 from v1.4-MILESTONE-AUDIT.md) is a *correctness defect in the example's argument shape*, not an introduced anti-pattern; it is fully tracked in the Gaps Summary below and routed for closure in Phase 40.1 Plan 05 (rewrite) + Plan 03 (drift-prevention test).

### Human Verification Required

The single manual-only verification declared by `39-VALIDATION.md` ("Guide prose matches operational reality" — assertive demotion of front-channel SLO + mandate of absolute timeouts and stateful sessions) was satisfied during Phase 39's original execution and is recorded in `39-01-SUMMARY.md` Accomplishments + Decisions Made. No new human verification gate is added by this retroactive verification.

| Behavior                                            | Requirement | Why Manual                                                            | Original Verification                                                                 | Status      |
|-----------------------------------------------------|-------------|-----------------------------------------------------------------------|---------------------------------------------------------------------------------------|-------------|
| Guide prose matches operational reality (assertive tone) | DOCS-04     | Automated checks verify keywords, not assertive demotion of SLO.       | 39-01-SUMMARY decisions: "Positioned front-channel SLO as structurally unreliable…", "Mandated durable/stateful sessions…", "Established absolute session timeouts as the true security boundary…" | ✓ SATISFIED |

### Gaps Summary

**One audit-surfaced gap, fully tracked and routed to closure:**

The `Relyra.SessionAdapter` code example at `guides/recipes/logout.md:107,121` initially shipped with incorrect 4-arg signatures (`index_session(connection, login_result, local_session_id, opts)` and `terminate_by_session_index(connection, session_index, _name_id, opts)`) instead of the actual callback signatures defined in `lib/relyra/session_adapter.ex:19-31` (`index_session(session_index, issuer, context, opts)` and `terminate_by_session_index(session_index, issuer, context, opts)`). A host copy-pasting the example as-shipped would fail `@behaviour Relyra.SessionAdapter` checks at compile time — the headline operator guide for the milestone's headline feature carries a defect that blocks integration.

**This is resolved in Phase 40.1 Plan 05** (per 40.1-CONTEXT D-02 / D-03 / D-04): the code block at lines 100-127 is rewritten to match the real callback signatures in `lib/relyra/session_adapter.ex:19-31`, with a new host-linkage operator paragraph inserted between sections 3 and 4 (D-03) explicitly documenting that hosts must call `MyAdapter.index_session/4` from their ACS controller after `Relyra.consume_response/3` returns, reading `session_index` from `login_result.principal.session_index`. Sections 1, 2, and 4 are byte-untouched per D-04 because they were verified satisfied in this report.

**Drift prevention:** Phase 40.1 Plan 03 adds `test/docs/logout_recipe_drift_test.exs` wired into `ci.docs` as its own `cmd mix test` line per D-05 / D-06 (matching the Phase 30 hollow-gate invariant and the Phase 40 troubleshooting-drift precedent at `mix.exs:160`). The test uses runtime introspection — `Relyra.SessionAdapter.behaviour_info(:callbacks)` — never hardcoded arity literals, so the gate stays accurate as `SessionAdapter` evolves. This drift class cannot regress silently after Plan 03 lands.

The Phase 40.1 Plan 05 verify step is where end-to-end re-verification of the fix lands; **this VERIFICATION.md certifies the Phase 39 deliverables as originally executed**, with the post-execution audit gap explicitly tracked here and routed to the closure plans (Plan 05 for the rewrite, Plan 03 for the drift gate).

No other gaps. Every must-have for the phase goal — operators have the vocabulary to push back on rigid compliance checklists (ITP/ETP/Privacy Sandbox, the Compliance Trap framing), the mandate for stateful sessions when enabling SLO, the SessionAdapter linkage seam to durable storage, and the absolute-timeout dual-layer pattern as the true security boundary — is verified in the published guide with direct grep / file-existence evidence. The DOCS-04 `mix ci.docs` gate (presence guard at `mix.exs:157`) exits 0 end-to-end.

---

_Verified: 2026-05-27T16:43:40Z_
_Verifier: Claude (gsd-verifier, retroactive closure-phase artifact per Phase 40.1)_
