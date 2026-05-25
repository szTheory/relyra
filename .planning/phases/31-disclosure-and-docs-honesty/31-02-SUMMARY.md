---
phase: 31-disclosure-and-docs-honesty
plan: 02
subsystem: docs
tags: [security, disclosure, advisory, ghsa, cve]
key-files:
  created:
    - docs/advisories/2026-001-xmldsig-signature-not-verified.md
  modified: []
requirements-completed: [DISC-02]
metrics:
  completed: 2026-05-24
---

# Phase 31 Plan 02: Staged advisory draft Summary

Created the checked-in advisory draft at `docs/advisories/2026-001-xmldsig-signature-not-verified.md`, mapped to the GitHub repository advisory form, and staged the ship-time CVE-request fields plus release-note prose without editing `CHANGELOG.md`, `SECURITY.md`, or generated artifacts.

## Accomplishments

- Added a staged GHSA-style advisory body carrying the internal id `RELYRA-2026-001`, affected range `>= 1.0.0, < 1.2.0`, patched version `1.2.0`, CVSS 3.1 `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N`, and `CWE-347`.
- Documented the missing primitive in `1.0.0` and `1.1.0` and the `1.2.0` fix in exact terms: exclusive-C14N, `:public_key.verify`, and constant-time `DigestValue` recompute on both verification paths.
- Added a pre-staged `CVE request` section and an exact `CHANGELOG security note` section while explicitly stating that release-please does not generate a dedicated Security section and that publication remains a ship-time action.

## Task Commits

1. **Task 1: Create the staged GHSA advisory draft body** - `1724218` (`docs(31-02): stage GHSA advisory draft body`)
2. **Task 2: Append CVE-request fields and release-note prose** - `678f316` (`docs(31-02): add CVE request and release-note staging`)

## Verification

- `test -f docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `grep -q "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N" docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `grep -q "CWE-347" docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `grep -q "RELYRA-2026-001" docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `grep -qE ">= ?1\\.0\\.0, ?< ?1\\.2\\.0" docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `grep -qE "[Pp]atched.*1\\.2\\.0" docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `grep -q "adversarial_crypto_test.exs" docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `grep -qiE "CVE request|Request CVE" docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `grep -qi "CHANGELOG" docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- `git diff --quiet CHANGELOG.md SECURITY.md SECURITY_REVIEW_EVIDENCE.md`

## Deviations from Plan

None.

## Self-Check: PASSED

- FOUND: `docs/advisories/2026-001-xmldsig-signature-not-verified.md`
- FOUND: `.planning/phases/31-disclosure-and-docs-honesty/31-02-SUMMARY.md`
- FOUND commit `1724218`
- FOUND commit `678f316`

---
*Phase: 31-disclosure-and-docs-honesty*
*Completed: 2026-05-24*
