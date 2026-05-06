---
phase: 12
slug: metadata-refresh-trust-state-repair
status: ready_for_verify
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix on Elixir `1.19.5` |
| **Config file** | `mix.exs`, `test/test_helper.exs`, and `config/test.exs` |
| **Quick run command** | `mix test test/relyra/metadata_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | < 60 seconds for the phase-focused smoke commands |

---

## Sampling Rate

- **After every task commit:** Run the task-specific smoke command plus `mix format --check-formatted`
- **After every plan wave:** Run `mix compile --warnings-as-errors`
- **Before `$gsd-verify-work`:** `mix test --warnings-as-errors` must be green
- **Max feedback latency:** < 60 seconds for the phase-focused smoke commands

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-T01 | 12-01 | 1 | CFG-03 | T-12-01-01 / T-12-01-02 | Metadata-derived certificate inputs normalize into one canonical internal shape for valid inputs while malformed cert bodies still fail with typed `:invalid_certificate_pem` | unit/integration | `mix test test/relyra/metadata_test.exs test/relyra/ecto/certificate_inventory_expiry_test.exs --warnings-as-errors` | ✅ existing | ⬜ pending |
| 12-02-T01 | 12-02 | 2 | CFG-03 | T-12-02-01 / T-12-02-02 | Import and refresh share the repaired apply seam, preserve last-known-good state on failure, and keep new metadata certificates staged instead of active | integration | `mix test test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors` | ✅ existing | ⬜ pending |
| 12-03-T01 | 12-03 | 3 | CFG-03 | T-12-03-01 | Requirement closure is backed by focused smoke, full-suite proof, and explicit verification traceability for Phase 09 | verification | `mix test test/relyra/metadata_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/metadata_refresh_test.exs --warnings-as-errors && mix test --warnings-as-errors` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Task-Local Nyquist Ordering

- Phase 12 relies on existing metadata, apply, refresh, and certificate-expiry test files; no task-first test creation is required.
- Verification must remain serial because the milestone audit already identified parallel migration bootstrap races as a false-failure footgun.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Imported metadata still collapses multiple published SSO endpoints into one predictable runtime value | CFG-03 | Automated tests prove the selection rule, but a human should still confirm the chosen endpoint remains the intended least-surprise operator behavior after the repair | Review the endpoint-selection assertions and resulting docs/error text to confirm HTTP-Redirect remains preferred over HTTP-POST over remaining endpoints |
| Operator-facing refresh semantics remain explicit write-side verbs rather than runtime-resolution behavior | CFG-03 | Tests can prove isolation, but wording and docs still need a human pass for DX clarity | Review `Relyra.Metadata.import_xml/3`, `register_source/3`, and `refresh/2` docs/error text after execution and confirm they read as explicit metadata-management operations |

---

## Validation Sign-Off

- [x] Every expected execution task has an automated verification target
- [x] Sampling continuity covers normalization, apply, refresh, and final requirement closure
- [x] No watch-mode or parallel-only commands are required
- [x] Serial execution is explicitly required where migration bootstrap races could create false failures
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
