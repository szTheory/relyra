# Relyra: "Are we done?" — Strategic Assessment + Reordered Roadmap

## Context

You asked whether Relyra is "basically done" (another LLM scored it 93/done for SP scope),
what the highest-impact next milestone is, and where the diminishing-returns line sits — with
a mandate to research deeply and one-shot a coherent recommendation.

I researched three layers: your own `prompts/` + JTBD docs, the **actual implemented code**, and
cross-ecosystem lessons (your `prompts/elixir-saml-lib-deep-research.md` already had most of the
latter). The headline is not what the score suggested.

**The SP happy path runs, and the security *scaffolding* around it is genuinely excellent
(XSW defenses, KeyInfo rejection, duplicate-ID rejection, algorithm allowlisting, replay,
hardened XML boundary, telemetry, audit, conformance harness). But the cryptographic heart of
SAML — actually verifying the signature — is missing.** Everything else (advanced federation,
adoption docs) is real and worth doing, but it comes *after* the foundation is made true.

---

## 🔴 P0 FINDING — Signature verification is not cryptographic (likely auth bypass)

**Evidence (code inspection, high confidence — confirm empirically as Step 1 below):**
- `lib/relyra/security/signature.ex` `do_verify/4` requires `cert_chain != []` but **never uses
  the certificate cryptographically**. It checks: KeyInfo-trust rejection, duplicate XML IDs,
  algorithm-string allowlist, and "exactly one signed candidate" — then returns a `SignedNode`.
- **No `:public_key.verify` / `:crypto.verify` exists anywhere in `lib/`** (only PEM decode and
  test-IdP key *generation*). The `SignatureValue` bytes are never checked against the IdP key.
- The referenced node's `DigestValue` is never recomputed/compared. `canonicalize/2`
  (`normalize_signed_xml`) is a passthrough and isn't called in the verify path.
- The adversarial corpus exercises structural attacks only (wrapping/unsigned/parser-diff/dup-ID/
  XXE/KeyInfo). **No fixture asserts that a valid-structure + forged-signature + tampered-content
  response is rejected.** That gap is why CI is green without real crypto.

**Impact:** An attacker who can craft a well-formed `<Response>` with a single, structurally-valid
`<Signature>` (allowlisted algorithm, no dup IDs, no document KeyInfo) and arbitrary assertion
contents (any NameID/email) would be **accepted as that user, on any connection**. This makes the
project's north star — *"every SAML login ends in a verified trust path… never a silent
compromise"* — currently false. Metadata-root verification uses the same primitive; its integrity
currently rests on SHA-256 fingerprint-pinning (`TrustAnchor.check`), not signature math.

**Why it was missed:** Phase 26 ("Security Audit Preparation and Remediation") produced a reviewer
*packet* (`SECURITY_REVIEW.md`) with **no external findings recorded** — i.e. no external auditor
appears to have actually run a forged-signature test. A real external review would catch this in
minutes. The discipline gates are so well-built they create a convincing illusion of verification.

**Confidence & honesty:** I'm highly confident from reading the full `do_verify` path, but I did
not execute code (plan mode). Step 1 of execution is a 30-minute empirical confirmation before any
disclosure action.

---

## Revised answer to "are we driving toward done?"

- **No — not yet.** The "93/done" score measured surface area, not foundation. The SP path
  *succeeds* on valid logins but also *accepts forged ones*. That's a correctness/security hole, not
  a polish gap.
- **The good news:** the expensive, hard-to-retrofit scaffolding (hardened parser, XSW discipline,
  trust-anchor pinning, replay, algorithm policy, the whole behaviour/store architecture, admin UI,
  telemetry, conformance harness) is already built and high quality. Dropping real XMLDSig crypto
  into the existing `do_verify` seam is **tractable** — the seam, the cert chain, the algorithm
  policy, and the signed-node selection are all already there waiting for the actual math.
- **Then** the previously-planned "v2 advanced federation" (encrypted assertions, full SLO, signed
  AuthnRequests) plus the adoption-docs polish your JTBD map identified are the right next steps —
  and they were *correctly* deferred to v2 in your own research. Note: **encrypted assertions
  literally cannot be done safely until real verify exists** (the design is decrypt→verify), so the
  ordering below is forced, not arbitrary.

---

## Recommended program (reordered)

### Release A — "Verify the trust path, for real" (URGENT security release, ship alone first)

The foundation. Ship as its own release **ahead of** any feature work, with a security advisory.

1. **Confirm empirically (Step 1):** add a throwaway test — valid-structure response, single
   signature, allowlisted algo, no dup IDs, *forged SignatureValue + tampered NameID* — and assert
   the **current** code accepts it. This converts "high confidence" into proof and sizes the blast
   radius.
2. **Implement real XMLDSig verification** inside the existing `do_verify` seam:
   - Exclusive XML Canonicalization (C14N 1.0 exclusive — the SAML default). **This is the genuinely
     hard part** the project deferred; it forces the pure-BEAM-vs-native-xmlsec ADR flagged in
     `prompts/elixir-saml-lib-deep-research.md:1359`. Decide it here.
   - `:public_key.verify(canonical_signed_info, digest_alg, signature_value, idp_public_key)` against
     the **configured** cert chain (the chain `do_verify` already demands but ignores).
   - Recompute the referenced element's digest after C14N + enveloped-signature transform; compare to
     `DigestValue`. Bind to the same single verified node (preserve existing XSW discipline).
   - Apply identically to `verify_metadata_root` (metadata trust becomes signature + fingerprint, not
     fingerprint alone).
3. **Adversarial corpus for crypto** (the missing half): forged-signature/valid-structure,
   wrong-key, tampered-content-same-signature, digest-mismatch, C14N-differential, enveloped-
   transform edge cases — all asserting **rejection**. Wire into `corpus_gate` + conformance manifest.
4. **Disclosure** (see escalation below): GHSA + CVE, CHANGELOG security note, advise/yank affected
   hex versions (1.0.0, 1.1.0). Correct `docs/security_boundary.md` to match reality.
5. **Fix the overstatement:** update `SECURITY_REVIEW.md` scope/claims; record this in
   `docs/security_findings.md`.

**Files:** `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex` (real C14N +
digest), `lib/relyra/security/algorithm_policy.ex` (already correct), `priv/security_corpus.json`,
`CONFORMANCE.md`, `docs/security_boundary.md`, `SECURITY_REVIEW.md`, `docs/security_findings.md`.
**Risk:** HIGH (crypto + C14N correctness). This is the whole ballgame; do it first, review hardest.

---

### Release B — "Advanced Federation" (the planned v2 capabilities) → ship as **v1.2.0 (minor)**

All additive/backward-compatible (strict defaults unchanged, new config opt-in) → SemVer minor,
themed "Advanced Federation." Do **not** bump 2.0.0 (lies to resolvers; spends the major budget with
nothing breaking). Detailed designs were produced by sub-agents and are summarized here.

**B1 — Encrypted assertions (EncryptedAssertion / XML-Enc).** *Depends on Release A.*
- Pure-BEAM: `:public_key` RSA-OAEP key transport + `:crypto` AES-GCM. **Default-reject RSA-1.5
  (Bleichenbacher) and AES-CBC (Jager–Somorovsky padding oracle); GCM + OAEP only**, enforced via an
  extended `AlgorithmPolicy` (same time-boxed override mechanism as SHA-1).
- Pipeline: decrypt → **re-feed plaintext through the SAME hardened parser** → existing `verify`
  (now real) → protocol-validate. Never read a field from a decrypted-but-unverified assertion;
  reject "both cleartext and encrypted assertion present"; single generic `:decryption_failed` (no
  padding oracle in the error taxonomy).
- SP private decryption key via a `KeyResolver` behaviour (config-PEM default + KMS hook); never the
  raw private key in the DB. Extend cert inventory with `party:`/`use:` (the largest mechanical
  surface — key-confusion blast radius; isolate in its own plan). Publish SP encryption
  `KeyDescriptor` in metadata.
- ~4 plans: (a) algorithm policy + crypto core, (b) key mgmt + schema, (c) pipeline integration +
  re-parse, (d) adversarial corpus + metadata + conformance flip.

**B2 — Complete Single Logout (today's SLO is outbound-build only, ~40%).**
- SP-initiated round trip (build LogoutRequest → top-level redirect → consume LogoutResponse →
  terminate session) **and** IdP-initiated (consume inbound LogoutRequest → verify → terminate →
  return LogoutResponse). Redirect + POST bindings.
- **Route logout messages through the SAME hardened parser** (extend the `<Response>`-only root gate
  with a `message_type` dispatch — do NOT fork the parser; PITFALLS Pitfall 2/XSW).
- **SessionIndex correlation** (the hard part): extend `SessionAdapter` with `index_session/4` (at
  login) + `terminate_by_session_index/4` (at logout); storage-agnostic with an Ecto reference
  adapter for clusters. Reuse `ReplayStore` for InResponseTo correlation + LogoutResponse replay.
- **Top-level redirects only** (2026 3rd-party-cookie blocking orphans iframe SLO); document
  mandatory absolute session timeouts as the honest backstop. Explicitly do **not** promise
  back-channel/SOAP SLO or multi-SP propagation (state the boundary like passport-saml).
- ~5 plans: schema+parser boundary; LogoutResponse builder + logout pipeline; SessionIndex
  correlation; public API + Phoenix controllers/routes; corpus.

**B3 — Signed AuthnRequests (for IdPs setting `WantAuthnRequestsSigned`: ADFS, Shibboleth).**
- Needs a new SP signing primitive (`Signature.sign_*`, reusing `AlgorithmPolicy`) and an SP private
  key (recommend runtime-injected `sp_signing_key:` for v1.2 over DB storage — keeps secrets out of a
  schema/diagnostic surface hardened around public material).
- **Ship HTTP-Redirect signing first** (detached signature over the exact `SAMLRequest&RelayState&
  SigAlg` octet string — sign/verify raw sender octets, never a re-serialized map; this is the
  CVE-class footgun). Defer POST enveloped signing (needs the C14N from Release A).
- Per-connection `sign_authn_requests` toggle; publish SP signing `KeyDescriptor` + SLO endpoints in
  metadata.

---

### Release C — Adoption / DX / docs (interleaved with B, each guide lands after its capability)

From your JTBD gap map, in priority order:
- **D1 (highest):** `guides/recipes/generic_saml.md` (first-class peer of okta.md) +
  `guides/minimum_safe_checklist.md` — with a per-vendor "field-name decoder" table. Turns custom
  IdPs (Ping/ADFS/Shibboleth/Keycloak/OneLogin/internal) from "you own the synthesis" back to
  "guided." This is the substitute for more presets.
- **D2:** `guides/identity_mapping_and_provisioning.md` — NameID vs app identity, required attrs,
  account linking, group→role posture, JIT decision tree, explicit SCIM non-goal.
- **D3:** `guides/recipes/logout.md` — **lands right after B2** (can't be honest before SLO is real):
  when to enable SLO, session-model implications, 3rd-party-cookie caveat, absolute-timeout guidance.
- **D4:** `guides/operations/incident_playbook.md` — one table stitching telemetry → audit → admin
  UI → mix task into a "something drifted, now what" narrative.
- **D5:** `guides/troubleshooting.md` — SAML-error decoder (one row per error atom, drift-checked).

**DX & demo:**
- **Demo:** ship `dev/relyra_demo.exs` (single-file playground wired to FakeIdP) + `examples/
  quickstart.exs` (`Mix.install` headless round trip), CI-compiled via a new `ci.demo` alias so it
  can't rot. **Not** a full `examples/phoenix_saml_demo` app (highest maintenance, re-proves existing
  tests). Mirrors LiveDashboard/Oban Web/LiveView norms.
- **Connection-test stepwise UX** (✓ decoded → ✓ verified signature → … → "Would sign in user: x")
  as a FakeIdP-scoped admin LiveView this milestone — the brand-defining moment, now meaningful
  because verify is real.
- **Installer fixes:** fix the stale `~> 0.1.0` pin in getting_started; add a "choose your storage
  posture" (ETS-single-node warning) callout; auto-wire the router when `--router` is passed;
  scaffold a session adapter with `establish_session/3` + `revoke_session/4`.

---

## Diminishing-returns line (deliberately OUT — state honestly in CONFORMANCE.md)

Keep out unless real adopter demand: HTTP-Artifact binding, ECP, Attribute Query, SCIM-in-core, more
provider presets beyond the three (D1 generic runbook is the substitute), a full standalone demo app,
and full customer-admin synthetic-login self-service. Add a "Scope boundary & diminishing returns"
section to CONFORMANCE.md marking these as deliberate-not-missing. **Once Release A + B + C land, you
are genuinely at "done enough"; further work is demand-gated, not coverage-gated.**

---

## Sequencing & versioning

1. **Release A** → urgent security release (e.g. **1.2.0** as a security fix, or 1.1.1 if you prefer
   patch semantics) + GHSA/CVE. Ship before anything else.
2. **Release B + C** → **v1.2.0 "Advanced Federation"** (or 1.3.0 if A took the 1.2.0 slot).
   Phase order: A → [B3 signed-requests ‖ B1 encryption ‖ B2 SLO can parallelize after A] →
   D-guides each immediately after their capability → connection-test LiveView + incident playbook →
   close (version bump, CHANGELOG, README/ROADMAP/jtbd_gap_map refresh, CONFORMANCE scope section).

---

## "Shift-left in GSD" (durable, so I stop asking on settled calls)

Encode your recommendation-first posture in three cheap layers:
1. **Config:** confirm/lock `.planning/config.json` `research_before_questions: true` +
   `discuss_mode: "assumptions"` (already set); adopt an even-quieter mode if GSD exposes one.
2. **Create `CLAUDE.md`** at repo root (none exists) with a "decision posture" section: default to a
   single deeply-researched recommendation; state assumptions and proceed; escalate ONLY
   high-blast-radius decisions (public API shape, default-tightening, security posture, real majors).
   Survives GSD upgrades; read by non-GSD tooling too.
3. **Auto-memory:** one line reinforcing the same (complements existing
   `feedback_recommendation_first`).
Each future phase opens with a 2–4 line "Assumptions & chosen approach" block instead of a question
list.

---

## Verification (how we'll know each release is real)

- **Release A:** the forged-signature/tampered-content fixture flips from ACCEPTED→REJECTED; a
  positive control (FakeIdP real-key signed response) still verifies; wrong-key fixture rejected;
  C14N-differential fixtures rejected; `mix ci.security` green with the new crypto corpus.
- **B1:** OAEP+GCM round-trips and the recovered signed assertion verifies; RSA-1.5/CBC rejected;
  padding-oracle probe yields one opaque error; encrypted-then-XSW rejected.
- **B2:** SP-initiated round trip terminates the session; forged/unsigned LogoutRequest rejected;
  replayed LogoutResponse rejected; IdP-initiated logout terminates the correlated SessionIndex.
- **B3:** golden redirect-binding signed query verifies bit-for-bit; ADFS-style differing encoding
  handled via raw octets.
- **C:** `ci.demo` compiles the playground + runs the headless quickstart asserting the stepwise
  trace; troubleshooting/error-atom drift check green.

---

## ⚠ One escalation for you (the only VERY-impactful fork)

**Security disclosure posture for the signature finding.** Relyra is published on hex.pm (1.0.0,
1.1.0). My recommendation: (1) confirm empirically, (2) fix in a private branch, (3) file a GHSA +
request a CVE, (4) release the fix, (5) publish the advisory and mark 1.0.0/1.1.0 as
affected/retired. But the aggressiveness (coordinated GHSA+CVE+yank vs. a quiet fix given likely
near-zero production adopters today) is your call — I'll proceed per your direction at approval.

---

## Follow-ups I'll make after approval (cannot during plan mode)
- Write the auto-memory entry for the P0 finding + the shift-left posture.
- If you want this as a GSD milestone, route through `/gsd:new-milestone` (Release A first) — this
  plan is the input.
