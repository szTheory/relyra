---
phase: 30-adversarial-crypto-assurance
plan: 02
subsystem: testing
tags: [xmldsig, c14n, public_key, adversarial-corpus, fakeidp, digest_mismatch, invalid_signature]

# Dependency graph
requires:
  - phase: 30-01
    provides: "FakeIdP.sign/2 promoted to delegate to the genuine Phase-29 signer (real DigestValue + SignatureValue); FakeIdP.self_signed_cert_pem/0 exposes the trust cert"
  - phase: 29
    provides: "Frozen Signature.verify/4 crypto path (:public_key.verify of canonicalized SignedInfo + constant-time DigestValue recompute); XmldsigSigner genuine signer; C14N exclusive engine"
provides:
  - "Permanent @moduletag :adversarial_crypto corpus (test/security/xml/adversarial_crypto_test.exs) proving rejection of forged-sig / wrong-key / tampered-content / c14n-differential / algorithm-substitution, plus a genuine positive control"
  - "ASSUR-02 end-to-end exercise of the promoted FakeIdP.sign real-signing path"
  - "The genuinely-NEW c14n-differential :digest_mismatch case (D-06) complementary to the JSON-corpus :canonicalization_failed row from 30-03"
affects: [30-04, disclosure, ci.security]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Adversarial corpus as a single @moduletag-gated suite: every assertion pins the EXACT %Error{type: ...} (or %SignedNode{}), never a bare {:error, _}, so a no-op mutation surfaces as a {:ok} failure"
    - "Promote-don't-re-derive: proven Phase-29 recipes consolidated into a permanent gated suite rather than re-invented"
    - "C14N-differential tamper via a C14N-PRESERVED post-signing mutation (added non-namespace attribute on the apex) with an explicit landed-mutation guard"

key-files:
  created:
    - "test/security/xml/adversarial_crypto_test.exs"
  modified: []

key-decisions:
  - "D-06 c14n-differential mutation = add a non-namespace attribute (Foo=\"bar\") to the <Assertion> apex — unambiguously C14N-PRESERVED per PROVENANCE Pitfall 8 (attrs are sorted by resolved-URI-then-local but NEVER dropped), so the recomputed exclusive-C14N digest differs -> :digest_mismatch"
  - "Negatives drive through XmldsigSigner.signed_response/1 (cleaner mutation seam); the positive control drives END-TO-END through the promoted FakeIdP.sign (ASSUR-02). Post-promotion both go through the SAME signing path (D-01)"
  - "ECDSA fail-closed carried into the gate as an explicit 6th assertion (:unsupported_signature_algorithm), NOT a 6th category — closes the algorithm-substitution sample (T-30-08)"
  - "Production crypto FROZEN: no file under lib/relyra/security/ touched; no XSW-shaped input built (no WR-03 brush, D-10/T-30-10)"

patterns-established:
  - "Permanent adversarial corpus: positive control + 5 negative categories, each pinning an exact typed error, gated by a single @moduletag for selective CI naming (--only adversarial_crypto)"
  - "Landed-mutation guard: assert the C14N-PRESERVED tamper actually changed the XML before asserting the rejection, so a no-op String.replace cannot falsely pass"

requirements-completed: [ASSUR-01, ASSUR-02]

# Metrics
duration: ~4min
completed: 2026-05-24
---

# Phase 30 Plan 02: Adversarial Crypto Corpus Summary

**Permanent `@moduletag :adversarial_crypto` corpus that drives the frozen Phase-29 `Signature.verify/4` path: a genuine FakeIdP.sign-signed Response verifies `{:ok, %SignedNode{}}`, while forged-sig / wrong-key / tampered-content / c14n-differential / ECDSA each reject with the EXACT typed error.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-24T16:31Z (approx)
- **Completed:** 2026-05-24T16:33Z
- **Tasks:** 2
- **Files modified:** 1 (created)

## Accomplishments

- Created `test/security/xml/adversarial_crypto_test.exs` (`Relyra.Security.AdversarialCryptoTest`, `async: true`, `@moduletag :adversarial_crypto`) — the permanent ASSUR-01 corpus, 198 lines, 6 assertions.
- **Positive control (ASSUR-02 end-to-end):** `FakeIdP.sign(FakeIdP.build_response())` → base64-decode → `PureBeam.parse_safely` → `Signature.verify(parsed_doc, connection(), [FakeIdP.self_signed_cert_pem()])` → `{:ok, %SignedNode{}}` with `signature_method == rsa-sha256`. Literally exercises the promoted real-signing path.
- **5 negative categories**, each pinning the exact `%Error{type: ...}`:
  - forged-sig (same-length random base64) → `:invalid_signature`
  - wrong-key (throwaway cert) → `:invalid_signature`
  - tampered-content (post-signing NameID rewrite) → `:digest_mismatch`
  - **c14n-differential (D-06, NEW)** — added non-namespace attribute on the `<Assertion>` apex → `:digest_mismatch`
  - ECDSA carry-over → `:unsupported_signature_algorithm`
- Full suite green: `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors` = 6 tests, 0 failures.
- Per-wave merge check green: `--only security_corpus --only gate02_c14n --only adversarial_crypto --warnings-as-errors` = 16 tests, 0 failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Suite with 5 promoted recipes + positive control + ECDSA carry-over** — `17fa76c` (test)
2. **Task 2: NEW c14n-differential :digest_mismatch case (D-06)** — `676343e` (test)

## Files Created/Modified

- `test/security/xml/adversarial_crypto_test.exs` — Permanent `@moduletag :adversarial_crypto` adversarial corpus: positive control (FakeIdP.sign end-to-end) + forged-sig + wrong-key + tampered-content + c14n-differential + ECDSA, each asserting an exact typed result against the frozen `Signature.verify/4`.

## Decisions Made

- **C14N-differential mutation (D-06):** chose an added non-namespace attribute (`Foo="bar"`) on the `<Assertion ID="assertion-1">` apex. PROVENANCE Pitfall 8 confirms C14N sorts attributes by resolved-URI-then-local but NEVER drops them, so an added non-namespace attribute is unambiguously C14N-PRESERVED — it appears in the canonical output, the recomputed exclusive-C14N digest differs, and the verifier rejects `:digest_mismatch`. Deliberately avoided every AVOID-list mutation (attribute reordering / unused-ns decl / empty-element expansion / text re-escaping), which C14N normalizes away and would falsely pass `{:ok}`. Added a landed-mutation guard (`assert mutated =~ Foo="bar"`, `refute mutated == original`) so a no-op `String.replace` cannot silently assert against the un-mutated, still-valid doc.
- **Signing seams:** the positive control drives through the promoted `FakeIdP.sign` (ASSUR-02 end-to-end), while the negatives use `XmldsigSigner.signed_response/1` directly (cleaner mutation seam). Post-promotion both go through the SAME signing path (D-01).
- **ECDSA as a 6th ASSERTION, not a 6th category:** carried the existing fail-closed ECDSA assertion into the gate to close the algorithm-substitution sample (T-30-08).
- **Frozen crypto honored:** no file under `lib/relyra/security/` was touched; no XSW-shaped input was constructed (no WR-03 brush, D-10/T-30-10).

## Deviations from Plan

None - plan executed exactly as written.

The plan front-loaded the exact recipes and the recommended D-06 mutation; both tasks landed verbatim. The only environment step needed was `mix deps.get` in the fresh worktree (deps not shared from the main checkout) — `mix.lock` was unchanged (deps resolved to the committed lock), so this was not a deviation and produced no file changes to commit.

## Issues Encountered

- The worktree had no `deps/` populated; `mix` aborted with "Unchecked dependencies." Resolved with `mix deps.get` (no `mix.lock` change). Not a code issue.

## Known Stubs

None — the suite is fully wired: every assertion drives a real input through the genuine signer / FakeIdP.sign and the frozen `Signature.verify/4`. No placeholder data, no hardcoded empties, no TODO/FIXME.

## Self-Check: PASSED

- `test/security/xml/adversarial_crypto_test.exs` — FOUND
- Commit `17fa76c` — FOUND
- Commit `676343e` — FOUND
- Suite green: 6 tests / 0 failures under `--only adversarial_crypto --warnings-as-errors`
- No file under `lib/relyra/security/` modified

## Next Phase Readiness

- The `:adversarial_crypto` suite is ready for Plan 04 to NAME into `ci.security` (`--only adversarial_crypto`). Gating itself is Plan 04's scope, not this plan's.
- ASSUR-01 (rejection corpus + positive control) and ASSUR-02 (FakeIdP real-signing end-to-end) are satisfied by this suite.
- No blockers. Frozen crypto remains untouched.

---
*Phase: 30-adversarial-crypto-assurance*
*Completed: 2026-05-24*
