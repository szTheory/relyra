# Roadmap: Relyra

## Milestones

- ✅ **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- ✅ **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- ✅ **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- ✅ **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- ✅ **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- ✅ **v0.6 — Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- ✅ **v1.0 — External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- 🚧 **v1.1 — Verify the Trust Path** (ACTIVE — P0 security). Phases 28-31. See the v1.1 section below.

## Phases

<details>
<summary>✅ v0.1 — SP-initiated SSO (Phases 1-6) — SHIPPED 2026-04-25</summary>

See `.planning/milestones/v0.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.2 — Enterprise configuration (Phases 7-14) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.2-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.3 — LiveView admin (Phases 15-18) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.3-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.4 — IdP-initiated SSO (Phase 19) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.4-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.5 — Operational maturity (Phases 20-21.2) — SHIPPED 2026-05-07</summary>

See `.planning/milestones/v0.5-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.6 — Operational maturity carryover + SLO (Phases 22-24) — SHIPPED 2026-05-08</summary>

See `.planning/milestones/v0.6-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.0 — External security review + conformance + docs polish (Phases 25-27) — SHIPPED 2026-05-08</summary>

See `.planning/milestones/v1.0-ROADMAP.md`.

</details>

- 🚧 **v1.1 — Verify the Trust Path (Phases 28-31) — ACTIVE.** See the v1.1 section below for phase details.

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 01. XML security ADR + guardrails | v0.1 | 3/3 | Complete | 2026-04-25 |
| 02. Protocol + signature core | v0.1 | 5/5 | Complete | 2026-04-25 |
| 03. Behaviour contracts + stores | v0.1 | 3/3 | Complete | 2026-04-25 |
| 05. Observability + enforcement | v0.1 | 1/1 | Complete | 2026-04-25 |
| 06. Delivery hardening + adoption surface | v0.1 | 1/1 | Complete | 2026-04-25 |
| 07. Schema + connection aggregate | v0.2 | 3/3 | Complete | 2026-05-05 |
| 08. Resolver adapter + snapshotting | v0.2 | 3/3 | Complete | 2026-05-05 |
| 09. Metadata import/export + refresh | v0.2 | 4/4 | Complete | 2026-05-06 |
| 10. Certificate inventory + rollover | v0.2 | 3/3 | Complete | 2026-05-06 |
| 11. Mapping persistence + audit hardening | v0.2 | 4/4 | Complete | 2026-05-06 |
| 12. Metadata refresh trust-state repair | v0.2 | 3/3 | Complete | 2026-05-06 |
| 13. Certificate rollover validation + verification | v0.2 | 3/3 | Complete | 2026-05-06 |
| 14. Mapping/audit milestone verification | v0.2 | 2/2 | Complete | 2026-05-06 |
| 15. Admin shell + connection lifecycle | v0.3 | 3/3 | Complete | 2026-05-06 |
| 16. Metadata management UI | v0.3 | 3/3 | Complete | 2026-05-06 |
| 17. Certificate inventory + staged rollover UI | v0.3 | 2/2 | Complete | 2026-05-06 |
| 18. Mapping editor + audit timeline hardening | v0.3 | 2/2 | Complete | 2026-05-06 |
| 19. IdP-initiated SSO | v0.4 | 3/3 | Complete | 2026-05-06 |
| 20. Bulk operations across connections | v0.5 | 2/2 | Complete | 2026-05-06 |
| 21. Scheduled metadata refresh | v0.5 | 7/7 | Complete | 2026-05-07 |
| 22. Certificate expiry alerts | v0.6 | 1/1 | Complete | 2026-05-07 |
| 23. Diagnostic bundles | v0.6 | 2/2 | Complete | 2026-05-07 |
| 24. Single Logout Protocol | v0.6 | 3/3 | Complete | 2026-05-07 |
| 25. Conformance and CVE Regression Fixtures | v1.0 | 3/3 | Complete | 2026-05-07 |
| 26. Security Audit Preparation and Remediation | v1.0 | 3/3 | Complete | 2026-05-08 |
| 27. Adopter Onboarding Polish and Case Studies | v1.0 | 3/3 | Complete | 2026-05-08 |
| 28. Real C14N parser foundation | v1.1 | 4/4 | Complete    | 2026-05-24 |
| 29. Cryptographic XMLDSig verification | v1.1 | 5/5 | Complete    | 2026-05-24 |
| 30. Adversarial crypto assurance | v1.1 | TBD | Not started | - |
| 31. Disclosure and docs honesty | v1.1 | TBD | Not started | - |

---

## Milestone v1.1 — Verify the Trust Path (ACTIVE)

**Goal:** Make Relyra's Core Value literally true — cryptographically verify SAML response/assertion **and** metadata signatures so forged or tampered assertions are rejected, not silently accepted.

**Why now (P0 — confirmed 2026-05-23):** A code + empirical audit found `Relyra.Security.Signature` performs trust-*discipline* gating (document-`KeyInfo` rejection, duplicate-ID / single-signed-node selection, algorithm allowlisting) but **never cryptographically verifies the signature**: no `:public_key.verify`, no `DigestValue` recompute/compare, and `canonicalize/2` on the `Relyra.Security.XML` seam is an unused passthrough. A forged `SignatureValue` carrying an attacker-controlled `NameID` is accepted as `{:ok}` — a full SAML authentication bypass affecting published hex `1.0.0` / `1.1.0`. This invalidates the Core Value invariant until fixed; everything else waits behind it.

**Governing decision:** ADR-0001 — pure-BEAM exclusive-C14N + XMLDSig verify behind the `Relyra.Security.XML` seam. The hybrid+xmlsec NIF (GATE-03 matrix) is a **conditional rollback** triggered only if the pure-BEAM correctness gates cannot be met — NOT a planned phase.

**Branch:** `security/xmldsig-real-verification` (fix-first posture; advisory published at the fixed release).

**Granularity:** standard. **Coverage:** 8/8 v1.1 requirements mapped.

### Phases

- [x] **Phase 28: Real C14N parser foundation** — Add the `saxy`-backed parse tree + exclusive C14N 1.0 behind the existing `Relyra.Security.XML` seam, replacing regex string-scanning, preserving callback compatibility and the hardened entity/size/DOCTYPE guards. (SIGV-03) (completed 2026-05-24)
- [x] **Phase 29: Cryptographic XMLDSig verification** — Wire `:public_key.verify` of canonicalized `SignedInfo` against the configured IdP cert + `DigestValue` recompute/compare into `do_verify`, applied to both `verify/4` and `verify_metadata_root/4`; reject forged, tampered, and wrong-key inputs with typed errors. (SIGV-01, SIGV-02, SIGV-04) (completed 2026-05-24)
- [ ] **Phase 30: Adversarial crypto assurance** — Make `FakeIdP` perform real cryptographic signing and add the permanent adversarial corpus (forged-sig / tampered-content / wrong-key / digest-mismatch / c14n-differential REJECTED + positive control), wired into `corpus_gate` + the conformance manifest, green under `mix ci.security`. (ASSUR-01, ASSUR-02)
- [ ] **Phase 31: Disclosure and docs honesty** — Correct the security docs that overstate the guarantee, record the finding in the ledger, and prepare the GHSA + CVE + CHANGELOG security note marking hex `1.0.0`/`1.1.0` affected (publish at fixed-release ship time). (DISC-01, DISC-02)

### Phase Details

#### Phase 28: Real C14N parser foundation

**Goal**: Verification can operate over a correct, canonicalized parse tree — the precondition for any cryptographic check.
**Depends on**: Nothing new (extends the existing `Relyra.Security.XML` seam shipped in v0.1).
**Requirements**: SIGV-03
**Success Criteria** (what must be TRUE):

  1. `saxy` is a real dependency in `mix.exs` and the seam parses SAML XML into a structured parse tree (not regex string-scanning), with the single-parser trust path preserved.
  2. The `canonicalize/2` callback produces correct **exclusive XML canonicalization (C14N 1.0 exclusive)** output over the parse tree for a known fixture, byte-for-byte matching an independent reference (xmlsec / pyXMLSec) — the GATE-02 differential gate passes.
  3. The existing hardened guards (DOCTYPE/ENTITY rejection, pre- and post-decode size limits, document-`KeyInfo` rejection, duplicate-ID rejection, single-signed-node selection) still hold against the v1.0 corpus on the new parser — no regression, no second parser path.
  4. The verified signed node is bound to the exact element consumed downstream (no node/canonicalization differential between what is canonicalized and what is returned as the `SignedNode`).

**Plans**: 4 plans

  - [x] 28-01-PLAN.md — Add non-optional saxy dep (A1 checkpoint) + Saxy.Handler tree builder with in-scope ns stack + 3 infoset-normalization layers
  - [x] 28-02-PLAN.md — Hand-rolled exclusive C14N 1.0 engine (visibly-utilized rendering, sort, dual escaping, empty-element, no trailing newline) + enveloped-sig transform / PrefixList / transform allowlist
  - [x] 28-03-PLAN.md — Re-wire pure_beam seam onto the saxy tree (retire regex, re-derive all fields, port guards, additive :parse_tree, node binding D-10, canonicalize delegates to C14N)
  - [x] 28-04-PLAN.md — Mint + commit golden-byte oracle (lxml/xmlsec1, D-12) + GATE-02 positive byte-equality (D-11) + node-binding assertion

#### Phase 29: Cryptographic XMLDSig verification

**Goal**: A forged or tampered SAML signature is cryptographically rejected; only a genuinely-signed node from the configured IdP verifies.
**Depends on**: Phase 28 (needs correct canonicalization to verify against).
**Requirements**: SIGV-01, SIGV-02, SIGV-04
**Success Criteria** (what must be TRUE):

  1. `do_verify` cryptographically checks the canonicalized `SignedInfo` with `:public_key.verify` against the **configured** IdP certificate's public key (never document `KeyInfo`); a forged or invalid `SignatureValue` returns `{:error, %Relyra.Error{}}`.
  2. The signed `Reference`'s `DigestValue` is recomputed over the canonicalized, enveloped-signature-transformed referenced element and compared; a tampered `NameID` (with otherwise well-formed signature) is rejected.
  3. A response signed by the wrong key, or whose digest does not match, is rejected with a typed error naming the failed check — while a genuinely-signed positive control returns `{:ok, %SignedNode{}}`.
  4. `verify_metadata_root/4` uses the same signature-math primitive on `EntityDescriptor`/`EntitiesDescriptor`, with operator-pinned `TrustAnchor` fingerprint pinning preserved as defense-in-depth (signature math, not pinning alone).

**Plans**: 5 plans

  - [x] 29-01-PLAN.md — Mixed-content C14N Option-a fix (ordered content field + document-order render) + new Docker-minted golden (D-09/D-10)
  - [x] 29-02-PLAN.md — pure_beam D-02 field extraction (SignedInfo / DigestValue / SignatureValue) + AlgorithmPolicy URI→digest-atom & ECDSA fail-closed (D-06/D-07)
  - [x] 29-03-PLAN.md — Wire :public_key.verify + DigestValue recompute/compare into the do_verify [candidate] arm; new error atoms; crypto negative controls (D-01/D-03/D-04/D-05/D-08)
  - [x] 29-04-PLAN.md — Genuine XMLDSig signer (D-11) + assertion positive control + wrong-key/tampered-NameID negatives
  - [x] 29-05-PLAN.md — SIGV-04 metadata-root plumbing upgrade (tree-bound candidate) + metadata positive control + pinning defense-in-depth negative (D-13)

#### Phase 30: Adversarial crypto assurance

**Goal**: The proof that verification is real lives permanently in-repo and gates every build.
**Depends on**: Phase 29 (corpus must run against real verification).
**Requirements**: ASSUR-01, ASSUR-02
**Success Criteria** (what must be TRUE):

  1. `Relyra.TestSupport.FakeIdP` performs **real cryptographic XMLDSig signing** with its generated keypair (emits a real `DigestValue` + `SignatureValue`), so the suite exercises real verification rather than structure-only acceptance.
  2. A permanent adversarial corpus proves rejection of forged-signature-with-valid-structure, tampered-content (same signature), wrong-key, digest-mismatch, and canonicalization-differential responses — each asserting `{:error, %Relyra.Error{}}`.
  3. A positive control proves a genuinely FakeIdP-signed response verifies as `{:ok}`.
  4. The corpus is wired into `corpus_gate` and the conformance manifest and is green under `mix ci.security` (no skipped/pending crypto assertions).

**Plans**: TBD

#### Phase 31: Disclosure and docs honesty

**Goal**: The shipped story matches the code, and a coordinated advisory is staged for the fixed release.
**Depends on**: Phase 30 (advisory text describes a fix proven by the corpus).
**Requirements**: DISC-01, DISC-02
**Success Criteria** (what must be TRUE):

  1. `docs/security_boundary.md`, `SECURITY_REVIEW.md`, and `docs/security_findings.md` are corrected to describe the **actual** verification guarantee (no overstatement), and `mix ci.security` doc checks stay green.
  2. The finding is recorded in the findings ledger with a disposition (confirmed → fixed in v1.1 / hex 1.2.0).
  3. A GHSA draft + requested CVE + CHANGELOG security note are prepared, marking hex `1.0.0`/`1.1.0` as affected, staged for publication at the fixed release (fix-first: not published before the fix ships).

**Plans**: TBD
