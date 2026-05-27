---
phase: 38-single-logout-slo-core-security
verified: 2026-05-27T16:43:30Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 38: Single Logout (SLO) Core & Security Verification Report

**Phase Goal:** Users and Identity Providers can securely terminate sessions across the federation via verified SAML Single Logout flows.
**Verified:** 2026-05-27T16:43:30Z
**Status:** passed
**Re-verification:** No — retroactive closure-phase verification per Phase 40.1 D-07/D-10

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | `Relyra.SessionAdapter` defines `index_session/4` and `terminate_by_session_index/4` callbacks at the canonical signature `(session_index, issuer, context, opts)`. | ✓ VERIFIED | `grep -nE '^  @callback (index_session\|terminate_by_session_index)' lib/relyra/session_adapter.ex` returns matches at lines 19 and 26. Top-level dispatch helpers with telemetry live at `lib/relyra/session_adapter.ex:96-126` and `:128-158` (38-01-SUMMARY decision row). |
| 2  | HTTP-Redirect signatures are verified against raw query octets via `Signature.verify_redirect_signature/4` — never re-serialized inside the function. | ✓ VERIFIED | `grep -n 'verify_redirect_signature' lib/relyra/security/signature.ex` returns the `@spec` at line 144 and the active head at line 146. `mix test test/relyra/security/signature_test.exs --warnings-as-errors` exits 0 (signature_test.exs PRESENT — see `test -f test/relyra/security/signature_test.exs` exits 0). 38-VALIDATION Truth #2. |
| 3  | `Relyra.Security.LogoutValidator` enforces the strict ordered pipeline: `Parse → Verify → Replay → Execute` for POST and `Verify → Inflate → Parse → Replay → Execute` for Redirect. | ✓ VERIFIED | `test -f lib/relyra/security/logout_validator.ex` exits 0; module created in Plan 03. `mix test test/relyra/security/logout_validator_test.exs --warnings-as-errors` exits 0. 38-03-SUMMARY items #1-#3 enumerate the two ordered pipelines and confirm tampered/replay/unsigned coverage. |
| 4  | Replay protection is enforced on all consumed logout messages — replayed Redirect requests and Redirect responses are both rejected as `:replayed_assertion` after the first successful consumption. | ✓ VERIFIED | `mix test test/protocol/logout_pipeline_test.exs:79 test/protocol/logout_pipeline_test.exs:121 --warnings-as-errors` exits 0. The redirect-request replay test lives at `test/protocol/logout_pipeline_test.exs:79-97`; the redirect-response replay test at `:121-138`. Both `assert {:error, %Error{type: :replayed_assertion}}`. 38-VALIDATION Truth #4. |
| 5  | The facade `Relyra.consume_logout/3` invokes `SessionAdapter.terminate_by_session_index/4` on a valid IdP-initiated logout request, threading `session_index` + `issuer` + `context` verbatim. | ✓ VERIFIED | `grep -n 'handle_idp_initiated_logout\|terminate_by_session_index' lib/relyra.ex` returns the auto-wire call site at line 353 inside the `defp handle_idp_initiated_logout/3` at line 343. `mix test test/protocol/logout_pipeline_test.exs:37 --warnings-as-errors` exits 0; the success test at `:37-58` asserts `{:terminate_session, "session_abc123", @issuer, %{connection_id: "conn_123"}}`. Audit v1.4-MILESTONE-AUDIT.md WIRED row 2. |
| 6  | A tampered Redirect signature is rejected with typed `:invalid_signature` BEFORE any session mutation — order is proven, not assumed. | ✓ VERIFIED | `mix test test/protocol/logout_pipeline_test.exs:60 --warnings-as-errors` exits 0; the test at `:60-77` asserts `{:error, %Error{type: :invalid_signature}}` AND `refute_receive {:terminate_session, _, _, _}` — the absence of the message proves the adapter was not called. Audit v1.4-MILESTONE-AUDIT.md PASS row 2. |
| 7  | A POST-binding unsigned LogoutRequest is rejected immediately as `:missing_signature` — there is no fall-through to processing. | ✓ VERIFIED | `mix test test/protocol/logout_pipeline_test.exs:140 --warnings-as-errors` exits 0; the test at `:140-152` asserts `{:error, %Error{type: :missing_signature}}` against an unsigned `<samlp:LogoutRequest>`. Audit v1.4-MILESTONE-AUDIT.md PASS row 5. |
| 8  | SP-initiated `LogoutResponse` round-trip succeeds end-to-end: `consume_logout/3` returns `{:ok, %{type: :response, message: res}}` with the verified `id` and `status` populated. | ✓ VERIFIED | `mix test test/protocol/logout_pipeline_test.exs:100 --warnings-as-errors` exits 0; the test at `:100-119` asserts both `res.id == id` and `res.status == "urn:oasis:names:tc:SAML:2.0:status:Success"`. Audit v1.4-MILESTONE-AUDIT.md PASS row 4. |
| 9  | `Relyra.Protocol.LogoutRequest` and `LogoutResponse` are built directly on the `SaxyTree` root node — the single hardened parse path (CLAUDE.md non-negotiable #2) is preserved. | ✓ VERIFIED | `grep -n 'SaxyTree\|parse_tree\|from_parsed_doc' lib/relyra/protocol/logout_request.ex` returns the alias at line 5 (`alias Relyra.Security.XML.SaxyTree.Node`) and `from_parsed_doc/1` at line 78 routing through `parsed_doc.parse_tree`. 38-02-SUMMARY decision row: "Implemented `LogoutRequest` and `LogoutResponse` directly against the `SaxyTree` root node to ensure no separate parsing path is used." |
| 10 | Telemetry events `[:logout, :start]` and `[:logout, :consume]` are emitted around the core flows via `Relyra.Telemetry.span/3`. | ✓ VERIFIED | `grep -n 'Relyra.Telemetry.span.*:logout' lib/relyra.ex` returns two matches: `:start` wrapper at line 199, `:consume` wrapper at line 278. 38-04-SUMMARY accomplishment #2. |
| 11 | The full end-to-end logout-pipeline suite passes deterministically with `--warnings-as-errors`. | ✓ VERIFIED | `mix test test/protocol/logout_pipeline_test.exs --warnings-as-errors` reports `6 tests, 0 failures` and exits 0. `grep -c '    test ' test/protocol/logout_pipeline_test.exs` = 6 (one per flow: success, tampered, redirect-request replay, redirect-response success, redirect-response replay, POST unsigned). |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/relyra/session_adapter.ex` | Defines `index_session/4` + `terminate_by_session_index/4` callbacks and top-level dispatch helpers with telemetry | ✓ VERIFIED | 163 lines; callbacks at 19-31; dispatch helpers at 96-126 and 128-158. `test -f` exits 0. |
| `lib/relyra/security/signature.ex` | Exposes `verify_redirect_signature/4` for raw-query-octet signature verification | ✓ VERIFIED | `verify_redirect_signature/4` at lines 144-155. Active head at 146; `:invalid_signature` fail-closed head at 155. `test -f` exits 0. |
| `lib/relyra/security/logout_validator.ex` | Strict-ordered pipeline module (POST and Redirect) | ✓ VERIFIED | `test -f` exits 0. Created in Plan 03 (38-03-SUMMARY item #1). |
| `lib/relyra.ex` | Exposes public `start_logout/3` and `consume_logout/3`; auto-wires `terminate_by_session_index/4` on IdP-initiated logout | ✓ VERIFIED | `start_logout/3` at line 190; `consume_logout/3` at line 273; `handle_idp_initiated_logout/3` at lines 343-361 with the `terminate_by_session_index` call at line 353. `test -f` exits 0. |
| `lib/relyra/protocol/logout_request.ex` | `LogoutRequest` model built on `SaxyTree` root | ✓ VERIFIED | `test -f` exits 0. 78-line `from_parsed_doc/1` routes through `parsed_doc.parse_tree`. |
| `lib/relyra/protocol/logout_response.ex` | `LogoutResponse` model built on `SaxyTree` root | ✓ VERIFIED | `test -f` exits 0. Created in Plan 02. |
| `test/protocol/logout_pipeline_test.exs` | End-to-end logout flows: IdP-initiated success/tampered/replay; SP-initiated success/replay; POST unsigned rejection | ✓ VERIFIED | `test -f` exits 0. 175 lines; 6 tests. `mix test test/protocol/logout_pipeline_test.exs --warnings-as-errors` reports `6 tests, 0 failures`. |
| `.planning/phases/38-single-logout-slo-core-security/38-01-SUMMARY.md` | Plan 01 evidence (SessionAdapter callbacks + `verify_redirect_signature/4`) | ✓ VERIFIED | `test -f` exits 0. 47 lines; decisions row enumerates the two extensions. |
| `.planning/phases/38-single-logout-slo-core-security/38-02-SUMMARY.md` | Plan 02 evidence (LogoutRequest/LogoutResponse models on SaxyTree root) | ✓ VERIFIED | `test -f` exits 0. 42 lines; decisions row confirms `SaxyTree` root usage. |
| `.planning/phases/38-single-logout-slo-core-security/38-03-SUMMARY.md` | Plan 03 evidence (`LogoutValidator` strict pipeline) | ✓ VERIFIED | `test -f` exits 0. Enumerates POST and Redirect ordered pipelines. |
| `.planning/phases/38-single-logout-slo-core-security/38-04-SUMMARY.md` | Plan 04 evidence (facade integration, telemetry, E2E test creation) | ✓ VERIFIED | `test -f` exits 0. Item #2 confirms `[:logout, :start]` / `[:logout, :consume]` wiring; item #3 confirms E2E test landed. Cosmetic API-name drift on line 4 (`consume_logout_response/3` → `consume_logout/3`) addressed in Phase 40.1 Plan 04 per D-11. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `Relyra.consume_logout/3` (`lib/relyra.ex:273`) | `LogoutValidator` (`lib/relyra/security/logout_validator.ex`) | Validator handles both POST and Redirect bindings; on success returns the message and the typed `:request` / `:response` discriminator | ✓ WIRED | Audit v1.4-MILESTONE-AUDIT.md row 2: `lib/relyra.ex:272-358` → `lib/relyra/security/logout_validator.ex:14-22`. |
| `Relyra.consume_logout/3` (`lib/relyra.ex:273`) | `SessionAdapter.terminate_by_session_index/4` (`lib/relyra/session_adapter.ex:128`) | After validator success, `handle_idp_initiated_logout/3` (lib/relyra.ex:343-361) auto-invokes the dispatcher; call site at `lib/relyra.ex:353` | ✓ WIRED | `grep -n 'terminate_by_session_index' lib/relyra.ex` returns the call site at line 353; success path proven by `logout_pipeline_test.exs:37-58` (`assert_receive {:terminate_session, ...}`). |
| `LogoutValidator.validate_redirect` | `Signature.verify_redirect_signature/4` | Validator hands the raw query octets directly to the verifier; configured-cert pubkey only (CLAUDE.md non-negotiable #1) | ✓ WIRED | Audit v1.4-MILESTONE-AUDIT.md row 3: `logout_validator.ex:66-79,144` → `signature.ex:144-153`. Tampered-signature rejection proven at `logout_pipeline_test.exs:60-77`. |
| `LogoutValidator.validate_post` | `Signature.verify/4` | Strict envelope; replay BEFORE mutation (CLAUDE.md non-negotiable #6) | ✓ WIRED | Audit v1.4-MILESTONE-AUDIT.md row 4: `logout_validator.ex:40-50`. Replay rejection proven at `logout_pipeline_test.exs:79-97` and `:121-138`. |
| `Relyra.start_logout/3` (`lib/relyra.ex:190`) | `LogoutRequest.build` / `to_xml` | Facade emits the canonical Request via the `Relyra.Protocol.LogoutRequest` model | ✓ WIRED | Audit v1.4-MILESTONE-AUDIT.md row 1: `lib/relyra.ex:189-218`. Telemetry `[:logout, :start]` wraps the call at line 199. |
| `Relyra.start_logout/3` + `consume_logout/3` | `Relyra.Telemetry.span([:logout, :start], ...)` + `Relyra.Telemetry.span([:logout, :consume], ...)` | Spans wrap the core flows; metadata includes the session/connection context | ✓ WIRED | Audit v1.4-MILESTONE-AUDIT.md row 5: `lib/relyra.ex:199, 278`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `lib/relyra.ex:343-361` (`handle_idp_initiated_logout/3`) | `session_index` (binary) | `Map.get(message, :session_index)` at line 344 — populated by `LogoutRequest.from_parsed_doc/1` reading `<samlp:SessionIndex>` from the verified parse tree | Yes — verified by `logout_pipeline_test.exs:50-57` asserting `req.session_index == "session_abc123"` AND the `{:terminate_session, "session_abc123", @issuer, %{connection_id: "conn_123"}}` adapter callback receipt | ✓ FLOWING |
| `lib/relyra.ex:343-361` | `issuer` (binary) | `Map.get(message, :issuer)` at line 345 — derived from `<saml:Issuer>` in the verified parse tree | Yes — proven by `logout_pipeline_test.exs:57` asserting the issuer match at the adapter call site | ✓ FLOWING |
| `lib/relyra/session_adapter.ex:96-126` (`index_session/4` dispatcher) | `session_index` (binary) | Host-owned linkage per Phase 40.1 D-01: hosts read `login_result.principal.session_index` from `Relyra.consume_response/3` and invoke `MyAdapter.index_session/4` themselves | N/A (host-invoked dispatcher; documented policy, NOT a gap — see Gaps Summary below) | ✓ FLOWING (host-invoked path) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `LogoutValidator` module file exists | `test -f lib/relyra/security/logout_validator.ex` | exit 0 | ✓ PASS |
| `index_session/4` callback declared at canonical arity | `grep -nE '@callback index_session\(' lib/relyra/session_adapter.ex` | one match at line 19 | ✓ PASS |
| `terminate_by_session_index/4` callback declared at canonical arity | `grep -nE '@callback terminate_by_session_index\(' lib/relyra/session_adapter.ex` | one match at line 26 | ✓ PASS |
| Full logout-pipeline E2E suite green (no warnings) | `mix test test/protocol/logout_pipeline_test.exs --warnings-as-errors` | `6 tests, 0 failures`; exit 0 | ✓ PASS |
| Telemetry `:logout` spans present | `grep -c 'Relyra.Telemetry.span(\[:logout' lib/relyra.ex` | 2 (lines 199 and 278) | ✓ PASS |
| `consume_logout/3` auto-wires the terminate dispatcher | `grep -n 'SessionAdapter.terminate_by_session_index' lib/relyra.ex` | one match at line 353 inside `handle_idp_initiated_logout/3` | ✓ PASS |

### Probe Execution

The phase's primary end-to-end gate is `mix test test/protocol/logout_pipeline_test.exs`. There is no dedicated `mix ci.logout` alias; the suite participates in the standard `mix test` lane. Phase 30's `mix ci.security` is byte-identical to the v1.1 baseline (no SLO test was added to the security alias).

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| Full logout pipeline E2E suite | `mix test test/protocol/logout_pipeline_test.exs --warnings-as-errors` | `6 tests, 0 failures`; exit 0 | ✓ PASS |
| LogoutValidator unit suite | `mix test test/relyra/security/logout_validator_test.exs --warnings-as-errors` | exits 0 (per 38-03-SUMMARY item #3 + retroactive re-run) | ✓ PASS |
| Redirect-signature verifier unit suite | `mix test test/relyra/security/signature_test.exs --warnings-as-errors` | exits 0 (per 38-01 plan and retroactive re-run) | ✓ PASS |
| Security adversarial corpus (CLAUDE.md non-negotiable) | `mix ci.security` | exit 0; byte-equivalent to base (Phase 30 hollow-gate invariant preserved) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SLO-01 | 38-01-PLAN, 38-02-PLAN, 38-03-PLAN, 38-04-PLAN | Single Logout (SP-initiated and IdP-initiated) | ✓ SATISFIED | All four SUMMARYs present (`38-01-SUMMARY.md`, `38-02-SUMMARY.md`, `38-03-SUMMARY.md`, `38-04-SUMMARY.md`); end-to-end behaviour proven by `test/protocol/logout_pipeline_test.exs` (6 tests covering IdP-initiated success/tampered/redirect-replay, SP-initiated success/redirect-replay, and POST unsigned rejection). Audit v1.4-MILESTONE-AUDIT.md lists 5/6 E2E flows as PASS; the 6th (host-owned login → index_session linkage) is the deliberate D-01 policy disposed of in the Gaps Summary below — NOT a gap. |

No orphaned requirements. REQUIREMENTS.md maps SLO-01 exclusively to Phase 38 plans 01-04.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/relyra/session_adapter.ex` | — | No TODO/FIXME/HACK/placeholder/stub | — | Clean. |
| `lib/relyra/security/signature.ex` | — | No TODO/FIXME/HACK/placeholder/stub introduced by Phase 38 | — | Clean (pre-existing module; `verify_redirect_signature/4` additive). |
| `lib/relyra/security/logout_validator.ex` | — | No TODO/FIXME/HACK/placeholder/stub | — | Clean. |
| `lib/relyra/protocol/logout_request.ex` | — | No TODO/FIXME/HACK/placeholder/stub | — | Clean. |
| `lib/relyra/protocol/logout_response.ex` | — | No TODO/FIXME/HACK/placeholder/stub | — | Clean. |
| `test/protocol/logout_pipeline_test.exs` | — | No TODO/FIXME/HACK/placeholder/stub | — | Clean. |

**No anti-patterns introduced by Phase 38.**

**Note on pre-existing `mix format` drift:** A pre-existing format drift in `test/security/xml/adversarial_crypto_test.exs` (lines 188-200 + the long `:public_key.sign` tuple) is byte-identical to base commit `c80742c` and documented in `.planning/phases/40-operational-polish-error-taxonomy/deferred-items.md`. NOT introduced by Phase 38. Out of scope per the SCOPE BOUNDARY rule; also called out in `40-VERIFICATION.md` § Anti-Patterns.

### Human Verification Required

None. Phase 38 deliverables are executable code + a deterministic E2E test suite. All verification steps above are programmatically checkable via the commands shown:

- File existence: verified via `test -f`.
- Callback shape and call-site presence: verified via `grep -n` against `lib/`.
- End-to-end behaviour, including order-of-operations (tampered before mutation), replay rejection, unsigned rejection, and adapter auto-wire: verified via `mix test test/protocol/logout_pipeline_test.exs --warnings-as-errors` exit 0.
- Telemetry span emission: verified via `grep -c` against `lib/relyra.ex`.

### Gaps Summary

**No goal-blocking gaps.** Every must-have for the phase goal — IdP-initiated logout terminates host sessions through the strict validator, SP-initiated logout round-trips and rejects replays, tampered signatures and unsigned POST payloads are rejected with typed errors, and the single hardened parse path is preserved — is verified in the codebase with direct evidence.

**WARNING 2 from `v1.4-MILESTONE-AUDIT.md` (`SessionAdapter.index_session/4` has no in-tree caller in `consume_response/3`)** is dispositioned as the deliberate **host-owned linkage** policy per Phase 40.1 Decision D-01, **NOT a gap**:

- `lib/relyra/session_adapter.ex:96-126` makes `index_session/4` a top-level dispatch helper with telemetry — designed for host invocation, identical to `establish_session/3` which is also explicitly host-invoked.
- Relyra dispatches the callback; the host invokes it from the ACS controller after `Relyra.consume_response/3` returns, reading from `login_result.principal.session_index` (populated by `normalize_consume_result/1` at `lib/relyra.ex:406-413`).
- This is the explicit policy resolution per the CLAUDE.md "Key Architecture Seams" rule: **behaviour seams are never bypassed**. Auto-wiring would commit Relyra to a session-storage policy at index time, violating the host-owned-sessions stance.
- The asymmetry with `consume_logout/3` auto-wiring `terminate_by_session_index/4` (`lib/relyra.ex:343-361`) is defensible: terminate operates entirely on inbound-message data (`session_index` + `issuer` arrive in the verified `LogoutRequest`); index needs the host's local session ID that Relyra does not have at the close of the SSO assertion.
- The policy is documented in `guides/recipes/logout.md` per Phase 40.1 Plan 05 (D-02/D-03/D-04), and a drift-prevention CI test (`test/docs/logout_recipe_drift_test.exs`) lands in Phase 40.1 Plans 03 + 05 to keep the documented example arity in lock-step with the canonical callbacks via `behaviour_info(:callbacks)` introspection.
- The decision is **reversible**: if a future audit demands auto-wiring, the recovery is a follow-up phase adding the call site post-`normalize_consume_result/1` without breaking the current contract.

**WARNING 3 from `v1.4-MILESTONE-AUDIT.md` (`38-04-SUMMARY.md:4` cosmetic API name drift, `consume_logout_response/3` → `consume_logout/3`)** is addressed by Phase 40.1 Plan 04 (D-11). Pre-existing at time of this verification, but tracked for closure in the same closure phase as this artifact.

---

_Verified: 2026-05-27T16:43:30Z_
_Verifier: Claude (gsd-verifier, retroactive closure-phase artifact per Phase 40.1)_
