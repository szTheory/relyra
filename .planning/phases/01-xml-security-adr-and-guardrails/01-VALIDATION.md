---
phase: 01
slug: xml-security-adr-and-guardrails
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir/OTP) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test --warnings-as-errors` |
| **Full suite command** | `mix qa` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test --warnings-as-errors`
- **After every plan wave:** Run `mix qa`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | GATE-01 | T-01-ADR | XML strategy decision documented with rationale and fallback criteria | doc-check | `rg "pure BEAM|hybrid|xmlsec|fallback" .planning/phases/01-xml-security-adr-and-guardrails/01-*` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | SEC-01, GATE-01 | T-01-SEAM | Only seam callbacks define trust path (`parse_safely/2`, `select_signed_node/2`, `canonicalize/2`) | unit/static | `mix test --only xml_seam --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 1 | GATE-01 | T-01-ERR | Typed `%Relyra.Error{}` atoms remain deterministic for malformed and hostile XML | unit/property | `mix test --only xml_errors --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 2 | GATE-02, SEC-01 | T-01-FIXTURES | Adversarial corpus classes present with expected rejection atoms | integration | `mix test --only security_corpus --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 01-03-02 | 03 | 2 | GATE-03 | T-01-NIF-POLICY | Conditional NIF matrix and checksum policy locked in ADR/guardrail docs | doc-check | `rg "checksum|matrix|nif|precompiled" .planning/phases/01-xml-security-adr-and-guardrails/01-*` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/security/xml/seam_contract_test.exs` — seam contract stubs for `SEC-01` and `GATE-01`
- [ ] `test/security/xml/error_atoms_test.exs` — typed rejection stability checks
- [ ] `test/security/xml/corpus_security_test.exs` — adversarial corpus gate for `GATE-02`
- [ ] `test/fixtures/security/xml/manifest.json` — fixture metadata and expected rejection types

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ADR quality gate for strategy rationale and tradeoffs | GATE-01 | Narrative quality and decision justification cannot be fully automated | Reviewer confirms ADR includes alternatives, tradeoffs, and explicit fallback trigger |
| Conditional NIF policy completeness when pure BEAM remains default | GATE-03 | Policy may remain dormant but must be complete and release-ready | Reviewer confirms target matrix, checksum workflow, and activation criteria are documented |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
