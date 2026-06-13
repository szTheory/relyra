---
id: SEED-002
status: dormant
planted: 2026-06-13
planted_during: v1.7 closeout (after PR #31 merge)
trigger_when: next $gsd-new-milestone, or first adopter issue about testing their SP integration
scope: small-to-medium
---

# SEED-002: Resolve Relyra.TestSupport vs Hex-package contradiction

## Why This Matters

Surfaced during the v1.7 demo work (and four-agent research). There is a real
doc-vs-package contradiction:

- `guides/getting_started.md` §3 ("Prove local login with TestSupport") instructs
  adopters to `use Relyra.TestSupport, endpoint: …` — and v1.6 ADOPT-01 marked
  this "validated".
- BUT `mix.exs` `package_lib_files/0` and `prod_elixirc_paths/0` both reject any
  path containing `test_support`, so `lib/relyra/test_support/` (the macro +
  FakeIdP + XmldsigSigner) is **excluded from the published Hex tarball** and from
  `:prod` compilation. This is the verified invariant **TD-02**.

So either adopters installing from Hex cannot actually `use Relyra.TestSupport`
(docs overpromise), or `test_support` is *meant* to ship (the package filter is
the bug). It needs a deliberate decision.

This is the same defect that made the demo's path-dependency build break in CI
(a `:prod`-compiled dep has no `test_support`).

## When to Surface

**Trigger:** next `$gsd-new-milestone`, or sooner if an adopter files an issue
about testing their SP integration / can't find `Relyra.TestSupport`.

## Scope Estimate

**Small-to-medium.** Two coherent directions (pick one, deliberately):

1. **Document the exclusion** — make Getting Started honest that `TestSupport` is
   repo-only (run against the source / a path dep), not a Hex artifact. Cheapest.
2. **Ship a curated `Relyra.Testing`** for adopters — idiomatic in Elixir
   (`Oban.Testing`, `Phoenix.ConnTest`). Mint a valid signed assertion + canned
   *invalid* assertions (expired / wrong-audience / tampered-digest) so adopters
   can test their **rejection** path. Ship in `lib/` with **ephemeral per-call
   keypairs**, keep the **adversarial corpus private** in `test/`, and never let a
   `Relyra.Testing` cert wire into a production `ConnectionResolver`.

## Escalation

Direction 2 is a **public API shape change** + reverses TD-02 + crosses the
"FakeIdP is dev/CI-only, not a product IdP" Out-of-Scope line (PROJECT.md). Per
CLAUDE.md it **requires explicit user sign-off** before acting. Treat it as its
own milestone, not a smuggled-in change.

## Footguns (from cross-ecosystem research)

- Shipped default signing keys reused in prod (ruby `saml_idp`, python3-saml) →
  attacker-known prod key. Use ephemeral keypairs only.
- A fake that serializes with your own code masks real parser-differential bugs
  (ruby-saml CVE-2025-25291/2) → keep the documented real-IdP (Keycloak) E2E path
  and keep the adversarial corpus as the gating security test, NOT the consumer
  helper.

## Breadcrumbs

- `guides/getting_started.md` §3 (76-125)
- `mix.exs` — `elixirc_paths/1`, `prod_elixirc_paths/0`, `package_lib_files/0`
- `lib/relyra/test_support/` (`test_support.ex`, `fake_idp.ex`, `xmldsig_signer.ex`)
- `PROJECT.md` (TD-02; Out-of-Scope "FakeIdP is dev/CI support only")
- `test/adoption/journey_02_testsupport_proof_test.exs`
