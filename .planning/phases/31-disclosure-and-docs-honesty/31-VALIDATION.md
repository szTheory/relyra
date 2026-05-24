---
phase: 31
slug: disclosure-and-docs-honesty
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-24
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
>
> **This is a documentation-only phase.** No `lib/` code changes, no new ExUnit
> tests. "Validation" here means **doc-gate compatibility**: the corrected docs
> and new advisory draft must keep the `mix ci.security` doc-check steps green
> (CONTEXT.md D-10/D-11). The doc-gate IS the validation surface.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `mix ci.security` alias (doc-check steps) + ExUnit meta-gate (unchanged this phase) |
| **Config file** | `mix.exs` `aliases/0` → `"ci.security"` (lines 152–180; doc-checks at 153–158) |
| **Quick run command** | `mix cmd test -f SECURITY_REVIEW.md && mix cmd test -f docs/security_boundary.md && mix cmd grep -nE "docs/security_findings.md\|Findings Ledger" SECURITY_REVIEW.md && mix relyra.security_review --check` |
| **Full suite command** | `mix ci.security` |
| **Estimated runtime** | ~5s for doc-gate steps; full `ci.security` ~60–120s (recompiles + crypto/corpus suites) |

---

## Sampling Rate

- **After every doc edit:** Re-run the four doc-gate steps (fast) — especially the `grep -nE` cross-ref after any `SECURITY_REVIEW.md` change.
- **After every task commit:** Run the quick doc-gate command above.
- **After every plan wave:** Run `mix ci.security` (proves no crypto/corpus regression AND doc-gate green).
- **Before `/gsd:verify-work`:** `mix ci.security` green + full `mix test` green.
- **Max feedback latency:** ~5 seconds (doc-gate steps).

---

## Per-Task Verification Map

> Doc-gate checks captured verbatim from `mix.exs` lines 153–158. The advisory
> draft has no content gate by design (D-09 / CONTEXT.md) — content correctness
> is a reviewer concern; do NOT add a brittle content-grep gate.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01 | 01 | 1 | DISC-01 | — | `SECURITY_REVIEW.md` still present | file-existence | `mix cmd test -f SECURITY_REVIEW.md` | ✅ | ⬜ pending |
| 31-01 | 01 | 1 | DISC-01 | — | `docs/security_boundary.md` still present | file-existence | `mix cmd test -f docs/security_boundary.md` | ✅ | ⬜ pending |
| 31-01 | 01 | 1 | DISC-01 | — | findings-ledger cross-ref still grep-matchable in `SECURITY_REVIEW.md` | grep | `mix cmd grep -nE "docs/security_findings.md\|Findings Ledger" SECURITY_REVIEW.md` | ✅ | ⬜ pending |
| 31-01 | 01 | 1 | DISC-01 | — | generated evidence not drifted (do not hand-edit; regenerate via generator if needed, D-11) | generator drift-check | `mix relyra.security_review --check` | ✅ | ⬜ pending |
| 31-01 | 01 | 1 | DISC-01 | — | corrected docs recompile clean | compile gate | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 31-02 | 02 | 1 | DISC-02 | — | advisory draft is a valid new file | file-existence | `test -f docs/advisories/2026-001-xmldsig-signature-not-verified.md` | ❌ W0 | ⬜ pending |
| 31-* | * | 2 | DISC-01/02 | — | full lane green after all edits | full gate | `mix ci.security` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. (Wave/Task IDs indicative — planner finalizes.)*

---

## Wave 0 Requirements

- [ ] `docs/advisories/` directory does not exist yet — created when the draft lands (no test infra needed; it is a doc).
- [ ] No new ExUnit test files required — the `mix ci.security` doc-gate is the validation surface.

*Existing doc-gate infrastructure covers all phase requirements. The only "new" artifact is the advisory draft file, validated by existence, not by an automated content assertion.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Corrected docs precisely state the real crypto guarantee (no overstatement; named primitive) | DISC-01 | Prose accuracy + brand-voice ("calm, exact, falsifiable") is a human judgment; no gate can assert wording | Read the three corrected docs; confirm each describes `:public_key.verify` over canonicalized `SignedInfo` vs **configured** IdP cert + constant-time `DigestValue` recompute, on both `verify/4` and `verify_metadata_root/4`; confirm no "bulletproof/unhackable/military-grade" language |
| Findings-ledger row is accurate (Critical, exploit path, disposition, regression proof refs) | DISC-01 | Content correctness of a single ledger row | Confirm the D-04 row replaces `none yet`, severity Critical, disposition "Confirmed → Fixed in v1.1 (hex 1.2.0)", cites `adversarial_crypto_test.exs` + `ci_gate_integrity_test.exs` |
| Advisory draft maps cleanly to the GHSA form + CVE request + CHANGELOG note | DISC-02 | Disclosure-document quality is reviewer-judged; staged-not-published (D-09) | Confirm GHSA body (summary, impact, affected `>=1.0.0,<1.2.0`, patched `1.2.0`, CVSS `9.1` vector, CWE-347, workaround=upgrade, credits, references), CVE-request subsection, and exact CHANGELOG prose are all present; confirm NO `gh`/publish/CVE-filing was performed |

---

## Validation Sign-Off

- [ ] DISC-01/DISC-02 tasks map to a doc-gate automated check OR a justified manual-only verification
- [ ] Sampling continuity: doc-gate re-run after each edit; full `mix ci.security` per wave
- [ ] No new test files needed (doc-gate is the surface) — confirmed
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s for doc-gate steps
- [x] `nyquist_compliant: true` set in frontmatter (doc-gate surface fully mapped)

**Approval:** pending
