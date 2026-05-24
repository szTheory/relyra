# Requirements — Milestone v1.1 "Verify the Trust Path"

**Milestone goal:** Make Relyra's Core Value literally true — cryptographically verify SAML response/assertion and metadata signatures so forged or tampered assertions are rejected, not silently accepted.

**Origin:** P0 audit (2026-05-23). `Relyra.Security.Signature` performs trust-discipline gating but never cryptographically verifies signatures (no `:public_key.verify`, no `DigestValue` recompute, `canonicalize/2` is an unused passthrough). Empirically confirmed: a forged `SignatureValue` + attacker-controlled `NameID` is accepted as `{:ok}` — a full authentication bypass in published hex `1.0.0`/`1.1.0`.

**Governing decision:** ADR-0001 — implement real exclusive-C14N + XMLDSig verification in pure-BEAM behind the `Relyra.Security.XML` seam; fall back to hybrid+xmlsec NIF (GATE-03 matrix) ONLY if correctness gates can't be met within the pure-BEAM seam.

---

## v1.1 Requirements

### Signature Verification (SIGV)

- [ ] **SIGV-01** — Response and assertion XMLDSig signatures are cryptographically verified: the canonicalized `SignedInfo` is checked with `:public_key.verify` against the **configured** IdP certificate's public key (never document `KeyInfo`), and any forged or invalid signature is rejected with a typed `%Relyra.Error{}`.
- [ ] **SIGV-02** — The signed `Reference`'s `DigestValue` is recomputed over the canonicalized, enveloped-signature-transformed referenced element and compared; any content tampering (e.g. an altered `NameID`) is rejected even when the `SignatureValue` is otherwise well-formed. _(29-01 landed the byte-exact canonicalization precondition — mixed-content document-order C14N proven vs libxml2; the DigestValue recompute/compare + tamper-rejection arm lands in Plan 03.)_
- [x] **SIGV-03** — Verification uses correct **exclusive XML canonicalization (C14N 1.0 exclusive)** over a real parse tree behind the `Relyra.Security.XML` seam (the `saxy`-backed parser path ADR-0001 specified), with no parser/canonicalization differentials and the verified signature bound to the exact node consumed.
- [ ] **SIGV-04** — Metadata-root signatures (`EntityDescriptor`/`EntitiesDescriptor`) are cryptographically verified using the same primitive (signature math, not fingerprint-pinning alone), preserving operator-pinned trust (`TrustAnchor`) as defense-in-depth.

### Adversarial Assurance (ASSUR)

- [ ] **ASSUR-01** — A permanent adversarial corpus proves rejection of: forged-signature-with-valid-structure, tampered-content (same signature), wrong-key, digest-mismatch, and canonicalization-differential responses — each asserting an `{:error, %Relyra.Error{}}` — plus a positive control proving a genuinely-signed response verifies. Wired into `corpus_gate` and the conformance manifest, green under `mix ci.security`.
- [ ] **ASSUR-02** — `Relyra.TestSupport.FakeIdP` performs real cryptographic signing (XMLDSig with its generated keypair) so the test suite exercises real verification rather than structure-only acceptance.

### Disclosure & Honesty (DISC)

- [ ] **DISC-01** — `docs/security_boundary.md`, `SECURITY_REVIEW.md`, and `docs/security_findings.md` are corrected to describe the actual verification guarantee, and the finding is recorded in the findings ledger with disposition.
- [ ] **DISC-02** — A coordinated security advisory is prepared for publication at the fixed release: GHSA + requested CVE + CHANGELOG security note, marking hex `1.0.0`/`1.1.0` as affected. (Outward publication happens at ship time per the chosen fix-first posture.)

---

## Future Requirements (deferred — next milestone "Advanced Federation")

- Encrypted assertions (EncryptedAssertion / XML-Enc): OAEP + AES-GCM, decrypt→verify, GCM/OAEP-only policy.
- Complete Single Logout: inbound `LogoutResponse` consumption, IdP-initiated `LogoutRequest`, SessionIndex correlation, session termination.
- Signed outbound AuthnRequests (redirect-binding first) for `WantAuthnRequestsSigned` IdPs.
- Adoption docs: generic-SAML runbook + minimum-safe checklist, identity-mapping/provisioning guide, logout adopter guide, operator incident playbook, troubleshooting/error decoder.
- Runnable demo (`dev/relyra_demo.exs` + `Mix.install` quickstart) with a `ci.demo` anti-rot lane; FakeIdP-scoped connection-test stepwise LiveView; installer DX fixes.

## Out of Scope (explicit — unchanged from PROJECT.md, restated for this milestone)

- HTTP-Artifact binding, ECP profile, Attribute Query — demand-gated, not coverage-gated.
- SCIM lifecycle ownership; OIDC/OAuth in-core; hosted broker runtime.
- Native xmlsec NIF — **conditional**: only adopted if ADR-0001's correctness rollback trigger fires (pure-BEAM C14N/verify gates cannot be met). Not a default.

## Traceability

REQ-ID → Phase mapping for milestone v1.1 (every v1.1 requirement maps to exactly one phase; 8/8 covered).

| Requirement | Phase | Status |
|-------------|-------|--------|
| SIGV-03 | Phase 28 — Real C14N parser foundation | Complete |
| SIGV-01 | Phase 29 — Cryptographic XMLDSig verification | In progress (29-03: :public_key.verify of canonicalized SignedInfo wired into the [candidate] arm; forged/non-base64 SignatureValue → :invalid_signature proven via negative controls + genuine positive smoke. Fuller positive control + wrong-key negative + existing-test triage → Plan 04) |
| SIGV-02 | Phase 29 — Cryptographic XMLDSig verification | In progress (29-01 byte-exact C14N precondition done; 29-03: DigestValue recompute over the canonicalized referenced element + constant-time compare wired — truncated/non-base64/wrong digest → :digest_mismatch proven. Full NameID-tamper proof → Plan 04) |
| SIGV-04 | Phase 29 — Cryptographic XMLDSig verification | Pending (verify_metadata_root/4 inherits the 29-03 crypto via do_verify/4; metadata-root tree-bound plumbing + positive control + pinning negative → Plan 05) |
| ASSUR-01 | Phase 30 — Adversarial crypto assurance | Pending |
| ASSUR-02 | Phase 30 — Adversarial crypto assurance | Pending |
| DISC-01 | Phase 31 — Disclosure and docs honesty | Pending |
| DISC-02 | Phase 31 — Disclosure and docs honesty | Pending |

**Coverage:** 8/8 v1.1 requirements mapped. No orphans. No duplicates.
