---
gsd_state_version: 1.0
milestone: v1.10
milestone_name: Phases
current_phase: 72.1
current_phase_name: close-v1-10-evaluator-endpoint-and-trace-auth-gaps
status: verifying
stopped_at: Completed 72.1-04-PLAN.md
last_updated: "2026-08-27T21:04:59.488Z"
last_activity: 2026-08-27
last_activity_desc: Phase 72.1 execution started
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 30
  completed_plans: 30
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-08-27)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 72.1 — close-v1-10-evaluator-endpoint-and-trace-auth-gaps

## Current Position

Phase: 72.1 (close-v1-10-evaluator-endpoint-and-trace-auth-gaps) — EXECUTING
Plan: 4 of 4
Status: Phase complete — ready for verification
Last activity: 2026-08-27 — Phase 72.1 execution started

## Performance Metrics

- Last shipped milestone: v1.9 Loose Ends & Adoption Honesty (Phases 64-67, 15/15 requirements, archived 2026-06-19)
- Highest shipped phase: 67
- Current milestone: v1.10 Docker DX & Fleet Proxy (Phases 68-72)
- Previous milestone: v1.8 Brand System & Identity (Phases 58-63)
- v1.9 phase progress: 4/4 phases complete, 13/13 plans complete
- v1.9 audit status: `tech_debt` for non-blocking validation metadata cleanup; 15/15 requirements satisfied
- Phase 64 Plan 01 completed in 8min (2 tasks, 5 files)
- Phase 64 Plan 02 completed in 8min (2 tasks, 5 files)
- Phase 64 Plan 03 completed in 5min (2 tasks, 4 files)
- Phase 64 Plan 04 completed in 3min (2 tasks, 2 files)
- Phase 66 Plan 01 completed in 9min (3 tasks, 1 file)
- Phase 66 Plan 02 completed in 8min (1 task, 4 planning files; decision checkpoint)
- Phase 66 Plan 04 completed in 3min (2 tasks, 3 files; retained FakeIdP documentation; SEED-003 resolved)
- Phase 67 completed 2026-06-19 (4/4 plans; MAINT-01..MAINT-03 verified; CVE backfill and seed cleanup reconciled)

**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 69-compose-split-fleet-proxy P01 | 24m | 2 tasks | 4 files |
| Phase 69 P02 | 42m | 2 tasks | 2 files |
| Phase 69 P03 | 17m | 2 tasks | 21 files |
| Phase 70 P01 | 9min | 1 tasks | 10 files |
| Phase 70 P02 | 18min | 2 tasks | 2 files |
| Phase 70 P03 | 6m | 2 tasks | 2 files |
| Phase 70 P04 | 14min | 2 tasks | 6 files |
| Phase 70 P05 | 7m | 2 tasks | 3 files |
| Phase 70-keycloak-behind-the-proxy P06 | 6min | 1 tasks | 2 files |
| Phase 70 P07 | 8m | 2 tasks | 2 files |
| Phase 70-keycloak-behind-the-proxy P08 | 20m | 2 tasks | 9 files |
| Phase 70 P09 | ~10 minutes | 1 tasks | 2 files |
| Phase 70 P10 | 12m | 2 tasks | 2 files |
| Phase 70 P11 | 7m | 2 tasks | 2 files |
| Phase 70 P12 | 6m | 1 task | 1 file |
| Phase 70 P13 | — | 1 task | 4 files |
| Phase 70 P14 | — | 2 tasks | 7 files |
| Phase 71 P01 | 25min | 2 tasks | 4 files |
| Phase 71 P02 | 20min | 2 tasks | 3 files |
| Phase 72-documentation P01 | 6m | 2 tasks | 2 files |
| Phase 72-documentation P02 | 14m | 2 tasks | 4 files |
| Phase 72 P03 | ~2 minutes | 1 tasks | 2 files |
| Phase 72-documentation P04 | ~5 minutes | 2 tasks | 3 files |
| Phase 72 P05 | ~6 minutes | 2 tasks | 3 files |
| Phase 72.1-close-v1-10-evaluator-endpoint-and-trace-auth-gaps P01 | 5min | 1 tasks | 5 files |
| Phase 72.1 P02 | 4m | 1 tasks | 4 files |
| Phase 72.1 P03 | 5m | 1 tasks | 3 files |
| Phase 72.1-close-v1-10-evaluator-endpoint-and-trace-auth-gaps P04 | 19min | 1 tasks | 2 files |

## Accumulated Context

### Decisions

- v1.10 is demo + docker + docs ONLY — zero changes to lib/ security seams, public API, behaviour callbacks, protocol surface, or the Hex package whitelist (`mix.exs` package.files). Nothing new ships in the tarball.
- v1.10 locked decisions: simple `relyra.localhost` hostname (static `COMPOSE_PROJECT_NAME=relyra`, single checkout at a time, `RELYRA_HOST` override hook retained); scheme `http` (no mkcert); shared Traefik proxy on external `proxy` network per the `scoria` sibling-lib convention; Keycloak fully behind the proxy.
- v1.10 dependency chain: 68 (caching) → 69 (compose/proxy) → 70 (keycloak, needs proxy) → 71 (launcher, wraps the compose files) → 72 (docs, describes the finished surface).
- v1.10 phase→category map: 68=DKR-01..04, 69=FLEET-01..03, 70=KC-01, 71=DX-01..02, 72=DOC-01..02.
- v1.10 risks to respect: `*.localhost` is browser-only (never rely on it for curl/BEAM/psql); prefix Traefik router/service names `relyra-*`; bind host ports to `127.0.0.1`; keep proxy config out of the auto-loaded `docker-compose.override.yml`; use `KC_PROXY_HEADERS=xforwarded` (not deprecated `KC_PROXY=edge`).
- Brand voice source of truth for v1.10 docs: `brandbook/notes/decision-log.md` Canonical Lock Set (newest; supersedes `prompts/relyra-brand-book.md`).
- Demand-gated protocol scope is unchanged and still paused: AUTHN-POST-01, KMS-01, SIGNED-META-01.
- v1.9 resolved SEED-002, SEED-003, and narrow maintenance sync as bounded adoption-honesty cleanup; SEED-001 is historical v1.7 work, not a future candidate.
- [Phase ?]: curl added to Dockerfile.dev apk list to preserve existing demo_app healthcheck probe after removing inline apk install block
- [Phase ?]: Named volumes attach at nested demo paths — NOT generic /app/deps or /app/_build — ensuring macOS host artifacts never enter the Linux container (DKR-02, D-04)
- [Phase ?]: config :phoenix_live_reload backend: :fs_poll added as separate top-level block in dev.exs, NOT inside Endpoint live_reload: keyword which silently ignores backend: (DKR-04, D-10 corrected, Pitfall 1)
- [Phase ?]: Solo Compose auto-loads a loopback-only demo_app ingress while PostgreSQL remains internal.
- [Phase ?]: Phoenix public URL and LiveView origins derive from explicit runtime environment values outside test.
- [Phase ?]: Shared ingress remains neutral: dev_proxy on external proxy network; Relyra owns only relyra-local-demo labels.
- [Phase ?]: Fleet mode uses explicit base-plus-proxy Compose files, excluding the automatic solo port overlay.
- [Phase ?]: Keycloak trace proof uses the three persisted verifier steps; workspace return and LoginReceipt separately prove host mapping and session establishment.
- [Phase ?]: Unchanged Keycloak descriptors skip all trust mutations after issuer, SSO, active-cert, and Sarah identity comparison.
- [Phase ?]: Changed Keycloak descriptors disable before import, activate new signing trust, retire stale trust, then enable last.
- [Phase ?]: Keycloak proxy proof renders default and RELYRA_HOST override contracts from one public-host input.
- [Phase ?]: The E2E harness uses an owned Compose project and redacted named-layer diagnostics.
- [Phase ?]: The optional Keycloak job renders only when its stable persisted connection is enabled; FakeIdP remains the first deterministic job.
- [Phase ?]: Workspace proof uses only durable LoginReceipt presence and exact receipt wording, without cookie or authorization claims.
- [Phase ?]: Keycloak trace proof uses only the three persisted verifier steps; workspace return and LoginReceipt separately prove host mapping and session establishment.
- [Phase ?]: Keycloak descriptor bootstrap parses once into a canonical candidate reused for preflight, audited metadata apply, and certificate activation.
- [Phase ?]: Credential-bearing Keycloak Playwright runs disable all attachments and delete a per-run temporary output directory before diagnostics.
- [Phase ?]: Keycloak E2E diagnostics retain only validated redacted container-state.log, relyra.log, and audit-actions.log files.
- [Phase ?]: A single runtime Basic-auth pipeline guards both demo admin scope establishment and every mounted LiveAdmin route.
- [Phase ?]: The Keycloak harness generates and redacts an ephemeral host-admin credential pair for authenticated trace evidence.
- [Phase ?]: Keycloak identity creation, attributed mapping audit, and final enablement share one host-owned transaction.
- [Phase ?]: Diagnostic redaction and promotion validation independently track exact protected XML root QNames and fail closed at EOF.
- [Phase ?]: Keycloak scenario status is limited to public topology, signed ACS, receipt, trace, diagnostics, and cleanup evidence.
- [Phase ?]: The recurring Keycloak CI workflow is artifact-free and leaves dependency/security ownership to security-gates.yml.
- [Phase 71]: Environment-derived launcher values are exported and expanded as quoted shell data, never interpolated into Make recipe syntax.
- [Phase 71]: Host-specific launcher acceptance uses deterministic command fixtures; recurring fleet and Keycloak browser lanes own live topology proof, so no human UAT gate remains.
- [Phase ?]: Docker DX guide makes Solo FakeIdP the complete first proof; Fleet and Keycloak remain follow-on proofs.
- [Phase ?]: Solo/FakeIdP remains the complete first evaluator proof; Fleet and Keycloak are optional follow-ons.
- [Phase ?]: Published demo documentation uses absolute GitHub links for repository-only evaluator material.
- [Phase ?]: Root README retains its library Day-1 sequence and routes Docker evaluation separately.
- [Phase ?]: Keycloak launcher succeeds only after proxy, Fleet profile, provisioner, and exact public descriptor validation.
- [Phase ?]: Keycloak public readiness uses Traefik loopback resolution, not service DNS.
- [Phase ?]: The evaluator narrative is bound to FakeIdP's emitted Sarah NameID and the database-backed LoginReceipt assertion.
- [Phase ?]: Optional Keycloak documentation invokes only the public make keycloak launcher; make fleet remains discovery-only.
- [Phase ?]: Doctor classifies demo, PostgreSQL, and Traefik listeners by explicit role instead of inferring role from a port number.
- [Phase ?]: Override guidance uses the loopback origin emitted by make url; localhost:4000 remains default-only documentation.
- [Phase ?]: Setup derives all SAML endpoint values from one enabled connection and verified scoped routes.
- [Phase ?]: Trace tests establish admin scope only through credentialed /login/admin before visiting the exact trace path.
- [Phase ?]: Demo admin credentials forward only from empty-default operator environment values.
- [Phase ?]: make url names credential keys and 401 recovery without printing or persisting values.
- [Phase ?]: Evaluator docs require operator-chosen admin credentials before trace access, recover 401 through /login/admin, and publish connection-scoped SAML routes.
- [Phase ?]: Keycloak trace proof denies unauthenticated access before entering only through /login/admin.
- [Phase ?]: The Keycloak harness preserves complete operator pairs, generates absent pairs per run, and rejects partial input.

### Blockers/Concerns

- The milestone-wide invariant (no `lib/`/API/protocol/Hex-whitelist change) is the primary guardrail; every phase plan must keep repo gates (`mix qa`, `mix ci.security`, `mix format --check-formatted`, `mix test --warnings-as-errors`) green by not touching `lib/`.
- Direct `mix deps.audit` still reports the documented pre-existing Decimal 2.4.1 advisory; Phase 70 remediated Req/Mint without adding a suppression, and `mix ci.security` remains green.

### Roadmap Evolution

- Phase 72.1 inserted after Phase 72: Close v1.10 evaluator endpoint and trace-auth gaps (URGENT)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| demand_gated | AUTHN-POST-01 | save-for-demand |
| demand_gated | KMS-01 | save-for-demand |
| demand_gated | SIGNED-META-01 | save-for-demand |
| verification | Phase 53 human-needed UI testing (demo Setup/Operator UX click-through) | deferred; run `/gsd:verify-work 53` |
| v1.10_future | TLS via mkcert for `*.relyra.localhost` | deferred; http suffices on localhost |
| v1.10_future | Hashed per-checkout instance hostnames (scoria-style) | deferred; simple `relyra.localhost` chosen |
| v1.10_future | Production multi-stage `mix release` Dockerfile | deferred; dev/demo DX only |
| brand_future | BRAND-F01 — animated/motion brand assets | deferred to future milestone |
| brand_future | BRAND-F02 — full 19-icon icon library | deferred to future milestone |
| Phase 68 P01 | 128 | 3 tasks | 3 files |
| Phase 68 P02 | 2m 26s | 2 tasks | 2 files |

## Session Continuity

**Stopped at:** Completed 72.1-04-PLAN.md
**Resume file:** None

Last session: 2026-08-27T21:04:59.478Z
Resume at: $gsd-plan-phase 72.1

## Operator Next Steps

- Verify Phase 72 with `/gsd-verify-work 72`.
