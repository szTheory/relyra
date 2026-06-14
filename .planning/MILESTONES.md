# Milestones

## v1.8 Brand System & Identity (Shipped: 2026-06-14)

**Phases completed:** 6 phases (58–63), 6 plans · 39 commits · non-protocol brand/design milestone

**Key accomplishments:**

- WCAG-true brand foundation: every palette pair computed via a committed, re-runnable `brandbook/notes/contrast.exs`; 3 contrast failures remediated (gold #C08A2B→#9A6B1C, dark border #334155→#64748B, soft-line decorative-only) and the book's contradictions resolved into a single Canonical Lock Set.
- Complete cage-free logo system, chosen by the maintainer from four real rendered directions (A — Relying Path monogram): primary/stacked/mark/mono/inverse/favicon/tagline + integrated typemark, with usage rules.
- Implementation-ready design tokens (`tokens.json` + `tokens.css` `--rl-*` with automatic dark mode + `tailwind.example.js`), dogfooded by the brand book.
- Standalone professional HTML brand book (`brandbook/index.html`, 8 sections, all component states, light/dark/system) + copy-ready `examples/`; verified in both themes.
- Real-world brand presence: ex_doc logo+favicon, an OpenGraph social card, a README header banner, and a brand-reskinned `ledger_loop` demo.

**Repo-safety:** `brandbook/` self-contained at 316K (<1MB budget); no committed fonts (CDN); diff limited to `brandbook/` + 3 authorized integration files (README.md, mix.exs docs(), demo app.css). **No `lib/`, security, protocol, public-API, or `@version` change.** `mix qa` green (744 tests, 0 failures).

**Not a Hex release:** planning milestone only. (release-please independently released **Hex 1.8.0** — the v1.7 demo `feat` commits — while this was built; the GSD "v1.8" label is distinct from that release. The brand `feat(58–63)` commits will feed the next release-please version.) **No manual `v1.8` git tag** — `v1.8.0` already exists from release-please; a planning-milestone tag would collide. See `.planning/milestones/v1.8-ROADMAP.md`.

---

## v1.7 Adoption Evidence Demo (Shipped: 2026-06-13)

**Phases completed:** 6 phases, 23 plans, 17 tasks

**Key accomplishments:**

- Conventional Phoenix LedgerLoop host app scaffold with local Relyra path dependency and compile-ready repo/endpoint foundation
- LedgerLoop-owned Phoenix routes now mount Relyra SAML and LiveAdmin internals with a demo-owned admin scope provider
- Lightweight Phoenix health/readiness probes with automated route mount coverage for SAML and LiveAdmin seams
- LedgerLoop workspace and route affordance pages with explicit host/Relyra ownership boundaries
- App-local LedgerLoop styling plus Wave 0 workspace regression coverage
- Executable Hex unpack check proves LedgerLoop stays repo-local while the publishable Relyra package excludes demo paths
- Seeded deterministic Relyra connection scenarios with redaction-safe traces and rendered their statuses in the workspace shell.
- Implemented admin session mocking and deep link routing to LiveAdmin trace UI for operator demonstration.
- Demo orchestrator CLI wrapper for abstracting Docker Compose profiles.

**Known deferred items at close:** Phase 53 has a `human_needed` verification (demo Setup/Operator UX click-through) deferred to `/gsd:verify-work 53`. Two dormant seeds opened: SEED-002 (TestSupport vs Hex-package decision) and SEED-003 (demo FakeIdP login WIP). See STATE.md "Deferred Items".

**Merged:** PR #31 (squash) to `main` on 2026-06-13; `demo-app` + `security` + `keycloak` CI lanes green.

---

## v1.6 Adoption Truth (Shipped: 2026-05-28)

**Phases completed:** 5 phases, 15 plans, 46 tasks

**Key accomplishments:**

- Getting Started §3 teaches TestSupport macro round-trip; manual FakeIdP builder demoted to appendix; overview Day-1 aligned
- Production Ecto path guide covers dep-path migrations, host store DDL, wrapper modules, Connections delegator, and opt-in ETS warning
- Production Ecto guide linked from Day-2 hubs, ExDoc extras, and ci.docs presence gate — full doc CI green
- Incident playbook documents login-trace LiveView and `mix relyra.trace` across six evidence surfaces, operator tables, scenarios 3–6, and a diagnostic-vs-trace When in doubt split
- Day-2 hubs and Getting Started §5 now point operators at incident playbook login-trace evidence surfaces; mix ci.docs verified green
- ADOPT-04 delivered: generator emits scope-boundary section, ENC row passes with FakeIdP encrypted assertion positive control, CONFORMANCE.md regenerated with 9 pass / 0 deferred.
- ADOPT-05 delivered: jtbd_gap_map.md refreshed to v1.5+ shipped reality — generic runbook, logout, playbook, login trace, ENC, and identity mapping marked shipped; demand-gated milestones replace stale coverage gaps.
- ADOPT-06 delivered: generic SAML decoder table extended with Keycloak and OneLogin, Getting Started §4 lists four batteries-included presets including ADFS, and Ping/Shibboleth cross-references resolve README vs runbook naming drift without editing README.
- Production Ecto path closes with Related Day-2 guides footer linking incident playbook, troubleshooting, and overview hub
- README Start Here step 3 promotes TestSupport macro with deep link to Getting Started §3; runbook gate prose uses TestSupport proof
- jtbd_user_flows Related docs extended with production Ecto path and incident playbook #evidence-surfaces links
- Getting Started §5 incident playbook links use #evidence-surfaces anchor; final mix ci.docs gate green
- Phase 47 Nyquist parity achieved via retroactive 47-VALIDATION.md and milestone audit update
- v1.6 milestone audit editorial tech debt closed — playbook, jtbd_gap_map, SiteMinder footnote
- Phase 49.2 closed with VERIFICATION.md — Nyquist retro + editorial disposition + mix ci.docs

---

## v1.5 Publish, Prove, Polish (Shipped: 2026-05-27)

**Phases completed:** 6 phases, 18 plans, 24 tasks

**Key accomplishments:**

- XML attribute escaper for SP metadata plus ci.security adversarial corpus for entityID/Location injection
- Production compile and Hex package exclude TestSupport via explicit lib file lists
- Retire regex-alongside-tree EncryptedAssertion locator; extract wire bytes from SaxyTree byte spans
- README and legacy planning docs aligned to 4 first-class presets + 7-family generic runbook; ENC-01 scoped to EncryptedAssertion
- Formatting-only cleanup of adversarial crypto corpus test file
- Process-scoped LoginTrace handler flushes domain:login audit rows and populates LoginResult.validation_trace from consume-path telemetry spans
- LoginTrace.Export redacts audit rows for UI/CLI parity; LiveAdmin query helpers fetch login traces and keep trust timelines login-free
- ConnectionTraceLive mounts at /connections/:id/trace with expandable six-step login rows, navigation link, and Phase 15 UI contract tests
- Headless `mix relyra.trace` CLI and security corpus proving LiveView/CLI redaction equivalence, wired into hollow-gate `ci.security`
- Version sources bumped to 1.4.0 with hand-written CHANGELOG backfill for v1.3/v1.4 milestones — Phase 44-ready, no tag or Hex publish
- Pre-push gates green and release-please stall diagnosis drafted — ready for maintainer-approved push in Plan 44-02.
- Pushed 115 commits to origin, closed stale PR #5, triggered release-please — PR #6 reconciled from erroneous 1.5.0 bump to 1.4.0 narrative CHANGELOG.
- Merged release PR #6; CI published relyra 1.4.0 to Hex with v1.4.0 tag — PUB-03 complete.
- Release parity Mix task compares git tag vX.Y.Z paths to Hex tarball over full package.files scope with test_support hard-fail and unit-tested pure functions.
- Live parity verification for relyra 1.4.0 vs git tag v1.4.0 passes with auditable PARITY-RESULT.md and executable milestone gate script.
- README now answers the 30-second question with a runnable Okta preset snippet above Start Here.
- Installer auto-injects SAML routes on unambiguous single-router hosts and falls back safely when detection is ambiguous.
- Documentation navigation is job-shaped; root BATTERIES_INCLUDED.md is canonical with ADFS in the generated proof map.

---
