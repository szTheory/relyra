---
phase: 30-adversarial-crypto-assurance
plan: 01
subsystem: testing
tags: [xmldsig, saml, fake-idp, test-support, c14n, signature, public-key]

# Dependency graph
requires:
  - phase: 29-cryptographic-xmldsig-verification
    provides: "Relyra.TestSupport.XmldsigSigner (D-11 genuine signer: sign_response/1, self_signed_cert_pem/0) reusing FakeIdP.keypair() + the verifier's own C14N engine"
  - phase: 28-...
    provides: "Relyra.Security.XML.C14N exclusive-C14N engine + PureBeam SaxyTree parser the signer canonicalizes against (anti-divergent-signer guarantee)"
provides:
  - "FakeIdP.sign/2 now emits a Response carrying a REAL ds:DigestValue + ds:SignatureValue (no longer the structure-only empty SignedInfo) — ASSUR-02"
  - "FakeIdP.self_signed_cert_pem/0 — the trust cert callers configure cert_chain / idp_certificates with so FakeIdP-signed Responses verify {:ok}"
  - "FakeIdP.response_xml SignedInfo now carries <CanonicalizationMethod> and is whitespace-collapse-free (genuinely signable by XmldsigSigner.sign_response/1)"
affects: [30-02-adversarial-corpus-positive-control, 30-03, 30-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-signing-path (D-01): FakeIdP.sign delegates to the ONE genuine signer (XmldsigSigner.sign_response/1); no second signer / no bespoke crypto inside FakeIdP — neutralizes the T-30-01/T-29-15 canonicalizer-differential false-positive"
    - "Promotion-not-rewrite: a Phase-29 test-support module is reused verbatim through delegation rather than re-implemented in its consumer"

key-files:
  created: []
  modified:
    - lib/relyra/test_support/fake_idp.ex

key-decisions:
  - "D-02 CanonicalizationMethod added as first child of FakeIdP's <SignedInfo>; whitespace-collapse (String.replace ~r/\\s+/) dropped so the emitted bytes are genuinely signable by XmldsigSigner.sign_response/1 (Pitfall 5)"
  - "D-01 FakeIdP.sign/2 routes response_xml through XmldsigSigner.sign_response/1 and base64-encodes the signer's :response_xml (no padding); XmldsigSigner referenced fully-qualified (no alias) to keep --warnings-as-errors clean (Pitfall 4)"
  - "D-03 self_signed_cert_pem/0 exposed via defdelegate to XmldsigSigner — same keypair, so the delegated cert's SubjectPublicKeyInfo is byte-identical to the signer's (the load-bearing equivalence for cert_chain trust)"
  - "Acceptance-criterion wording reconciliation: 'returns the same PEM' is unsatisfiable as literal byte-equality — :public_key.pkix_test_root_cert/2 mints a random serial per call, so even two XmldsigSigner.self_signed_cert_pem/0 calls differ; the meaningful (and verified) equivalence is identical public key / SPKI"

patterns-established:
  - "FakeIdP positive-control readiness: a FakeIdP-signed Response + FakeIdP.self_signed_cert_pem/0 as cert_chain is now sufficient to drive {:ok, %SignedNode{}} through the real verifier (proven end-to-end in Plan 02)"

requirements-completed: [ASSUR-02]

# Metrics
duration: 3min
completed: 2026-05-24
---

# Phase 30 Plan 01: FakeIdP Real Cryptographic Signing Summary

**FakeIdP.sign now emits a Response carrying a genuine RSA ds:SignatureValue + SHA-256 ds:DigestValue by delegating to the Phase-29 XmldsigSigner (single signing path), and exposes self_signed_cert_pem/0 for cert_chain trust — ASSUR-02.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-24T16:24:10Z
- **Completed:** 2026-05-24T16:27:20Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- `FakeIdP.sign(%Builder{}, opts)` no longer base64-encodes a structure-only empty `<SignedInfo>`; it routes the rendered XML through `Relyra.TestSupport.XmldsigSigner.sign_response/1` and base64-encodes (no padding) the signer's `:response_xml`, which carries a real `ds:DigestValue` over the canonicalized `<Assertion>` and a real `ds:SignatureValue` over the canonicalized `<SignedInfo>` — verified visible in the decoded demo-test payload (`<DigestValue>OiP+GzD7suAcNAiekoCWwA3mKWmLtZW3g3XfTug21Ls=</DigestValue>` + a 2048-bit `<SignatureValue>`).
- `FakeIdP.response_xml`'s `<SignedInfo>` now carries `<CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>` as its first child and no longer applies the `String.replace(~r/\s+/, " ")` whitespace-collapse — so the emitted bytes are genuinely signable by the promoted signer (Pitfall 5).
- `FakeIdP.self_signed_cert_pem/0` added (defdelegate → `XmldsigSigner`) so callers can configure `cert_chain` / `idp_certificates` with FakeIdP's own trust cert.
- Single-signing-path discipline (D-01) preserved: no second signer and no bespoke `:public_key.sign` / `:crypto.hash` inside `fake_idp.ex` — the verifier's own C14N engine is the only canonicalizer, neutralizing the canonicalizer-differential false-positive (T-30-01 / T-29-15).

## Task Commits

Each task was committed atomically:

1. **Task 1: Reconcile FakeIdP's response_xml shape for genuine signing (D-02)** — `f9047fe` (fix)
2. **Task 2: Delegate sign/2 to the genuine signer + expose the trust cert (D-01/D-03)** — `18f5bd8` (feat)

_(Plan metadata commit covers this SUMMARY in worktree mode.)_

## Files Created/Modified
- `lib/relyra/test_support/fake_idp.ex` — added `<CanonicalizationMethod>` to the `<SignedInfo>` template and dropped whitespace-collapse (Task 1); rewired `sign(%Builder{}, opts)` to delegate to `XmldsigSigner.sign_response/1` and added the `self_signed_cert_pem/0` defdelegate (Task 2).

## Decisions Made
- **D-02 (Task 1):** `<CanonicalizationMethod>` placed as the first child of `<SignedInfo>` (mirroring `xmldsig_signer.ex:254`); whitespace-collapse removed, `String.trim()` kept. The SAML `xmlns="urn:oasis:names:tc:SAML:2.0:assertion"` declarations on `<Issuer>`/`<Assertion>` were intentionally KEPT (the signer self-parses the emitted bytes, so namespaces stay consistent and realistic).
- **D-01 (Task 2):** Promotion-not-rewrite — `sign/2` reuses the existing genuine signer verbatim via full-qualified call; the `sign(opts, extra_opts)` list clause is unchanged. `XmldsigSigner` referenced fully-qualified rather than via `alias` to avoid an unused-alias `--warnings-as-errors` abort (Pitfall 4); the only consumer references are the `sign/2` body and the `defdelegate`, both fully-qualified.
- **D-03 (Task 2):** `self_signed_cert_pem/0` exposed as a `defdelegate` to `XmldsigSigner` (single source of the trust cert; same `FakeIdP.keypair()`).
- **D-10 scope fence:** No file under `lib/relyra/security/` was modified — production crypto stays frozen.

## Deviations from Plan

None - plan executed exactly as written. (No code-behavior deviations; one acceptance-criterion *wording* reconciliation is documented under Issues Encountered — it required no code change.)

## Issues Encountered

- **Deps not hydrated in the worktree.** `mix compile` initially failed with "the dependency is not available" for every Hex package. Resolved with `mix deps.get`, which hydrates the **already-pinned** dependencies from the committed `mix.lock` — this is lockfile hydration, NOT adding/choosing a new package (no slopcheck surface; the threat model marks package installs `accept` / Not applicable). After hydration, `mix compile --warnings-as-errors` is clean.
- **Acceptance-criterion "returns the same PEM" is unsatisfiable as literal byte-equality.** `XmldsigSigner.self_signed_cert_pem/0` is non-deterministic: `:public_key.pkix_test_root_cert/2` mints a fresh random serial number on every call, so two consecutive calls to `XmldsigSigner.self_signed_cert_pem/0` itself produce different PEM strings (verified: `false`, both 1339 bytes). The `defdelegate` makes `FakeIdP.self_signed_cert_pem/0` *the same function*, so the criterion's intent — exposing the trust cert for `cert_chain` (D-03) — is fully met. The meaningful, load-bearing equivalence (identical public key for trust) was verified instead: both certs' `SubjectPublicKeyInfo` are byte-identical (`true`), because both derive from the shared `FakeIdP.keypair()`. No code change was needed; the criterion wording was reconciled to the actual API contract.

## Verification

- `mix compile --warnings-as-errors` — exit 0 (clean) after both tasks.
- `mix test test/test_support_demo_test.exs --warnings-as-errors` — 2 tests, 0 failures (blast-radius regression; the stub-controller demo stays green and the decoded payload shows a real DigestValue + SignatureValue).
- `mix test test/relyra/metadata/auto_refresh_test.exs --warnings-as-errors` — 16 tests, 0 failures (confirms the inline-keypair consumer is unaffected by the shape/delegation change).
- Scope fence: `git diff 10a78bb..HEAD --name-only` shows only `lib/relyra/test_support/fake_idp.ex` changed; no `lib/relyra/security/` file touched (D-10).
- `grep -v '^#' lib/relyra/test_support/fake_idp.ex | grep -c 'public_key.sign\|crypto.hash'` → 0 (no bespoke crypto / no second signer, D-01).
- `<CanonicalizationMethod ...>` count in the template = 1 (first child of `<SignedInfo>`); whitespace-collapse `String.replace(~r/\s+/)` count = 0; SAML xmlns count = 2 (Issuer + Assertion, KEPT).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- **Plan 02 (Wave 2) is unblocked.** The FakeIdP-driven positive control (`{:ok, %SignedNode{}}`) can now be proven end-to-end: feed `FakeIdP.sign(...)` (decoded) through the verifier with `FakeIdP.self_signed_cert_pem/0` configured as the connection's `cert_chain` / `idp_certificates`. The signing change in this plan is the load-bearing integration; Plan 02's corpus drives through it.
- No blockers. Production crypto remains frozen (D-10).

## Known Stubs

None - the modified file (`lib/relyra/test_support/fake_idp.ex`) contains no stub/placeholder patterns; `FakeIdP.sign/2` now produces a fully genuine signature (real DigestValue + SignatureValue), replacing the prior structure-only stub.

## Self-Check: PASSED

- FOUND: `.planning/phases/30-adversarial-crypto-assurance/30-01-SUMMARY.md`
- FOUND: `lib/relyra/test_support/fake_idp.ex`
- FOUND commit `f9047fe` (Task 1)
- FOUND commit `18f5bd8` (Task 2)
- FOUND commit `9791a75` (SUMMARY)

---
*Phase: 30-adversarial-crypto-assurance*
*Completed: 2026-05-24*
