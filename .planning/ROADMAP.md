# Roadmap: Relyra

## Overview

Relyra is a strict-by-default SAML 2.0 Service Provider library for
Elixir/Phoenix. The v1.x arc is shipped through **v1.11 — First-Adopter Twin**.
The active milestone is **v1.12 — Trust-Path Hardening**. It closes every place
where consumed SAML data, or the signature's own structure, is not bound to the
cryptographically verified node. It then tests the trust core with property-based
and mutation testing until each technique reaches a measured point of
diminishing returns. Fixes fail forward on `main` as `fix(...)` commits, and
disclosure is scripted at close-out.

## Milestones

- Complete: **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- Complete: **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- Complete: **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- Complete: **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- Complete: **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- Complete: **v0.6 — Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- Complete: **v1.0 — Security review, conformance, and onboarding** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- Complete: **v1.1 — Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- Complete: **v1.3 — Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- Complete: **v1.4 — Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- Complete: **v1.5 — Publish, Prove, Polish** (shipped 2026-05-27). See `.planning/milestones/v1.5-ROADMAP.md`.
- Complete: **v1.6 — Adoption Truth** (shipped 2026-05-28). See `.planning/milestones/v1.6-ROADMAP.md`.
- Complete: **v1.7 — Adoption Evidence Demo** (shipped 2026-06-13). See `.planning/milestones/v1.7-ROADMAP.md`.
- Complete: **v1.8 — Brand System & Identity** (shipped 2026-06-14). See `.planning/milestones/v1.8-ROADMAP.md`.
- Complete: **v1.9 — Loose Ends & Adoption Honesty** (shipped 2026-06-19). See `.planning/milestones/v1.9-ROADMAP.md`.
- Complete: **v1.10 — Docker DX & Fleet Proxy** (shipped 2026-08-27). See `.planning/milestones/v1.10-ROADMAP.md`.
- Complete: **v1.11 — First-Adopter Twin** (shipped 2026-10-19). See `.planning/milestones/v1.11-ROADMAP.md`.
- In progress: **v1.12 — Trust-Path Hardening** (Phases 80–84, started 2026-10-19). See the active milestone section below.

v1.11 is archived with 7/7 phases (73–79) verified and 78/78 plans terminal.
Phase 79 closed on live evidence from the same main SHA: green CI on `ed2d2cf1`,
protection matching `ci-gate`, and the approved remote batch read back.

Unlike earlier milestones, the v1.11 phase directories stay in `.planning/phases/`.
The executable governance and evidence contracts in `mix qa` and `mix ci.evidence`
read them in place. The frozen planning record they validate is
`.planning/milestones/v1.11-{PROJECT,ROADMAP,REQUIREMENTS,STATE}.md`.

## v1.12 — Trust-Path Hardening (In Progress)

**Goal:** Every consumed SAML value comes from the exact node that was
cryptographically verified, on every trust path (login, logout POST,
HTTP-Redirect, encrypted assertion, metadata). Property-based and mutation
testing then run until each reaches its stopping rule, and what remains is
recorded as residual risk.

**Seam inventory:** S1–S20 in `.planning/research/SUMMARY.md` § Seam Inventory.

**Milestone constraints:**
- Security invariants are strengthened, never relaxed. Retiring the metadata regex restores invariant #2 (one parse path).
- No public function or behaviour signature change. New `%Relyra.Error{}` types are additive.
- Every fixed seam gets at least one permanent corpus row that goes through the public API.
- Every new security suite is its own `cmd mix test` line in `mix ci.security`, with `ci_gate_integrity_test.exs` updated (no hollow gates).
- Mutation runs and deep property runs never run in `ci-gate`. Only bounded, seeded properties and the frozen corpus rows gate merges.
- FakeIdP, `Relyra.Testing`, and the Keycloak lanes stay green. Response-only signatures (S5) stay fail-closed.
- One evidence file for the milestone, with no new receipt chains.

## Phases

- [ ] **Phase 80: Seal the login trust path** - Every login field comes from the single signed, structurally bound `<Assertion>`
- [ ] **Phase 81: Seal logout, redirect, encrypted, and metadata paths** - Every non-login trust path consumes only data from the verified node
- [ ] **Phase 82: Property-based adversarial twin** - StreamData mutations over genuinely signed inputs prove the trust-path invariant until two empty rounds
- [ ] **Phase 83: Mutation testing of the security core** - A scheduled mutare lane measures test sharpness until the score plateaus
- [ ] **Phase 84: Close-out and scripted disclosure** - One evidence file, an advisory doc, and a scripted GHSA/CVE request

## Phase Details

### Phase 80: Seal the login trust path
**Goal**: An adopter calling `Relyra.consume_response/3` gets either identity data taken only from the single signed, structurally bound `<Assertion>`, or a typed rejection. No field, signature part, or algorithm is read from anywhere else in the document.
**Depends on**: Nothing (first phase of v1.12; builds on the v1.1 crypto gate)
**Requirements**: BIND-01, BIND-02, BIND-03, BIND-04, BIND-05, BIND-06, BIND-07, BIND-08
**Seams**: S1–S4, S6–S11, S20 (regression rows kept for S5, S12, S19)
**Success Criteria** (what must be TRUE):
  1. A genuinely signed Response with NameID, Conditions, Audience, AttributeStatement, SessionIndex, or a second or ID-less Assertion injected outside the signed `<Assertion>` returns `{:error, %Relyra.Error{}}` with a typed reason, or ignores the injected value. It never returns `{:ok, _}` carrying attacker values. A new `trust_binding` corpus suite in `mix ci.security` proves this through the public API, and it covers the reproduced S6/S7 live-probe cases.
  2. Signature-structure attacks are rejected with typed errors by corpus rows in the same suite. These cover: a replayed SignedInfo/SignatureValue with a DigestValue in `<ds:Object>`; a Reference URI not equal to `"#" <> Assertion ID`; more than one Reference; a non-enveloped or non-direct-child Signature; a foreign-namespace lookalike element; a document-wide SignatureMethod/DigestMethod decoy; a non-allowlisted CanonicalizationMethod; and a non-`samlp:Response` root.
  3. Protocol-binding attacks are rejected with typed errors by corpus rows. These cover: an Assertion Issuer that differs from the Response Issuer or the configured IdP; a nested StatusCode decoy; a non-bearer SubjectConfirmation; and a `SubjectConfirmationData@InResponseTo` mismatch when `InResponseTo` is required. A unit row also proves `bind_signed_node/2` rejects a consumed node that differs from the verified node.
  4. Existing evidence stays green with no test weakened: `adversarial_crypto_test.exs`, the FakeIdP and `Relyra.Testing` success fixtures, the conformance manifest, the Keycloak lane, and `ci_gate_integrity_test.exs` (updated to list the new suite). `consume_response/3` and the behaviour callback signatures are unchanged, and any new error types appear in the troubleshooting decoder, enforced by the existing drift test.
**Plans**: TBD

### Phase 81: Seal logout, redirect, encrypted, and metadata paths
**Goal**: The logout POST, logout HTTP-Redirect, encrypted-assertion, and metadata paths each consume only data derived from the node that was verified, through the single Saxy parse path.
**Depends on**: Phase 80 (reuses the namespace-aware direct-child helpers and binding primitives)
**Requirements**: PATH-01, PATH-02, PATH-03, PATH-04, PATH-05
**Seams**: S13–S18
**Success Criteria** (what must be TRUE):
  1. A POST LogoutRequest or LogoutResponse is accepted only with an enveloped signature on its own root whose Reference URI equals the root ID. Corpus rows in `mix ci.security` show typed rejection for: a logout whose only signature is on an embedded Assertion; a root that only contains the right substring; a wrong Destination; and a replay of the same ID under another connection, which is keyed separately.
  2. An HTTP-Redirect logout with a duplicated `SAMLRequest`, `SAMLResponse`, `RelayState`, `SigAlg`, or `Signature` query parameter gets a typed rejection. A corpus row proves that the verified octets are rebuilt from exactly the processed parameters.
  3. Encrypted-assertion corpus rows show typed rejection for: a decoy EncryptedAssertion hidden in a comment, PI, or CDATA; plaintext that is not exactly one `saml:Assertion`; and plaintext that adds ambiguity after the re-parse. The genuine ENC-01 corpus still accepts.
  4. Metadata entityID, SSO endpoints, signing certs, and validUntil come from the verified SaxyTree root. Corpus rows show that values placed in comments, unsigned wrappers, or KeyInfo are never imported. The regex extraction in `metadata/parser.ex` and `auto_refresh.ex` is gone, as a source-level guard test enforces, and the existing AutoRefresh pinning and staged-rollover tests stay green.
**Plans**: TBD

### Phase 82: Property-based adversarial twin
**Goal**: Mutated variants of genuinely signed SAML documents either produce exactly the values the generator signed or a typed rejection. Every counterexample becomes a permanent corpus row, and the technique stops after two consecutive deep rounds that find no new defect class.
**Depends on**: Phase 80, Phase 81
**Requirements**: PROP-01, PROP-02, PROP-03, PROP-04, PROP-05
**Success Criteria** (what must be TRUE):
  1. The twin signer mints genuinely signed Responses, LogoutRequests, and metadata documents. It supports both sign-then-mutate and mutate-then-resign, and a self-test shows an unmutated twin document is accepted by the public API.
  2. StreamData generators produce shrinkable op lists across every listed mutation family: wrap, move, or duplicate; envelope injection; namespace rebinding; comment, PI, and CDATA; whitespace and encoding; duplicate IDs; time boundaries; and truncation and size. A generator coverage test asserts that each family is reachable. Shrinking acts on the op list, not on raw bytes.
  3. The oracle compares consumed values against what the generator signed, never against Relyra's own parse. It fails the property on any `{:ok, _}` mismatch, a non-allowlisted error type, a raise, an exit, a timeout, or a heap blowup. A seeded meta-test with a deliberately planted binding bug proves the oracle catches it.
  4. A bounded, seeded property suite runs as its own `cmd mix test` line in `mix ci.security`, listed in `ci_gate_integrity_test.exs`. A scheduled deep-run workflow outside `ci-gate` prints its seed and fails visibly when it finds a counterexample.
  5. Every shrunk counterexample from the deep rounds is a named, permanent corpus row in `ci.security`. The round log in the milestone evidence file shows two consecutive deep rounds with no new defect class.
**Plans**: TBD

### Phase 83: Mutation testing of the security core
**Goal**: A measured mutation score shows that the security-core tests detect broken checks. Survivors are killed with sharper tests or by fixing the slack they expose, until the score plateaus.
**Depends on**: Phase 80, Phase 81 (may run alongside Phase 82)
**Requirements**: MUT-01, MUT-02, MUT-03
**Success Criteria** (what must be TRUE):
  1. A scheduled and `workflow_dispatch` workflow runs mutare (exact-pinned, test/dev only) over the security core (`signature.ex`, `pure_beam.ex`, `c14n.ex`, `algorithm_policy.ex`, `validation_pipeline.ex`, the logout validators, and `metadata/parser.ex`). It uploads a JSON score report artifact. A test asserts the lane is absent from `ci-gate` and that each mutant runs in a fresh `mix test` process.
  2. Each round's survivors are either killed by a new or sharper test, fixed in source with a corpus row, or recorded as equivalent mutants with a documented ignore. A guard test shows that no row was removed from `adversarial_crypto_test.exs` or the corpus suites.
  3. The score trend across rounds is recorded in the milestone evidence file. It shows a plateau across two rounds, and every remaining survivor is listed as residual risk.
**Plans**: TBD

### Phase 84: Close-out and scripted disclosure
**Goal**: The hardening is recorded in one evidence file and disclosed through a scripted advisory that names the affected range, the fixed version, and the residual risk.
**Depends on**: Phase 82, Phase 83
**Requirements**: CLOSE-01, CLOSE-02
**Success Criteria** (what must be TRUE):
  1. One evidence file maps each seam S1–S20 to its fixing commit and named corpus row, or to its fail-closed or deferred disposition (S5, S12, S19). It also records the property rounds, the mutation score trend, and the residual risk. A mandatory-CI contract test fails if any seam lacks a disposition or a referenced corpus row does not exist.
  2. `docs/advisories/2026-002-*` names the affected version range and the fixed release version. A docs lint in mandatory CI checks that it matches the evidence file's seam list and the published version.
  3. The GHSA and CVE request script has a deterministic dry-run mode that prints the exact request batch, covered by a fixture test in mandatory CI. The live filing runs only after exact-batch approval, and it reads back the advisory state, with the result recorded in the evidence file.
**Plans**: TBD

## Progress

**Execution order:** 80 → 81 → (82 and 83 in parallel) → 84

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 80. Seal the login trust path | v1.12 | 0/TBD | Not started | - |
| 81. Seal logout, redirect, encrypted, and metadata paths | v1.12 | 0/TBD | Not started | - |
| 82. Property-based adversarial twin | v1.12 | 0/TBD | Not started | - |
| 83. Mutation testing of the security core | v1.12 | 0/TBD | Not started | - |
| 84. Close-out and scripted disclosure | v1.12 | 0/TBD | Not started | - |

## Demand-Gated Future Candidates

- **AUTHN-POST-01** — HTTP-POST binding signed AuthnRequests with enveloped XML signature and C14N. Waiting for real adopter demand.
- **KMS-01** — KMS-native `KeyResolver` adapters for AWS KMS or GCP KMS. Waiting for real adopter demand.
- **SIGNED-META-01** — Signed SP metadata plus federation extensions and an InCommon runbook. Waiting for real adopter demand.

Deferred from v1.12 to a later milestone: FID-01 (real-IdP fidelity corpus),
CHAOS-01 (chaos journeys), ADMIN-01 (customer-IT-admin journey), and
INTEROP-01 (Response-level signatures with strict binding, S5).

---
*Roadmap updated: 2026-10-19 — v1.12 Trust-Path Hardening roadmap created (Phases 80–84)*
