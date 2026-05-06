---
phase: 8
slug: resolver-adapter-snapshotting
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with optional Ecto SQL Sandbox-backed integration tests |
| **Config file** | `test/test_helper.exs` and `config/test.exs` |
| **Quick run command** | `mix test test/relyra/ecto/runtime_readiness_test.exs test/relyra/connection_test.exs test/phoenix/login_controller_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | < 30 seconds for per-task smoke commands |

---

## Sampling Rate

- **After every task commit:** Run the task-focused resolver or snapshot test plus `mix format --check-formatted`
- **After every plan wave:** Run `mix compile --warnings-as-errors`
- **Before `$gsd-verify-work`:** `mix test --warnings-as-errors` must be green
- **Max feedback latency:** < 30 seconds for per-task smoke commands

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-T01 | 08-01 | 1 | CFG-02 | TM-08-01-CONTRACT-DRIFT | Resolver contract and diagnostics stay bounded while moving toward canonical runtime snapshot output | unit | `mix test test/relyra/connection_test.exs test/phoenix/login_controller_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 08-01-T02 | 08-01 | 1 | CFG-02 | TM-08-01-CONTRACT-DRIFT | Default resolver failure docs and compatibility fixtures align with the canonical runtime certificate contract | unit | `mix test test/relyra/connection_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 08-02-T01 | 08-02 | 2 | CFG-02 | TM-08-02-BOUNDARY-LEAK | Ecto adapter resolves a persisted aggregate without leaking schemas above the boundary | integration | `mix test test/relyra/ecto/ecto_connection_resolver_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 08-02-T02 | 08-02 | 2 | CFG-02 | TM-08-02-NORMALIZATION-DRIFT | Snapshot hydrator applies defaults once and canonicalizes `idp_certificates` with compatibility-only `cert_chain` glue | unit | `mix test test/relyra/connection_snapshot_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 08-02-T03 | 08-02 | 2 | CFG-02 | TM-08-02-BOUNDARY-LEAK | Draft, disabled, missing-certificate, and repo-misconfigured cases fail closed with typed resolver diagnostics | integration/unit | `mix test test/relyra/ecto/ecto_connection_resolver_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 08-03-T01 | 08-03 | 3 | CFG-02 | TM-08-03-FLOW-DIVERGENCE | Login flow consumes the same normalized snapshot the Ecto adapter returns | integration | `mix test test/phoenix/login_controller_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 08-03-T02 | 08-03 | 3 | CFG-02 | TM-08-03-FLOW-DIVERGENCE | Metadata flow consumes the same normalized snapshot and preserves typed resolver failures | integration | `mix test test/phoenix/metadata_controller_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 08-03-T03 | 08-03 | 3 | CFG-02 | TM-08-03-FLOW-DIVERGENCE | Compatibility fixtures and boundary assertions prove runtime purity across resolver consumers | integration/unit | `mix test test/relyra/ecto/ecto_connection_resolver_test.exs test/phoenix/login_controller_test.exs test/phoenix/metadata_controller_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `test/relyra/ecto/ecto_connection_resolver_test.exs` — persisted lookup, failure mapping, and boundary-purity coverage for CFG-02
- [x] `test/relyra/connection_snapshot_test.exs` — provider default expansion, `idp_certificates` canonicalization, and compatibility-glue coverage
- [x] `test/phoenix/metadata_controller_test.exs` — persisted metadata flow through the resolver path
- [x] Resolver diagnostic assertions proving `details` remain redaction-safe and avoid raw payload dumps

Wave 0 is complete only when the missing test files exist and the new resolver-focused smoke commands run green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host-app Repo configuration ergonomics for the built-in Ecto resolver | CFG-02 | The repo can prove adapter behavior, but the adopter-facing setup contract still benefits from a direct docs review before phase closeout | Review resolver configuration examples and failure messaging to confirm missing-repo and optional-dependency guidance is explicit and operator-friendly |

---

## Validation Sign-Off

- [x] All planned tasks have an automated verification target
- [x] Wave 0 covers persisted resolver, snapshot normalization, and metadata-path gaps
- [x] Login and metadata flows share one normalized snapshot contract
- [x] Resolver diagnostics remain typed, bounded, and redaction-safe
- [x] `nyquist_compliant: true` set in frontmatter once Wave 0 and task verification are complete

**Approval:** complete
