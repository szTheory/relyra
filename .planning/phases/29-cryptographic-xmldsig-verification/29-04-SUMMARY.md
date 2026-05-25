---
phase: 29-cryptographic-xmldsig-verification
plan: 04
subsystem: testing
tags: [xmldsig, crypto, public_key, positive-control, test-signer, FakeIdP, C14N, SIGV-01, SIGV-02]

requires:
  - phase: 29-03
    provides: "Real :public_key.verify of canonicalized SignedInfo + constant-time DigestValue recompute in the [candidate] arm; public_key_from_cert_chain/1; :digest_mismatch / :unsupported_signature_algorithm error atoms; genuine in-test signer (genuine_signed_doc/0) — the canonical shape promoted here"
  - phase: 29-01
    provides: "Mixed-content C14N document-order fix (byte-exact canonical bytes) — precondition for the signer/verifier byte-alignment"
provides:
  - "Relyra.TestSupport.XmldsigSigner (D-11): reusable genuine XMLDSig signer reusing FakeIdP's RSA-2048 keypair + the verifier's own C14N engine; signed_response/1 + sign_response/1 + self_signed_cert_pem/0; prod-guarded; Phase-30 promotion target (D-12)"
  - "POSITIVE control proven: a genuinely-signed Response verifies {:ok, %SignedNode{}} through PureBeam.parse_safely → Signature.verify/4 (the verifier is NOT an always-reject stub)"
  - "Wrong-key negative (:invalid_signature) + tampered-NameID negative (:digest_mismatch) via the genuine signer"
  - "All 10 structure-only {:ok}-asserting end-to-end tests triaged to genuine signatures; full mix test --warnings-as-errors green (524/0) — phase gate met"
affects: [29-05 (metadata-root SIGV-04), 30 (assurance / FakeIdP real signing — promotes XmldsigSigner)]

tech-stack:
  added: []
  patterns:
    - "Anti-divergent-signer (D-12): the signer parses its OWN emitted XML and canonicalizes the bound Assertion/SignedInfo nodes with the verifier's PureBeam.canonicalize / C14N.serialize, so signer and verifier can never canonicalize differently"
    - "Keypair reuse (D-11): the signer reuses FakeIdP.keypair() (zero :public_key.generate_key in the module); the trusted cert is derived from that same key via :public_key.pkix_test_root_cert/2 (no openssl, no committed key material)"
    - "In-place re-sign (sign_response/1): inject a genuine DigestValue + SignatureValue into an EXISTING structure-only Response, preserving its exact element shape so the downstream validation stage sees the same fields it asserts on"
    - "Triage-by-re-pointing: structure-only {:ok} fixtures are made genuine (disposition a) rather than weakened to assert a rejection — coverage preserved, no verifier change"

key-files:
  created:
    - "lib/relyra/test_support/xmldsig_signer.ex (Relyra.TestSupport.XmldsigSigner — the D-11 reusable signer)"
  modified:
    - "test/relyra/security/signature_crypto_test.exs (positive control + wrong-key + tampered-NameID through the full verify path)"
    - "test/protocol/consume_response_pipeline_test.exs (response_xml/1 + manifest payloads genuinely signed; genuine cert)"
    - "test/conformance/sp_conformance_test.exs (consume-path fixtures genuinely signed; genuine cert)"
    - "test/phoenix/acs_controller_test.exs (ACS success uses a genuinely-signed payload + genuine-cert resolver)"
    - "test/relyra/telemetry_test.exs (success response_xml genuinely signed; genuine cert)"
    - ".planning/phases/29-cryptographic-xmldsig-verification/deferred-items.md (marked the triage RESOLVED)"

key-decisions:
  - "The signer computes its digest/signature by parsing its OWN emitted bytes and binding the exact Assertion/SignedInfo nodes the verifier will bind (D-12) — guaranteeing byte-alignment instead of canonicalizing a standalone parse"
  - "Added sign_response/1 (re-sign an existing Response in place) so the triage preserves each fixture's exact assertion shape; this was the lowest-blast-radius way to re-point the time/replay/success rows whose declared outcome fires AT or AFTER the crypto step"
  - "Triaged acs_controller_test.exs + telemetry_test.exs too (beyond the plan's files_modified list) — Task 3 mandates 'include any other file the grep surfaces' and the full-suite green gate requires them; both were in deferred-items.md"

patterns-established:
  - "D-11/D-12 genuine test-signer: reuse FakeIdP's key + the verifier's C14N engine; never a second keypair or a divergent signer"
  - "Positive-control discipline: the genuine signer is the ONLY input that verifies {:ok}; every other structure-only input fails closed"

requirements-completed: [SIGV-01, SIGV-02]

duration: ~32min
completed: 2026-05-24
---

# Phase 29 Plan 04: Genuine XMLDSig test-signer + positive control + existing-test triage Summary

**A reusable, prod-guarded genuine XMLDSig signer (D-11) that reuses FakeIdP's RSA-2048 keypair and the verifier's own C14N engine to prove the POSITIVE control (a legitimately-signed Response verifies `{:ok, %SignedNode{}}`), plus the wrong-key (`:invalid_signature`) and tampered-NameID (`:digest_mismatch`) negatives, and the full triage of all 10 structure-only `{:ok}` tests so `mix test --warnings-as-errors` is green (524/0).**

## Performance

- **Duration:** ~32 min
- **Completed:** 2026-05-24T13:19Z
- **Tasks:** 3
- **Files modified:** 6 (1 created, 5 modified) + deferred-items.md

## Accomplishments

- **`Relyra.TestSupport.XmldsigSigner` (D-11)** — emits real `ds:DigestValue` (via `PureBeam.canonicalize`) + real `ds:SignatureValue` (`:public_key.sign` over `C14N.serialize`-canonicalized `SignedInfo`), reusing `FakeIdP.keypair()`. It parses its OWN emitted bytes and binds the exact Assertion/SignedInfo nodes the verifier binds, so signer and verifier canonicalize identically (D-12, no divergent signer). Prod-guarded via `@prod_build` + `ensure_not_prod!`. Phase-30 promotion target (fills the empty `SignedInfo` `FakeIdP.response_xml` emits today).
- **POSITIVE control PROVEN (ROADMAP success #3, T-29-14):** a genuinely-signed Response → `{:ok, %Relyra.Security.SignedNode{}}` through `PureBeam.parse_safely → Signature.verify/4`. The verifier is demonstrably NOT an always-reject stub.
- **Real-signature negatives:** wrong-key (verify the genuine Response against a throwaway-keypair cert) → `:invalid_signature` (T-29-16); NameID rewritten AFTER signing → `:digest_mismatch` (T-29-17, the SignatureValue is still well-formed; only the digest catches the tamper).
- **All 10 structure-only `{:ok}` tests triaged** to genuine signatures (disposition a — re-point, not weaken). Full `mix test --warnings-as-errors` = **524/0**; the Phase 29 full-suite gate is met. Trust-gate tests untouched; no test deleted; no Plan 03 / Task 2 crypto assertion weakened.

## Task Commits

1. **Task 1: Build the genuine XMLDSig signer (D-11)** — `c45864f` (feat)
2. **Task 2: Positive control + wrong-key + tampered-NameID negatives** — `531a4ae` (test)
3. **Task 3: Triage all 10 structure-only `{:ok}` tests** — `08fbc66` (test)

**Plan metadata:** (this commit — docs: complete plan)

## Files Created/Modified

- `lib/relyra/test_support/xmldsig_signer.ex` — the D-11 reusable signer: `signed_response/1` (build a fresh genuinely-signed Response, with field overrides + a `tamper_name_id` knob), `sign_response/1` (genuinely sign an EXISTING Response in place by injecting a real DigestValue + SignatureValue, preserving its exact shape), `self_signed_cert_pem/0` (the FakeIdP-derived trusted cert).
- `test/relyra/security/signature_crypto_test.exs` — added the positive control + wrong-key + tampered-NameID assertions driven by the signer through the full `Signature.verify/4` path; all Plan 03 negatives unchanged (22/0).
- `test/protocol/consume_response_pipeline_test.exs` — `response_xml/1` now routes its structure-only output through `XmldsigSigner.sign_response/1`; manifest payloads with a signed Reference are re-signed at test time; the connection carries the genuine cert (12/0).
- `test/conformance/sp_conformance_test.exs` — consume-path fixtures (the pass row, the idp-initiated row, AND the 4 reject rows whose error fires after crypto) genuinely signed; genuine cert (2/0).
- `test/phoenix/acs_controller_test.exs` — ACS success POSTs a genuinely-signed `@valid_xml` and resolves a connection whose cert is the genuine FakeIdP-derived PEM (2/0).
- `test/relyra/telemetry_test.exs` — the success `response_xml/0` genuinely signed; genuine cert so the `signature.verify` telemetry emits `outcome: :ok` for the right reason (4/0).

## Decisions Made

- **Byte-alignment by self-parse (D-12):** rather than canonicalizing a standalone Assertion parse, the signer parses its *emitted* XML and binds the exact tree nodes the verifier will bind, then canonicalizes THEM. This makes the anti-divergent-signer guarantee structural, not a convention that can drift.
- **`sign_response/1` (in-place re-sign):** the time / replay / success manifest+fixture rows declare outcomes that fire AT or AFTER the crypto step, so they must pass crypto first. Re-signing each fixture in place (injecting a real DigestValue/SignatureValue) preserves its exact assertion shape — the lowest-risk way to keep every downstream assertion meaningful.
- **Scope: triaged 2 files beyond the plan's `files_modified`** (`acs_controller_test.exs`, `telemetry_test.exs`). Task 3 explicitly says "include any other file the grep surfaces," both were enumerated in `deferred-items.md`, and the full-suite green gate requires them. No verifier change; same re-point-at-genuine-signer disposition.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `XmldsigSigner.sign_response/1` to genuinely re-sign existing fixtures in place**
- **Found during:** Task 3 (triage)
- **Issue:** `signed_response/1` emits a fixed Assertion shape, but the triaged fixtures (manifest time/replay/success rows, conformance reject rows, the ACS `@valid_xml`) each have a DIFFERENT, fixed element shape the downstream stages assert on. Re-emitting them from the signer's fixed shape would change the fields under test.
- **Fix:** Added `sign_response/1`, which injects a genuine DigestValue + SignatureValue into ANY existing structure-only Response (computed via the verifier's canonicalize path), preserving the input's exact shape. Used it across all four triaged test files.
- **Files modified:** `lib/relyra/test_support/xmldsig_signer.ex` (+ the 4 test files)
- **Verification:** Each triaged lane green; full `mix test --warnings-as-errors` = 524/0.
- **Committed in:** `08fbc66` (Task 3 commit)

**2. [Rule 3 - Blocking] Removed now-unused `FakeConnectionResolver` alias in `acs_controller_test.exs`**
- **Found during:** Task 3 (ACS triage)
- **Issue:** Replacing the ACS success test's resolver with `GenuineCertConnectionResolver` left `alias ...FakeConnectionResolver` unused → `--warnings-as-errors` failed (tests passed 2/0 but the suite aborted on the warning).
- **Fix:** Dropped the unused alias.
- **Files modified:** `test/phoenix/acs_controller_test.exs`
- **Verification:** `mix test test/phoenix/acs_controller_test.exs --warnings-as-errors` → 2/0 clean.
- **Committed in:** `08fbc66` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 - blocking). No scope creep on the verifier; both were enablers for the mandated full-suite green gate.

## Triage Disposition Table

All 10 deferred rows resolved via disposition (a) — re-point at the genuine signer (no rejection-rewrite, no deletion, no verifier weakening):

| File:Line (declared) | Disposition |
|---|---|
| `consume_response_pipeline_test.exs` manifest (`:117`) — 5 rows fired `:invalid_signature` before their stage | manifest payloads with a signed Reference re-signed via `sign_response/1`; genuine cert |
| `consume_response_pipeline_test.exs` `:134` replay-consume-blocks | `response_xml/1` genuinely signed → reaches replay gate → `:replayed_assertion` |
| `consume_response_pipeline_test.exs` `:168` clock-skew config | `response_xml/1` genuinely signed → reaches time stage |
| `consume_response_pipeline_test.exs` `:219` consume-order gate | genuinely signed → both gates pass → `{:ok}` |
| `consume_response_pipeline_test.exs` `:242` explicit request_intent compat | genuinely signed → `{:ok}` |
| `consume_response_pipeline_test.exs` `:266` request-consume-blocks | genuinely signed → reaches request-consume gate → `:request_intent_consumed` |
| `consume_response_pipeline_test.exs` `:289` skew boundary | genuinely signed → reaches time stage (`{:ok}` + `:assertion_not_yet_valid`) |
| `sp_conformance_test.exs` `:30` (executed manifest rows) | consume-path fixtures (pass + reject) genuinely signed; genuine cert |
| `acs_controller_test.exs` `:52` ACS success | genuinely-signed `@valid_xml` + genuine-cert resolver |
| `telemetry_test.exs` `:152` ACS telemetry success | success `response_xml/0` genuinely signed; genuine cert |

## Threat Register Outcomes

| Threat ID | Disposition | Realized mitigation |
|---|---|---|
| T-29-14 (always-reject verifier) | mitigated | POSITIVE control: genuine signer → `{:ok, %SignedNode{}}` (the verifier still WORKS) |
| T-29-15 (divergent second signer → false positive) | mitigated | Signer self-parses + binds the verifier's exact nodes and uses `C14N.serialize`/`PureBeam.canonicalize` (D-12); reuses FakeIdP's key (D-11) |
| T-29-16 (wrong-key acceptance) | mitigated | Wrong-key negative → `:invalid_signature` against a throwaway-keypair cert |
| T-29-17 (post-signing content tamper) | mitigated | Tampered-NameID negative → `:digest_mismatch` (digest recompute catches it) |
| T-29-18 (signing code in prod) | mitigated | `@prod_build` + `ensure_not_prod!` guard mirroring FakeIdP |
| T-29-19 (stale structure-only fixtures masking a broken crypto path) | mitigated | All 10 re-pointed at the genuine signer; no `--warnings-as-errors` relaxation, no deleted coverage |
| T-29-SC (package installs) | accepted | No installs — OTP `:public_key`/`:crypto` only |

## Verification Results

- `mix test test/relyra/security/signature_crypto_test.exs --warnings-as-errors` → **14/0** (Task 1 lane)
- `mix test test/relyra/security/signature_crypto_test.exs test/security/signed_node_binding_test.exs --warnings-as-errors` → **22/0** (Task 2 lane: positive + wrong-key + tampered-NameID + Plan 03 negatives + gate regression)
- `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors` → **12/0**
- `mix test test/conformance/sp_conformance_test.exs --warnings-as-errors` → **2/0**
- `mix test test/phoenix/acs_controller_test.exs --warnings-as-errors` → **2/0**
- `mix test test/relyra/telemetry_test.exs --warnings-as-errors` → **4/0**
- `mix test --warnings-as-errors` (full-suite phase gate) → **524/0** ✅
- `mix compile --warnings-as-errors` → clean
- The signer module contains no second `:public_key.generate_key` (reuses `FakeIdP.keypair()`).

## Issues Encountered

- The genuine signer's digest depends on the referenced element's in-scope namespaces, which differ between a standalone Assertion parse and the Assertion-within-Response parse. Resolved by having the signer parse its OWN emitted Response and bind the exact node the verifier will bind (the D-12 self-parse approach), so the bytes match by construction.

## Known Stubs

None — no stubbed/placeholder data paths introduced. The signer emits real cryptographic material; the cert is a real (self-signed) X.509 derived from FakeIdP's key.

## Next Phase Readiness

- **SIGV-01/02 fully proven end-to-end:** positive control + wrong-key + tampered-NameID, with a green full suite.
- **Plan 05 (SIGV-04, metadata-root):** `verify_metadata_root/4` already inherits the crypto via `do_verify/4` (Plan 03); the metadata-root `parsed_doc` must surface the same tree-bound D-02 fields (RESEARCH Pitfall 2 / Open Q1). `XmldsigSigner.sign_response/1` can be reused to mint a genuinely-signed `<EntityDescriptor>` once the metadata-root shape exposes a signed Reference.
- **Phase 30:** PROMOTE `Relyra.TestSupport.XmldsigSigner` into `FakeIdP` (fill the empty `SignedInfo` in `FakeIdP.response_xml`) — the byte-alignment guarantee (D-12) is the whole point; keep it on promotion.

## Self-Check: PASSED

All key files exist on disk (`lib/relyra/test_support/xmldsig_signer.ex`, `29-04-SUMMARY.md`); all three per-task commits (`c45864f` Task 1, `531a4ae` Task 2, `08fbc66` Task 3) are present in git history.

---
*Phase: 29-cryptographic-xmldsig-verification*
*Completed: 2026-05-24*
