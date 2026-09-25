---
phase: "74"
slug: "clean-room-package-consumer"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-24"
---

# Phase 74 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus repository shell harness |
| **Config file** | Generated consumer Mix/Phoenix configuration; harness in `scripts/` |
| **Quick run command** | `scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check` (available after Plan 74-04) |
| **Full suite command** | Blocking security job runs `--profile full`, `--profile minimal --concurrency-check`, and `--profile contracts` |
| **Estimated runtime** | Full QA measured at about 7 minutes, including the Phase 73 reconciliation replay; consumer profiles completed with isolated fresh dependency builds and owned PostgreSQL |

---

## Sampling Rate

- **After every task commit:** Run the focused harness profile or contract owner for changed behavior.
- **After every plan wave:** Run every focused package-consumer command implemented by that wave; after Wave 4, run full, minimal and contracts on both current CI tuples. The full and prior-scaffold runtime cases require owned PostgreSQL.
- **Before `$gsd-verify-work`:** Required CI owner, formatting, warnings-as-errors, and security lanes must be green.
- **Max feedback latency:** About 7 minutes for `mix qa`, including the fresh-process Phase 73 replay; individual package profiles completed faster.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 74-01-01 | 01 | 1 | PKG-01, PKG-02, PKG-03 | T-74-01, T-74-02, T-74-04 | Locally unpacked package boots Phoenix, queries owned PostgreSQL and posts one signed ACS response; host receipt is exact | integration | `scripts/check_clean_room_consumer.sh --profile full` | ✅ | ✅ pass |
| 74-01-02 | 01 | 1 | PKG-01, PKG-02 | T-74-01, T-74-03 | Source path is under artifact; compiled path is under isolated build; private support and checkout paths are unavailable | integration | `scripts/check_clean_room_consumer.sh --profile full` | ✅ | ✅ pass |
| 74-02-01 | 02 | 2 | PKG-04, PKG-02 | T-74-05, T-74-06 | Separate package/host migrations from pristine DB support configured request/replay adapters | integration | `scripts/check_clean_room_consumer.sh --profile full` | ✅ | ✅ pass |
| 74-02-02 | 02 | 2 | PKG-04 | T-74-06, T-74-07 | Migration reruns apply zero versions; concurrent duplicate store calls yield one success and one typed rejection | integration | `scripts/check_clean_room_consumer.sh --profile full` | ✅ | ✅ pass |
| 74-03-01 | 03 | 3 | PKG-02 | T-74-08 | Required-file omission fails for the named package contract, never a generic prerequisite error | negative | `scripts/check_clean_room_consumer.sh --profile contracts --case omission` | ✅ | ✅ pass |
| 74-03-02 | 03 | 3 | PKG-06, PKG-03 | T-74-09, T-74-10 | Fresh generated tree and installer receipt match exact golden files | integration | `scripts/check_clean_room_consumer.sh --profile contracts --case fresh` | ✅ | ✅ pass |
| 74-03-03 | 03 | 3 | PKG-06, PKG-03 | T-74-09, T-74-10 | Prior scaffold is preserved, compiles, boots and completes signed ACS through preserved callbacks/router; force is separate | integration | `scripts/check_clean_room_consumer.sh --profile contracts --case prior` | ✅ | ✅ pass |
| 74-04-01 | 04 | 4 | PKG-05, PKG-02 | T-74-11, T-74-12 | No-optional compile and two concurrent minimal consumers retain disjoint provenance | integration | `scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check` | ✅ | ✅ pass |
| 74-04-02 | 04 | 4 | PKG-01..PKG-06 | T-74-13 | One unconditional security job runs full, minimal and contracts on both current OTP tuples | CI integration | `mix test test/adoption/package_consumer_ci_contract_test.exs --warnings-as-errors`; `actionlint .github/workflows/security-gates.yml` | ✅ | ✅ pass |

---

## Wave 0 Requirements

- [x] A tracked harness builds and unpacks the local Hex artifact and creates disposable consumer/Mix/dependency/build/output paths.
- [x] An owned PostgreSQL 16 data directory/container is created and removed per full-profile or prior-scaffold runtime run.
- [x] The consumer exercises a valid signed ACS response using only shipped `Relyra.Testing` helpers and records the exact host-owned receipt after verification.
- [x] A controlled omitted-file artifact and named expected diagnostic are covered.
- [x] Fresh installer output has a golden comparison; the prior generated scaffold has byte-preservation and a current-runtime compile/boot/signed-ACS compatibility check.
- [x] One blocking CI workflow invokes the selected profiles on Elixir 1.19.5 with OTP 27 and 28.

---

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency measured at about 7 minutes for the complete QA/reconciliation lane
- [x] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** pending
