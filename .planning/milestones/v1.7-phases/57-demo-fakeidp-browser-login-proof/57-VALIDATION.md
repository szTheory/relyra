---
phase: 57
slug: demo-fakeidp-browser-login-proof
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
validated: 2026-06-14
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + `Phoenix.ConnTest` + `Phoenix.LiveViewTest` (`LedgerLoopWeb.ConnCase`) |
| **Config file** | `demo/ledger_loop/test/test_helper.exs` (existing) |
| **Quick run command** | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/fake_idp_controller_test.exs test/ledger_loop/fake_idp/signer_test.exs` |
| **Full suite command** | `mix ci.demo_app` (rides existing `demo-app-ci.yml`) |
| **Estimated runtime** | ~5 seconds (demo suite is sub-second today; in-process) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (scoped fake_idp + signer tests)
- **After every plan wave:** Run `mix ci.demo_app` (full demo suite)
- **Before `/gsd:verify-work`:** Full demo suite green AND relyra `mix qa` untouched/green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-W0 | 01 | 1 | SEED-003 | T-57 crypto | Demo keypair/cert committed under `priv/fake_idp/`; fixture `:pem` updated from `MOCK_PEM_NOT_REAL` to real self-signed cert | data/fixture | `mix test test/ledger_loop/fake_idp/keypair_test.exs` (fixture loads, cert parses, key↔cert pairing) | ✅ `keypair_test.exs` | ✅ green |
| 57-W0 | 01 | 1 | SEED-003 | — | `LoginTrace.attach(repo: LedgerLoop.Repo)` wired in `LedgerLoop.Application` so `domain: :login` AuditEvents are written | wiring | `mix test test/ledger_loop_web/fake_idp_flow_test.exs` (trace row appears) | ✅ `fake_idp_flow_test.exs` | ✅ green |
| 57-signer | 02 | 1 | SEED-003 | V6 crypto | Vendored demo signer output passes `Relyra.Security.Signature.verify/4` against demo cert PEM (C14N via relyra public engine — never hand-rolled) | unit | `mix test test/ledger_loop/fake_idp/signer_test.exs` | ✅ `signer_test.exs:44` | ✅ green |
| 57-signer | 02 | 1 | SEED-003 | tamper | Mutated assertion `<NameID>` → `Signature.verify/4` `{:error, %Error{type: :digest_mismatch}}` | unit | same | ✅ `signer_test.exs:83` | ✅ green |
| 57-routes | 03 | 2 | SEED-003 | V5 input | `GET /fake_idp/login` renders "Local Test Support / FakeIdP" banner + passes RelayState; `POST /fake_idp/sso` self-submits `SAMLResponse` to `action="/saml/<…J0>/acs"` | controller | `mix test test/ledger_loop_web/controllers/fake_idp_controller_test.exs` | ✅ `fake_idp_controller_test.exs` | ✅ green |
| 57-flow | 03 | 2 | SEED-003 | V2/V3 | **Success:** `/saml/:id/login` → `/fake_idp/*` → POST `/saml/:id/acs` → `do_verify/4` `{:ok}` → `SessionAdapter` LoginReceipt inserted → redirect `/` | integration | `mix test test/ledger_loop_web/fake_idp_flow_test.exs` | ✅ `fake_idp_flow_test.exs:43` | ✅ green |
| 57-flow | 03 | 2 | SEED-003 | tamper/repudiation | **Tampered:** flow with mutated assertion → typed rejection AND `domain: :login` error AuditEvent visible at `/relyra/admin/connections/<…J0>/trace` | LiveView | same | ✅ `fake_idp_flow_test.exs:110` | ✅ green |
| 57-regress | 03 | 2 | SEED-003 | — | Phase-53 `/fake_idp/*`-adjacent tests stay green; demo suite ≥ 37/0 | suite | `mix ci.demo_app` | ✅ existing | ✅ green (57/0) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `demo/ledger_loop/priv/fake_idp/` — committed demo RSA-2048 keypair + self-signed cert PEM (demo-only secret)
- [x] `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — `relyra_certificates/0` `:pem` for scenario `…J0` set to the real cert (sourced from `Keypair.cert_pem/0`); `Demo.Reset` re-seeds it (Assumption A1 confirmed)
- [x] `demo/ledger_loop/lib/ledger_loop/application.ex` — `LoginTrace.attach(repo: LedgerLoop.Repo)` after `Supervisor.start_link`
- [x] `demo/ledger_loop/test/ledger_loop/fake_idp/signer_test.exs` — byte-compat + tamper (7 tests, green)
- [x] `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs` — end-to-end SP-initiated flow (2 tests, green)
- [x] Recovered + corrected `fake_idp_controller_test.exs` (scoped `/saml/<…J0>/acs`, 5 tests green)

Framework already present — no install needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | SEED-003 | All phase behaviors are reachable in-process via ConnTest/LiveViewTest — that is the explicit zero-human-UAT goal of this work | — |

*All phase behaviors have automated verification (in-process; no Wallaby, no human UAT).*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (keypair/cert, fixture PEM, LoginTrace.attach)
- [x] No watch-mode flags
- [x] Feedback latency < 10s (scoped suite 0.4s; full demo suite 0.8s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-14 — all 8 verification-map rows COVERED by green tests; 0 manual-only.

---

## Validation Audit 2026-06-14

State A audit of the planning-time draft. All planned verifications now exist on disk and run green; the draft's `⬜ pending` statuses were reconciled to executed reality. No `gsd-nyquist-auditor` spawn needed — zero gaps to fill.

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Coverage confirmation (run during audit):**
- `mix test` (scoped phase-57 4 files): 20 tests, 0 failures
- `mix test` (full demo suite): 57 tests, 0 failures

All 8 requirement→test mappings classified COVERED. No PARTIAL, no MISSING, no manual-only.
