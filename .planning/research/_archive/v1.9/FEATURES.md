# Feature Research

**Domain:** Public SAML testing helpers and adoption-honesty maintenance
**Researched:** 2026-06-15
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Public Hex-shipped testing module | Docs currently teach a helper path that Hex users cannot load. | MEDIUM | Use `Relyra.Testing`, not `Relyra.TestSupport`, to distinguish curated API from private repo internals. |
| Genuine signed positive fixture | Adopters need to prove their Relyra ACS/session integration with a valid signed SAML response. | MEDIUM | Must still enter the real verifier path and use configured certs only. |
| Named negative fixtures | Adopters also need to test rejection handling, not only happy-path login. | MEDIUM | Start with safe representative failures: expired assertion, wrong audience, tampered digest/signature. |
| Explicit cert/key provenance | Test certs must be threaded only into test connections. | MEDIUM | Return cert chain alongside response; do not auto-install global trust. |
| Documentation truth | README, Getting Started, overview, recipes, and batteries-included docs must match package contents. | LOW | Current docs say `Relyra.TestSupport`; package excludes `test_support`. |
| Package parity proof | Release parity should prove private support stays excluded and public testing helpers ship. | LOW | Existing parity gate already checks `test_support` exclusion. Extend with allowlist/presence check. |
| Demo FakeIdP disposition | The demo should have one intentional browser login path. | LOW-MEDIUM | Current routes/tests exist; v1.9 should verify whether the flow is complete, document it, or remove stale alternate flow. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Rejection-path helper ergonomics | Aligns with Relyra's core value: typed rejection is as important as accepted login. | MEDIUM | Public helpers can expose selected negative fixtures without publishing the full adversarial corpus. |
| Phoenix optional case-template | Gives Phoenix SaaS adopters low-boilerplate proof tests. | MEDIUM | Should be layered over core fixtures and avoid making Phoenix mandatory. |
| Validation trace assertion helpers | Helps operators/adopters prove the trace names the rejection reason. | MEDIUM | Must stay tied to public, stable error atoms only. |
| Demo/docs cross-proof | The LedgerLoop demo can show the same testing story in a browser and in test code. | MEDIUM | Useful if the FakeIdP browser flow is retained. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Ship current `Relyra.TestSupport` wholesale | Fastest way to make docs compile for Hex users. | Ships private internals and repo-only fixtures; weakens TD-02's package boundary. | Curate `Relyra.Testing` with a small supportable contract. |
| Public full FakeIdP product | Looks like a complete local IdP. | Crosses the product-IdP non-goal and invites production misuse. | Test-only fixture builder plus optional demo harness. |
| Public adversarial corpus | Sounds transparent. | Teaches implementation-specific bypass fixtures and couples consumers to security internals. | Public representative negative fixtures; private corpus remains CI gate. |
| Static canned private key | Makes examples deterministic. | Known key can leak into prod trust config. | Ephemeral keypair by default, optional explicit fixture seed only if phase review accepts it. |
| Protocol feature cleanup in same milestone | Tempting while touching SAML fixtures. | Reopens demand-gated `AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01`. | Keep protocol candidates parked until adopter demand. |

## Feature Dependencies

```text
Relyra.Testing API decision
    -> package allowlist update
    -> docs migration from TestSupport to Testing
    -> parity/adoption proof

Core fixture builder
    -> selected negative fixtures
    -> optional Phoenix helper

Demo FakeIdP verification
    -> docs decide one login path
    -> seed cleanup

Maintenance sync
    -> roadmap hygiene
    -> release/advisory notes
```

### Dependency Notes

- **Docs require API/package decision:** Do not rewrite Getting Started until the public API name and shipped files are real enough to test.
- **Phoenix helper requires core fixture builder:** Keep Phoenix ergonomics thin and use core-generated SAML inputs.
- **Negative fixtures require security review:** Public fixture names and failure modes should be useful without disclosing the private adversarial matrix.
- **Demo cleanup requires current-state verification:** SEED-003 is no longer exactly accurate because `/fake_idp/*` routes and tests exist in the tree.

## MVP Definition

### Launch With (v1.9)

- [ ] `Relyra.Testing` public module exists or a phase-level API decision narrows the public surface with documented rationale.
- [ ] Public helper creates a genuine signed success response plus the matching test cert chain.
- [ ] Public helper creates at least two named rejection fixtures that exercise typed failures through real Relyra validation.
- [ ] Docs no longer tell Hex adopters to use private `Relyra.TestSupport`.
- [ ] Package parity proves public testing files ship and private `test_support` paths stay excluded.
- [ ] Demo FakeIdP path is verified and documented, or removed.
- [ ] Seeds and carry-forward maintenance are triaged.

### Add After Validation (v1.x)

- [ ] More public negative fixture recipes if real adopters ask for them.
- [ ] Optional browser-test examples using Wallaby/Playwright if adopter demand appears.
- [ ] Richer trace assertion helpers if the first public API lands cleanly.

### Future Consideration (v2+)

- [ ] First-class multi-IdP testing matrix.
- [ ] Signed AuthnRequest POST helper, but only if `AUTHN-POST-01` is triggered.
- [ ] KMS-backed test key material, but only if `KMS-01` is triggered.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Public `Relyra.Testing` core fixtures | HIGH | MEDIUM | P1 |
| Docs/package truth migration | HIGH | LOW | P1 |
| Package parity proof | HIGH | LOW | P1 |
| Selected negative fixtures | HIGH | MEDIUM | P1 |
| Optional Phoenix helper layer | MEDIUM | MEDIUM | P2 |
| Demo FakeIdP finish/remove | MEDIUM | LOW-MEDIUM | P1 |
| Narrative/JTBD/ADFS sync | LOW-MEDIUM | LOW | P2 |
| CVE/CI/review-item triage | MEDIUM | LOW | P2 |

## Competitor Feature Analysis

| Feature | Oban.Testing | Phoenix.ConnTest / ConnCase | Relyra v1.9 Approach |
|---------|--------------|-----------------------------|----------------------|
| Public helper module | `Oban.Testing` reduces boilerplate and validates worker-test pitfalls. | `Phoenix.ConnTest` exposes endpoint dispatch helpers and encourages case-template reuse. | `Relyra.Testing` should reduce SAML fixture boilerplate and guard common trust-path pitfalls. |
| Case-template ergonomics | `use Oban.Testing, repo: MyApp.Repo` precedent. | Generated ConnCase uses `@endpoint`, imports conn helpers, and passes `conn` in setup. | Optional `use Relyra.Testing.PhoenixCase, endpoint: ...` only if optional dependency boundary is clean. |
| Negative-path support | Assertion helpers focus on enqueued jobs and worker execution. | Response helpers assert status/body. | Relyra should expose typed rejection fixtures and trace assertions because rejection is core product value. |

## Sources

- `.planning/seeds/SEED-002-testsupport-vs-hex-package.md`
- `.planning/seeds/SEED-003-demo-fakeidp-login-wip.md`
- `mix.exs`
- `guides/getting_started.md`
- `README.md`
- `lib/relyra/test_support.ex`
- `lib/relyra/test_support/fake_idp.ex`
- `demo/ledger_loop/lib/ledger_loop_web/router.ex`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex`
- `https://phoenix.hexdocs.pm/Phoenix.ConnTest.html`
- `https://phoenix.hexdocs.pm/testing.html`
- `https://ex-unit.hexdocs.pm/ExUnit.CaseTemplate.html`
- `https://oban.hexdocs.pm/testing_workers.html`

---
*Feature research for: Relyra v1.9 public testing API and loose-end cleanup*
*Researched: 2026-06-15*
