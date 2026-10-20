# Project Research Summary

**Project:** Relyra
**Domain:** Public SAML testing API and adoption-honesty maintenance
**Researched:** 2026-06-15
**Confidence:** HIGH

## Executive Summary

The next milestone should be a bounded v1.9 maintenance/adoption-honesty milestone. The primary product issue is real: docs teach `Relyra.TestSupport`, while the Hex package deliberately excludes every `test_support` path. The maintainer explicitly approved planning the public API direction, so the coherent fix is a curated `Relyra.Testing` surface that ships in Hex while private `Relyra.TestSupport` remains repo-internal.

The recommended technical shape is core-first: public fixture generation that returns signed SAML inputs, matching test cert chain, and expected outcomes without requiring Phoenix. A thin optional Phoenix helper/case-template can sit on top if phase design proves the optional dependency boundary stays clean. The helper must never bypass the verifier, never trust document `KeyInfo`, never auto-register test certs globally, and must keep the private adversarial corpus private.

SEED-003 needs current-state handling rather than a blind implementation plan. The demo now contains `/fake_idp/login` and `/fake_idp/sso` routes plus controller tests. The milestone should verify whether that browser flow is complete, documented, and CI-covered; if not, finish it or remove it and close the stale seed deliberately.

## Key Findings

### Recommended Stack

No new dependencies are recommended. Use existing Elixir/OTP crypto primitives and Relyra's parser/canonicalization/signature code. Follow ExUnit/Phoenix testing idioms only at the edges: `ExUnit.CaseTemplate` for reusable case ergonomics and `Phoenix.ConnTest` for optional endpoint posting helpers.

**Core technologies:**
- Elixir/OTP: public fixture generation and key/cert handling.
- Existing Relyra XML/signature internals: keep signer/verifier byte behavior aligned.
- ExUnit.CaseTemplate: optional `use` ergonomics for test modules.
- Phoenix.ConnTest: optional Phoenix-specific posting helper, not a core dependency.
- Release parity task: package truth gate for public `testing` inclusion and private `test_support` exclusion.

### Expected Features

**Must have (table stakes):**
- Public Hex-shipped testing module under `Relyra.Testing`.
- Genuine signed success fixture that enters real verification.
- Representative typed rejection fixtures.
- Docs migrated away from private `Relyra.TestSupport` for Hex adopters.
- Package parity proof.
- Demo FakeIdP flow verified/finished or removed.
- Seed and maintenance triage.

**Should have (competitive):**
- Optional Phoenix helper/case-template.
- Validation trace/rejection assertion helpers.
- Demo/docs cross-proof showing the same testing story in code and browser.

**Defer:**
- Full public adversarial corpus.
- Protocol candidates `AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01`.
- Large browser-testing matrix.

### Architecture Approach

Use a public `Relyra.Testing` layer that generates data, not global state. It should return response XML/Base64 SAMLResponse, cert chain, connection hints, and expected result metadata. Phoenix posting should be a separate optional layer. Package filters should continue excluding `test_support` while explicitly including `testing`.

**Major components:**
1. `Relyra.Testing` - public core fixture generation and small assertions.
2. Optional `Relyra.Testing.Phoenix` - endpoint/ACS posting helpers if dependency boundaries are clean.
3. Package parity checks - prove Hex contents match docs.
4. Demo FakeIdP flow - verify or prune current LedgerLoop routes/controllers/tests.
5. Docs/maintenance sync - align README, guides, JTBD/ADFS notes, seeds, CVE/CI status.

### Critical Pitfalls

1. **Public helper becomes a trust bypass** - require real signed XML through ACS or `consume_response/3`.
2. **Static test keys leak into production** - use ephemeral/default test-only key material and explicit returned cert chains.
3. **Shipping private `test_support` internals** - create allowlisted public `testing` modules instead.
4. **Phoenix optional dependency leak** - keep core fixture generation Phoenix-free.
5. **Publishing the private adversarial corpus** - expose representative rejection fixtures only.
6. **Planning stale demo work** - verify current demo routes/tests before deciding finish vs remove.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 64: Public Testing API Contract

**Rationale:** The public API/package-posture decision is the riskiest part and must come first.
**Delivers:** `Relyra.Testing` contract, fixture shape, safety rules, and tests for positive/negative fixtures.
**Addresses:** public Hex testing module, genuine signed fixture, selected negative fixtures.
**Avoids:** trust bypass, static key leakage, private corpus publication.

### Phase 65: Package and Documentation Truth

**Rationale:** Docs and package filters depend on the public API contract.
**Delivers:** package allowlist/parity proof, README/Getting Started/overview/recipes migration from `TestSupport` to `Testing`.
**Uses:** release parity gate and docs drift tests.
**Implements:** docs/package truth boundary.

### Phase 66: Demo FakeIdP Disposition

**Rationale:** SEED-003 is partially stale; current state must be verified before finishing or removing.
**Delivers:** verified and documented browser FakeIdP flow, or deleted stale flow with tests/docs updated.
**Addresses:** demo clarity and seed cleanup.
**Avoids:** duplicate/confusing login paths.

### Phase 67: Maintenance Narrative Sync

**Rationale:** Keep this low-risk work last so it cannot distort the public API design.
**Delivers:** JTBD Scene 3/ADFS sync, optional reviewer quick-architecture note, CVE/CI/review-item triage, seed disposition.
**Addresses:** loose planning and narrative debt.

### Phase Ordering Rationale

- API contract first because package/docs work depends on it.
- Package/docs truth second because it closes the adopter-facing contradiction and gives release proof.
- Demo cleanup third because it is independent but should incorporate the new testing story if useful.
- Maintenance sync last because it is lowest risk and easiest to defer if the API work expands.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 64:** final API shape, key lifecycle, optional Phoenix module compile behavior.
- **Phase 65:** package parity mechanics and doc drift tests.

Phases with standard patterns:
- **Phase 66:** route/controller/browser test verification uses existing demo conventions.
- **Phase 67:** doc and seed maintenance follows existing planning patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified against local `mix.exs`, existing modules, and official ExUnit/Phoenix docs. |
| Features | HIGH | Derived from current seeds, docs/package contradiction, and user-approved scope. |
| Architecture | HIGH | Clear boundary: public `testing`, private `test_support`, optional Phoenix layer. |
| Pitfalls | HIGH | Security pitfalls map directly to Relyra's existing invariants and prior TD-02. |

**Overall confidence:** HIGH

### Gaps to Address

- **Exact `Relyra.Testing` API shape:** settle in Phase 64 before implementation.
- **Ephemeral key performance:** measure during implementation if test generation feels slow.
- **Demo FakeIdP status:** run the demo test lane to decide whether it is already complete or needs finishing/removal.
- **Hex release version implication:** Release Please will decide final package version; do not hand-edit CHANGELOG or manually publish.

## Sources

### Primary (HIGH confidence)

- `mix.exs` - package filters, optional deps, current version.
- `lib/relyra/test_support.ex` - current private macro and Phoenix posting behavior.
- `lib/relyra/test_support/fake_idp.ex` - private FakeIdP fixture shape and prod guard.
- `lib/relyra/test_support/xmldsig_signer.ex` - existing genuine signer behavior.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` - current `/fake_idp/*` routes.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex` - demo browser FakeIdP behavior.
- `https://phoenix.hexdocs.pm/Phoenix.ConnTest.html` - endpoint testing and helper composition.
- `https://phoenix.hexdocs.pm/testing.html` - Phoenix case-template setup pattern.
- `https://ex-unit.hexdocs.pm/ExUnit.CaseTemplate.html` - `using/2` case-template behavior.
- `https://oban.hexdocs.pm/testing_workers.html` - public test helper precedent.

### Secondary (MEDIUM confidence)

- `.planning/seeds/SEED-002-testsupport-vs-hex-package.md` - original contradiction and risk framing.
- `.planning/seeds/SEED-003-demo-fakeidp-login-wip.md` - original demo WIP framing, now partially stale.

---
*Research completed: 2026-06-15*
*Ready for roadmap: yes*
