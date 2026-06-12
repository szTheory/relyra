---
phase: 52
slug: ecto-stores-and-deterministic-seed-story
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-12
---

# Phase 52 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Phoenix generated test setup |
| **Config file** | `demo/ledger_loop/test/test_helper.exs`; app config in `demo/ledger_loop/config/test.exs` |
| **Quick run command** | `cd demo/ledger_loop && mix test test/ledger_loop --warnings-as-errors` |
| **Full suite command** | `cd demo/ledger_loop && mix test --warnings-as-errors` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd demo/ledger_loop && mix test test/ledger_loop --warnings-as-errors`
- **After every plan wave:** Run `cd demo/ledger_loop && mix test --warnings-as-errors`
- **Before `$gsd-verify-work`:** Run `cd demo/ledger_loop && mix format --check-formatted && mix test --warnings-as-errors`
- **Root safety gate:** If any root Relyra files change, also run `mix format --check-formatted`, `mix test --warnings-as-errors`, and `mix ci.security`
- **Max feedback latency:** 90 seconds for demo-only checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | DATA-01 | T-52-01 | Reset uses stable fixture IDs/timestamps and never relies on wall clock for seeded story rows | integration | `cd demo/ledger_loop && mix test test/ledger_loop/demo/reset_test.exs --warnings-as-errors` | no - W0 | pending |
| 52-01-02 | 01 | 1 | DATA-02 | T-52-02 | Seeded scenarios are queryable and redaction-safe | integration/query | `cd demo/ledger_loop && mix test test/ledger_loop/demo/connection_scenarios_test.exs --warnings-as-errors` | no - W0 | pending |
| 52-02-01 | 02 | 1 | ECTO-01 | T-52-03 | Relyra migrations run from `../../priv/repo/migrations` and are not copied into the demo app | integration/source | `cd demo/ledger_loop && mix test test/ledger_loop/relyra/migrations_test.exs --warnings-as-errors` | no - W0 | pending |
| 52-03-01 | 03 | 2 | ECTO-03 | T-52-04 | Request/replay storage targets are fixed in host code and cannot be influenced by request values | unit/source | `cd demo/ledger_loop && mix test test/ledger_loop/relyra/store_wrapper_test.exs --warnings-as-errors` | no - W0 | pending |
| 52-04-01 | 04 | 3 | ECTO-02 | T-52-05 | Non-browser signed login uses Ecto connection, request, and replay stores | integration | `cd demo/ledger_loop && mix test test/ledger_loop/relyra/ecto_happy_path_test.exs --warnings-as-errors` | no - W0 | pending |
| 52-05-01 | 05 | 3 | ECTO-04 | T-52-06 | Host mapper/session code runs only after Relyra returns a verified principal and persists host-owned proof | integration | `cd demo/ledger_loop && mix test test/ledger_loop/relyra/host_boundary_test.exs --warnings-as-errors` | no - W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs` - stubs for DATA-01 determinism.
- [ ] `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` - stubs for DATA-02 seeded scenario inspection.
- [ ] `demo/ledger_loop/test/ledger_loop/relyra/migrations_test.exs` - stubs for ECTO-01 dependency-path migration proof.
- [ ] `demo/ledger_loop/test/ledger_loop/relyra/store_wrapper_test.exs` - stubs for ECTO-03 fixed table wrappers.
- [ ] `demo/ledger_loop/test/ledger_loop/relyra/ecto_happy_path_test.exs` - stubs for ECTO-02 Ecto connection/request/replay happy path.
- [ ] `demo/ledger_loop/test/ledger_loop/relyra/host_boundary_test.exs` - stubs for ECTO-04 mapper/session host boundary.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | N/A | All Phase 52 behavior has automated ExUnit coverage before phase verification | N/A |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for demo-only checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
