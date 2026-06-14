# Phase 57: Demo FakeIdP Browser-Login Proof - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning
**Source:** Orchestrator synthesis (investigation this session — no interactive discuss-phase)
**Mode:** mvp

<domain>
## Phase Boundary

Deliver a real, in-browser SSO login round-trip for the LedgerLoop demo app
(`demo/ledger_loop`) driven by a **demo-local fake IdP**, so an evaluator clicks
"Log in with SSO", is bounced to a built-in IdP page, and lands back logged in —
with Relyra having **cryptographically verified** a genuinely-signed SAML
assertion against the demo connection's configured IdP certificate. A failure
variant produces a **tampered** signature that Relyra rejects with a typed error,
surfaced in the existing trace UI.

In scope: demo-local SAML-response signer + keypair, fixture cert alignment,
`/fake_idp/login` + `/fake_idp/sso` routes wired into the demo router, success +
tampered variants, in-process tests.

Out of scope: any change to relyra's published API or packaging; real/external
IdP; hosted broker; Wallaby/real-browser tooling; new CI lanes.
</domain>

<decisions>
## Implementation Decisions (LOCKED)

### Approach — option (b), demo-local signer
- The signer lives **inside `demo/ledger_loop`** with its own demo IdP keypair.
  Relyra's `Relyra.TestSupport.FakeIdP` / `xmldsig_signer` are **off-limits at
  runtime** — relyra's `prod_elixirc_paths()` strips everything under
  `test_support`, and path deps compile in `:prod`, so the demo cannot reference
  them. (Verified this session: the parked WIP on branch `wip/demo-fake-idp`
  fails precisely because it calls `Relyra.TestSupport.FakeIdP.sign/1`.)

### Trust posture — DO NOT relax (escalation fence)
- Do **NOT** expose `Relyra.TestSupport.FakeIdP` (or any signing helper) outside
  `:test`. That is the SEED-002 packaging / "public FakeIdP" security-posture
  escalation and is explicitly OUT OF SCOPE. Keep relyra's `prod_elixirc_paths`
  `test_support` exclusion intact. Relyra's verifier must stay strict — the demo
  earns a real verification, it does not weaken the gate.

### Cert-trust alignment — THE CRUX
- The demo's enabled connection fixture (`LedgerLoop.Demo.Fixtures`, scenario
  `01H0B4Y1A2B3C4D5E6F7G8H9J0`) currently stores `pem: "MOCK_PEM_NOT_REAL"` for
  its `:signing` IdP cert (`fixtures.ex:100-140`). For verification to pass, the
  fixture must store the **real self-signed cert** whose **private key** the
  demo-local signer uses. One keypair, two sides: private key signs in
  `/fake_idp/sso`; matching cert is the connection's trusted IdP signing cert.
- The demo IdP keypair + cert are demo-only secrets and may be committed into
  `demo/ledger_loop/priv/` (no real-world trust). They must be generated
  deterministically/once and checked in (mirrors how relyra's test keypair works).

### Routes & flow
- Wire `GET /fake_idp/login` (renders the local-test-support IdP form, passes
  through `RelayState`) and `POST /fake_idp/sso` (emits a self-submitting POST
  form to the SP ACS with `SAMLResponse` + `RelayState`).
- The parked WIP controller/templates on `wip/demo-fake-idp` are a starting
  point; replace the `Relyra.TestSupport.FakeIdP.sign/1` call with the new
  demo-local signer. Reuse the existing demo SP ACS endpoint + connection context;
  the existing `RouteAffordanceController` "Log in with SSO" affordance should
  point at `/fake_idp/login`.
- Success variant: valid signed assertion → Relyra verifies → host session
  established (existing SessionAdapter / login-receipt path).
- Failure variant: tamper the signed XML (e.g. mutate a byte after signing) →
  Relyra typed rejection → surfaced in the trace UI at
  `/relyra/admin/connections/:id/trace`.

### Testing & CI
- In-process only: `Phoenix.ConnTest` + `Phoenix.LiveViewTest` (no Wallaby).
- Rides the existing `demo-app-ci.yml` → `mix ci.demo_app` lane. **No new CI.**
- Demo suite must stay green (currently 37/0). Keep relyra's full `mix qa` /
  `mix ci.security` gates untouched and green.

### Marker for the "Local Test Support" banner
- The fake IdP pages must visibly announce they are a local testing harness
  (copy: "Local Test Support / FakeIdP", "This is a local testing harness") —
  matches the parked WIP test expectations and avoids any impression of a real IdP.

### Claude's Discretion
- Exact XML-DSIG construction for the demo signer: hand-roll with `:public_key`
  + exclusive C14N matching what relyra's verifier requires, **OR** vendor a
  demo-local copy of relyra's `xmldsig_signer` approach into `demo/ledger_loop`
  (a copy is not "exposing relyra's API"). Research should pick the lowest-risk
  path that the relyra SP verifier accepts byte-for-byte.
- Keypair generation mechanism (mix task vs committed PEM vs `mint_signing_key.exs`
  analog) and where the cert PEM is threaded into Fixtures.
- Module names/locations within `demo/ledger_loop`.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Relyra signing reference (read-only — DO NOT import at runtime)
- `lib/relyra/test_support/xmldsig_signer.ex` — RSA-SHA256 + SHA256 digest +
  exclusive-C14N signing that relyra's own verifier round-trips against. The
  authoritative reference for what the demo signer must produce.
- `lib/relyra/test_support/fake_idp.ex` — response builder + `keypair()` shape;
  reference for assertion structure, not for runtime use.

### Relyra verifier (the gate the demo must satisfy)
- `lib/relyra/security/signature.ex` — `do_verify/4`, the single crypto gate.
- `lib/relyra/security/xml/c14n.ex` — exclusive C14N the digest must match.
- `lib/relyra/security/algorithm_policy.ex` — allowed signature/digest algorithms.

### Demo app integration points
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — `relyra_certificates/0`
  (the `MOCK_PEM_NOT_REAL` to replace) + enabled connection scenario `…J0`.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` — where `/fake_idp/*` routes
  attach; existing `/auth/saml/acs` ACS + LiveAdmin mount.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex`
  — existing login affordance to repoint at `/fake_idp/login`.
- Parked WIP: branch `wip/demo-fake-idp` (`fake_idp_controller.ex`,
  `fake_idp_html.ex`, `fake_idp_html/{login,sso}.html.heex`, controller test).
</canonical_refs>

<specifics>
## Specific Ideas

- Recover the parked WIP with: `git checkout wip/demo-fake-idp -- demo/ledger_loop/...`
- Tampered-variant technique from the WIP: sign a valid response, base64-decode,
  mutate (e.g. `<Issuer` → `<IssuerTampered`), re-encode — guarantees a signature
  break Relyra must catch.
- Hardened Phase-53 tests already assert `/fake_idp/*` adjacent flows; keep them green.
</specifics>

<deferred>
## Deferred Ideas

- Public/supported demo-signing API in relyra (option a) — escalation, deferred to
  a deliberate SEED-002 decision.
- Keycloak / external real-IdP browser proof — already optional, separate track.
</deferred>

---

*Phase: 57-demo-fakeidp-browser-login-proof*
*Context synthesized: 2026-06-13*
