---
phase: 48
slug: operator-completeness-incident-playbook-trace-tools
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` (`ci.docs` alias) |
| **Quick run command** | `grep` content checks per task verify blocks |
| **Full suite command** | `mix ci.docs` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run task `<verify>` grep commands
- **After every plan wave:** Run `mix ci.docs`
- **Before `/gsd-verify-work`:** `mix ci.docs` must exit 0
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | ADOPT-03 | T-48-01 | Playbook tables document trace route + CLI | grep | `grep "connections/:connection_id/trace" guides/operations/incident_playbook.md` | ✅ | ⬜ pending |
| 48-01-02 | 01 | 1 | ADOPT-03 | T-48-02 | Scenarios 3–6 Diagnose reference login trace | grep | `grep -c "login trace\|Login trace" guides/operations/incident_playbook.md` | ✅ | ⬜ pending |
| 48-01-03 | 01 | 1 | ADOPT-03 | T-48-03 | When in doubt splits diagnostic vs trace | grep | `grep "per-attempt\|step timeline" guides/operations/incident_playbook.md` | ✅ | ⬜ pending |
| 48-02-01 | 02 | 1 | ADOPT-03 | — | overview Day-2 links to playbook | grep | `grep "operations/incident_playbook" guides/overview.md` | ✅ | ⬜ pending |
| 48-02-02 | 02 | 1 | ADOPT-03 | — | getting_started §5 links to playbook | grep | `grep "operations/incident_playbook" guides/getting_started.md` | ✅ | ⬜ pending |
| 48-02-03 | 02 | 1 | ADOPT-03 | — | ci.docs green | integration | `mix ci.docs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 test stubs needed.

- [x] `mix ci.docs` presence gate on `guides/operations/incident_playbook.md`
- [x] `test/security/login_trace_test.exs` in `mix ci.security` (unchanged)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Playbook readability / scenario flow | ADOPT-03 | Prose quality | Skim Scenarios 3–6 Diagnose steps for natural reading order |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
