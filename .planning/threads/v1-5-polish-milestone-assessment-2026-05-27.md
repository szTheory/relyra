# Investigation: v1.5 Polish Milestone — "Publish, prove, polish"

Status: OPEN — assessment 2026-05-27, post v1.4 ship; NOT YET in a milestone
Priority: HIGH (highest-leverage non-feature work)
Depends: nothing (all wedges are self-contained)

## Trigger

Adopter-first assessment at v1.4 close confirmed Relyra is "protocol-feature complete and adopter-blocked." The v1.x arc shipped its done-enough line, but the Hex-published surface lags the code by two minor versions and the brand-defining "every login explains itself" promise has no UI receipt. v1.5 is a polish-and-publish milestone, NOT a new feature wedge.

## Scope (3 wedges)

### Wedge 1 — Ship v1.3 + v1.4 to Hex

**State of the world:**
- `mix.exs:6` is `@version "1.2.0"`
- Git tags: `v0.1, v0.2, v1.0, v1.1, v1.1.0, v1.2.0, v1.4` (no `v1.3.0`, no `v1.4.0`)
- `CHANGELOG.md` latest entry: `[1.2.0] 2026-05-25` (Phase 28-30)
- No `[1.3.0]` or `[1.4.0]` CHANGELOG sections — release-please likely staged them but the release PR never merged
- `.planning/PROJECT.md` declares v1.3 and v1.4 shipped 2026-05-27
- Hex audience can see at most v1.2.0; hexdocs for v1.2.0 already include v1.3/v1.4 guide files (via `extras:` in `mix.exs:111-136`), so published docs describe features the published code doesn't implement

**Steps:**
1. Bump `mix.exs:6` to `@version "1.4.0"` (or `1.3.0` then `1.4.0` if you want sequential releases — recommend single jump for adopter clarity)
2. Fix version pin in `guides/getting_started.md:26` from `~> 0.1.0` to `~> 1.4`
3. Backfill `CHANGELOG.md` `[1.3.0]` and `[1.4.0]` sections from milestone summaries
4. Verify Release Please automation triggers (PR currently stalled — diagnose why before re-triggering)
5. `git tag v1.4.0` (the existing `v1.4` is non-SemVer; Hex will reject it)
6. Publish via the release-please pipeline (NOT `mix hex.publish` manually — CLAUDE.md forbids it)

**Risk:** release-please pipeline state may need debugging; the gap from v1.2.0 → HEAD spans 9 phases.

### Wedge 2 — Stepwise login-trace LiveView

**Brand-defining gap:** `grep -r "stepwise\|login_trace" lib guides` returns nothing. The library's thesis ("every login produces a validation trace, every error names the field, every operator can read the trust path like a logbook") has no per-login UI receipt. Telemetry-handler self-wiring is the only current surface.

**Proposed:**
- New route in `lib/relyra/live_admin/router.ex` at `/relyra/admin/connections/:connection_id/trace`
- LiveView shows last N logins for that connection, each expandable into the 8 telemetry-span outcomes (decode → validate → signature → replay → user_map → session_establish), with `:outcome`, `:error_code`, and post-mapping role/attribute result
- Reuses existing audit_event + telemetry namespaces; no new schemas required
- Optionally: same surface as a Mix task (`mix relyra.trace --connection ID --last 10`) for headless/CI inspection

**Why now:** when wedge 1 ships v1.4 to Hex, the trace surface should be IN that release — it's what makes the "every login explains itself" claim true to adopters, not just to maintainers.

**Estimate:** 2-3 plans, ~600-900 LOC including tests.

### Wedge 3 — README/installer ergonomics + warning-level tech-debt sweep

**Pieces:**
- (a) Fix `guides/getting_started.md:26` version pin (also part of wedge 1; mention in both)
- (b) Lead `README.md` with an `apply_defaults(:okta, …)` snippet before the Day-1 router (single-snippet pitch — see oban/bandit pattern)
- (c) `mix relyra.install` (`lib/mix/tasks/relyra.install.ex:108-128`) auto-injects `saml_routes()` into the router when it finds an unambiguous insertion point — fall back to print-instruction only when ambiguous
- (d) Close v1.3 audit warnings (from `.planning/v1.3-MILESTONE-AUDIT.md`):
  - **WR-ENC-ATTR**: REQUIREMENTS.md mentions EncryptedAttribute inside ENC-01 while verified scope is EncryptedAssertion → doc fix
  - **WR-01/WR-02**: `locate_encrypted_assertion/1` still uses regex alongside parse-tree detector → unify on parse-tree
  - **WR-03**: metadata attribute interpolation in `lib/relyra/protocol/metadata.ex` is unescaped → XSS-class defense-in-depth gap; escape via existing C14N/serializer
  - **WR-04**: `lib/relyra/test_support` is compiled into the prod artifact with runtime guards → exclude from prod build via `elixirc_paths(:prod)` or `package.files` whitelist tightening
- (e) Close Phase 40 deferred-items.md formatting drift in `test/security/xml/adversarial_crypto_test.exs` (lines 188-200, 196) → `mix format` fix only
- (f) Correct PROJECT.md "Current State" + README preset claim from "8 presets" to "4 first-class + generic runbook covering 7 IdP families" (real coverage)
- (g) Dedupe `BATTERIES_INCLUDED.md` (root, drift-tested) and `guides/batteries_included.md` (hand-written) — pick one as primary, stub the other
- (h) Add `guides/overview.md` as a job-shaped index (Day-1 / Day-2 / Reference) — fixes the "5-footer-chase" navigation friction

**Estimate:** 1-2 plans, ~400-600 LOC change (mostly docs + small code touches).

## Adversarial / quality gates

- Wedge 1: post-publish parity verification (the existing release-please + Release-Please + post-publish-parity discipline from PROJECT.md "Constraints — OSS discipline"); verify hex.pm tarball matches git tag byte-for-byte
- Wedge 2: a `test/security/login_trace_test.exs` that asserts the trace LiveView never displays raw XML/PEM/key material (extends the existing audit redaction discipline — `diagnostic/allow_list.ex` is the precedent)
- Wedge 3: `mix qa` clean after the formatting fix; WR-03 closure adds a `metadata_attribute_injection_test.exs` row to `ci.security` proving interpolated values are XML-attribute-escaped

## Explicitly NOT in v1.5 scope

- AUTHN-POST-01 (POST-binding enveloped signed AuthnRequests) — save-for-demand; see this file's sibling thread `signed-authn-requests-investigation.md`
- KMS-01 (AWS/GCP KMS KeyResolver adapters) — save-for-demand; see `encrypted-assertions-investigation.md:50`
- SIGNED-META-01 (signed SP metadata for InCommon) — save-for-demand; new investigation needed if triggered
- More provider presets (Ping, OneLogin, Shibboleth, Keycloak) — generic runbook covers them
- Customer-IT self-serve onboarding broker — out of scope per PROJECT.md (host-app territory)
- SCIM, ECP, HTTP-Artifact, Attribute Query — out of scope per PROJECT.md

## Verdict

**v1.5 = single polish milestone, ~1 week scope, transforms the outside world's perception from "1.2 with some github tags" to "1.4 shipped, every login explains itself, install in 15 minutes."** After v1.5 ships, the rational next move is *waiting for demand-signal issues, not writing more code*. The three demand-gated candidates have pre-baked plans (this thread + the two v1.3-era investigation threads) ready to ship in 2-3 weeks the day the GitHub issue lands.

## Cross-references

- `.planning/threads/encrypted-assertions-investigation.md` — KMS-01 extension point
- `.planning/threads/signed-authn-requests-investigation.md` — AUTHN-POST-01 defer rationale
- `.planning/v1.3-MILESTONE-AUDIT.md` — source of WR-03/WR-04
- `.planning/phases/40-operational-polish-error-taxonomy/deferred-items.md` — formatting drift
- `.planning/STRATEGIC-ASSESSMENT-2026-05-23.md` — the original "diminishing returns" framing (still authoritative)
- `.planning/PROJECT.md` — "Next Milestone Goals" section + Out of Scope (locked)
