---
phase: 02
slug: protocol-and-signature-core
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/security --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/security --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | PROT-01 | T-02-01 | AuthnRequest fields and IDs are deterministic and complete | unit | `mix test test/protocol/authn_request_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | SEC-07 | T-02-02 | RelayState accepts opaque `rs_` handles and rejects raw URL payloads | unit | `mix test test/protocol/relay_state_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 1 | SEC-02, SEC-05 | T-02-03 | Signature trust uses configured certs only and enforces algorithm policy | unit | `mix test test/security/signature_policy_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 1 | SEC-03, SEC-04 | T-02-04 | Signed-node binding and duplicate XML ID detection reject wrapping indicators | unit | `mix test test/security/signed_node_binding_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 2 | PROT-02, PROT-03, PROT-05 | T-02-05 | Validation pipeline enforces issuer/audience/recipient/destination/status/time checks with typed failures | integration | `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/protocol/authn_request_test.exs` — add request-shape and ID contracts for PROT-01
- [ ] `test/protocol/relay_state_test.exs` — add opaque RelayState security tests for SEC-07
- [ ] `test/security/signature_policy_test.exs` — add trust-source and algorithm policy tests for SEC-02 and SEC-05
- [ ] `test/security/signed_node_binding_test.exs` — add signed-node binding and duplicate-ID cases for SEC-03 and SEC-04
- [ ] `test/protocol/consume_response_pipeline_test.exs` — add typed pipeline outcomes for PROT-02/03/05

---

## Manual-Only Verifications

All phase behaviors have automated verification targets. No manual-only checks are required.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
