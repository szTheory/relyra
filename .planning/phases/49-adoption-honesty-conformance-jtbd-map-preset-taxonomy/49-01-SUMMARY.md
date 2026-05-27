---
phase: 49-adoption-honesty-conformance-jtbd-map-preset-taxonomy
plan: 01
subsystem: testing
tags: [conformance, manifest, encrypted-assertions, adopt-04]

requires:
  - phase: 48-operator-completeness-incident-playbook-trace-tools
    provides: v1.6 doc-only milestone context and ci gate patterns
provides:
  - Scope boundary & diminishing returns section in conformance generator
  - sp-encrypted-assertions-pass manifest row with executable positive control
  - Regenerated CONFORMANCE.md with 9 pass / 0 deferred summary
affects:
  - 49-02-PLAN (jtbd_gap_map refresh)
  - 49-03-PLAN (preset taxonomy alignment)

tech-stack:
  added: []
  patterns:
    - "Generator-only CONFORMANCE.md edits via mix relyra.conformance"
    - "Encrypted assertion positive control via FakeIdP.encrypted_response in evaluate_row"

key-files:
  created: []
  modified:
    - lib/mix/tasks/relyra.conformance.ex
    - priv/conformance/sp_manifest.json
    - test/conformance/sp_conformance_test.exs
    - CONFORMANCE.md

key-decisions:
  - "Scope boundary section appended after CVE-REG-01 table in render_report/1"
  - "SPConformanceTest async: false for Application.put_env SP private key setup"
  - "XmldsigSigner.self_signed_cert_pem retained in connection/0 — delegates to FakeIdP keypair"

patterns-established:
  - "ENC manifest pass rows require evaluate_row positive control before flip"

requirements-completed: [ADOPT-04]

duration: 5min
completed: 2026-05-27
---

# Phase 49 Plan 01: CONFORMANCE scope boundary + ENC manifest Summary

**ADOPT-04 delivered: generator emits scope-boundary section, ENC row passes with FakeIdP encrypted assertion positive control, CONFORMANCE.md regenerated with 9 pass / 0 deferred.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-27T22:22:00Z
- **Completed:** 2026-05-27T22:27:57Z
- **Tasks:** 4 completed
- **Files modified:** 4

## Accomplishments

- Added `scope_boundary_section/0` to `Mix.Tasks.Relyra.Conformance` with v0.x→v1.5 arc, demand-gated out-of-scope list, and done-enough framing
- Flipped `sp-encrypted-assertions-deferred` → `sp-encrypted-assertions-pass` in manifest
- Added executable `evaluate_row/1` for encrypted assertions using `FakeIdP.encrypted_response/2`
- Regenerated `CONFORMANCE.md`; `mix ci.conformance` and `mix relyra.conformance --check` green

## Task Commits

Each task was committed atomically:

1. **Task 1: Add scope boundary section to conformance generator** - `93418a6` (feat)
2. **Task 2: Flip ENC manifest row to pass** - `f865174` (feat)
3. **Task 3: Add encrypted assertion evaluate_row and SP key setup** - `da47483` (test)
4. **Task 4: Regenerate CONFORMANCE.md and verify ci.conformance** - `11f1fc0` (docs)

**Plan metadata:** `4dc11ee` (docs: complete plan)

## Files Created/Modified

- `lib/mix/tasks/relyra.conformance.ex` — `scope_boundary_section/0` appended after CVE-REG-01 table
- `priv/conformance/sp_manifest.json` — ENC row renamed and status flipped to pass
- `test/conformance/sp_conformance_test.exs` — encrypted assertion evaluate_row + SP key setup, async: false
- `CONFORMANCE.md` — regenerated with scope section and updated requirement summary

## Decisions Made

- Scope boundary prose follows STRATEGIC-ASSESSMENT diminishing-returns framing and 49-CONTEXT D-01/D-02
- Kept `XmldsigSigner.self_signed_cert_pem()` in `connection/0` — same FakeIdP keypair as encrypted_response signer
- No hand-edits to CONFORMANCE.md — generator-only path per project invariant

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Verification

| Check | Result |
|-------|--------|
| `mix test test/conformance/sp_conformance_test.exs --only conformance --warnings-as-errors` | PASS |
| `mix relyra.conformance --check` | PASS |
| `mix ci.conformance` | PASS |
| CONFORMANCE.md pass count 9, deferred 0 | PASS |
| Scope boundary section present | PASS |

## Self-Check: PASSED

- Key files exist on disk: verified
- Commits grep `49-01`: 4 task commits found
- All acceptance criteria re-run: PASS
- Plan-level verification: PASS

## Next Phase Readiness

Ready for 49-02-PLAN (ADOPT-05 jtbd_gap_map refresh). ADOPT-04 complete; ci.conformance gate holds.

---
*Phase: 49-adoption-honesty-conformance-jtbd-map-preset-taxonomy*
*Completed: 2026-05-27*
