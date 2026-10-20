# Pitfalls Research

**Domain:** Public SAML testing helpers and loose-end maintenance
**Researched:** 2026-06-15
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Public Helper Becomes a Trust Bypass

**What goes wrong:**
The helper proves login by assigning session state or calling host callbacks directly instead of producing SAML that goes through the verifier.

**Why it happens:**
It is much simpler to mock "logged in" than to mint signed SAML and wire test certs.

**How to avoid:**
Every public login proof helper must feed `Relyra.consume_response/3` or the Phoenix ACS route with signed XML. Requirements should explicitly test that digest/signature verification still occurs.

**Warning signs:**
Helper APIs mention `current_user`, `SessionAdapter`, or direct controller assigns but not `SAMLResponse`, `cert_chain`, or ACS/consume entrypoints.

**Phase to address:**
First implementation phase for `Relyra.Testing`.

---

### Pitfall 2: Static Test Keys Leak Into Production

**What goes wrong:**
Docs or helpers normalize a reusable FakeIdP key/cert that adopters accidentally configure in production.

**Why it happens:**
Static fixtures are easy to copy and produce deterministic tests.

**How to avoid:**
Default to ephemeral key material returned with the fixture. If deterministic fixtures are needed, require explicit caller opt-in and label them unsafe for production. Never auto-register test certs globally.

**Warning signs:**
Docs show a PEM block or "put this cert in config" without "test only" and without scoped test setup.

**Phase to address:**
API design and docs phases.

---

### Pitfall 3: Shipping `test_support` Internals

**What goes wrong:**
Fixing the docs/package contradiction by allowing all `lib/relyra/test_support/*` into the Hex tarball exposes private internals as public API.

**Why it happens:**
It is the smallest packaging diff.

**How to avoid:**
Keep `test_support` excluded. Add new allowlisted `lib/relyra/testing*` modules and package parity tests proving both sides.

**Warning signs:**
Changes delete `String.contains?(&1, "test_support")` or weaken `verify.release_parity`.

**Phase to address:**
Packaging/docs truth phase.

---

### Pitfall 4: Optional Phoenix Dependency Becomes Mandatory

**What goes wrong:**
A public helper module references Phoenix at compile time, breaking non-Phoenix consumers or changing dependency expectations.

**Why it happens:**
The current private macro imports `Phoenix.ConnTest`; mirroring it directly is tempting.

**How to avoid:**
Put core fixture generation in a Phoenix-free module. If a Phoenix layer ships, isolate it and verify package compile with Phoenix optionality intact.

**Warning signs:**
`Relyra.Testing` itself imports `Phoenix.ConnTest` or calls Phoenix modules unconditionally.

**Phase to address:**
API design and compile/package test phase.

---

### Pitfall 5: Public Negative Fixtures Reveal the Private Corpus

**What goes wrong:**
Public helpers copy the full adversarial crypto corpus into API/docs, coupling adopters to internal attack fixtures and teaching bypass details.

**Why it happens:**
Relyra's strongest tests are already written, so copying them feels efficient.

**How to avoid:**
Expose representative named outcomes only, such as `:expired_assertion`, `:wrong_audience`, and `:tampered_digest`. Keep corpus-specific fixtures and exploit variants private and gated by `mix ci.security`.

**Warning signs:**
Public docs reference adversarial fixture filenames or named CVE exploit variants as helper API.

**Phase to address:**
Testing helper design and docs phase.

---

### Pitfall 6: Demo FakeIdP Seed Is Treated as Current Truth

**What goes wrong:**
The roadmap plans to wire routes that already exist, missing the real task: verify completion, docs, browser flow, and seed cleanup.

**Why it happens:**
SEED-003 was planted when files were untracked/WIP, but the repo has changed.

**How to avoid:**
Start the demo phase with a current-state verification pass: route table, controller tests, browser test, README guide, and `scripts/demo` path.

**Warning signs:**
Requirements say "add `/fake_idp/*` routes" without acknowledging they are already in `demo/ledger_loop/lib/ledger_loop_web/router.ex`.

**Phase to address:**
Demo cleanup phase.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Rename docs only, no public helper | Fast closure | Hex adopters still lack a good local proof story | Only if phase design rejects public API after explicit review. |
| Ship public helper without parity tests | Faster implementation | Next release may silently omit it from Hex | Never. |
| Reuse persistent private keypair | Faster tests | Key provenance becomes unclear and may leak into prod examples | Only inside private repo tests, not public default. |
| Leave SEED-003 untouched after verification | Saves cleanup time | Future agents keep replanning stale work | Never after milestone closes. |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Hex package files | Include `test_support` wholesale | Add only `testing` public modules, preserve `test_support` exclusion. |
| Phoenix host tests | Assume a fixed ACS path | Accept explicit `:path` or `:connection_id`; do not guess host routing. |
| Relyra connection config | Trust document `KeyInfo` for the test cert | Return cert chain and require normal configured-cert trust. |
| Demo browser flow | Bypass CSRF incorrectly or post to wrong pipeline | Keep ACS under the `:saml` pipeline with `SkipCSRF` before `protect_from_forgery`. |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| RSA key per assertion in large suites | Slow test modules | Allow caller-scoped fixture context if needed | Hundreds/thousands of generated fixtures per run. |
| Unbounded SAMLRequest inflate in demo | Hangs/memory pressure | Keep bounded `safeInflate` behavior | Crafted oversized SAMLRequest. |
| Full browser proof for every test | Slow demo CI | Unit/controller tests for signer/controller, one browser smoke | CI time grows with browser matrix. |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Helper installs cert globally | Test cert trusted in unintended environment | Return cert data only; caller wires it in test setup. |
| Helper accepts unsigned fixtures for convenience | Normalizes auth bypass | No unsigned success helper. |
| Helper weakens algorithm policy | Users think SHA-1/legacy paths are normal | Public helpers use current strict defaults only. |
| Demo calls private TestSupport | Path-dep prod compile breaks or hides package truth | Demo-local signer only. |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Two similarly named helpers (`TestSupport` and `Testing`) without migration docs | Adopters do not know which to use | Docs clearly say `Relyra.Testing` is public; `Relyra.TestSupport` is repo-internal. |
| Public negative fixtures with cryptic atoms only | Users cannot map failures to their app behavior | Provide examples with expected `Relyra.Error` atoms and trace assertions. |
| Demo has two login paths with no explanation | Evaluators click the wrong path | Pick one documented path or clearly label "local FakeIdP browser proof". |

## "Looks Done But Isn't" Checklist

- [ ] **Public API:** Module exists but is not included in `package.files`.
- [ ] **Docs:** README updated but `guides/getting_started.md` still uses `Relyra.TestSupport`.
- [ ] **Security:** Positive helper signs XML but tests do not prove tampering rejects.
- [ ] **Optional deps:** Core helper compiles only when Phoenix is installed.
- [ ] **Demo:** Controller tests pass but browser/README path still points elsewhere.
- [ ] **Seeds:** SEED-002/003 remain dormant after completion with stale trigger text.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Shipped too much `test_support` | MEDIUM-HIGH | Re-tighten package files, deprecate exposed modules, add parity regression. |
| Static key leaked in docs | MEDIUM | Remove key, rotate examples, add doc test forbidding PEM blocks in public testing docs. |
| Phoenix dependency leak | MEDIUM | Split modules, guard optional helper compile, add no-Phoenix compile check if feasible. |
| Demo flow duplicated/confusing | LOW | Delete one route path or update demo guide with explicit labels and tests. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Public helper bypasses verifier | Testing API phase | Tests prove helper output enters `consume_response/3`/ACS and verifies real signature/digest. |
| Static key leakage | Testing API + docs phase | Tests/docs checks ensure ephemeral/default test-only key handling and no production config guidance. |
| Shipping `test_support` internals | Packaging/docs phase | `mix verify.release_parity` pure functions and package tests cover exclude/include behavior. |
| Phoenix dependency leak | Testing API phase | Compile/package check with optional dependency assumptions. |
| Stale demo seed | Demo cleanup phase | Route/controller/browser tests and seed triage commit. |

## Sources

- `.planning/seeds/SEED-002-testsupport-vs-hex-package.md`
- `.planning/seeds/SEED-003-demo-fakeidp-login-wip.md`
- `mix.exs`
- `lib/mix/tasks/verify.release_parity.ex`
- `lib/relyra/test_support.ex`
- `lib/relyra/test_support/fake_idp.ex`
- `lib/relyra/test_support/xmldsig_signer.ex`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex`
- `demo/ledger_loop/lib/ledger_loop_web/router.ex`
- `https://phoenix.hexdocs.pm/Phoenix.ConnTest.html`
- `https://ex-unit.hexdocs.pm/ExUnit.CaseTemplate.html`

---
*Pitfalls research for: Relyra v1.9 public testing API and loose-end cleanup*
*Researched: 2026-06-15*
