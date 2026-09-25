---
phase: "74"
slug: "clean-room-package-consumer"
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Estimated runtime** | To be measured during first implementation; full profile includes fresh dependency build and PostgreSQL |

---

## Sampling Rate

- **After every task commit:** Run the focused harness profile or contract owner for changed behavior.
- **After every plan wave:** Run every focused package-consumer command implemented by that wave; after Wave 4, run full, minimal and contracts on both current CI tuples. The full and prior-scaffold runtime cases require owned PostgreSQL.
- **Before `$gsd-verify-work`:** Required CI owner, formatting, warnings-as-errors, and security lanes must be green.
- **Max feedback latency:** To be measured during implementation; no timing assertion until an observed baseline exists.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 74-01-01 | 01 | 1 | PKG-01, PKG-02, PKG-03 | T-74-01, T-74-02, T-74-04 | Locally unpacked package boots Phoenix, queries owned PostgreSQL and posts one signed ACS response; host receipt is exact | integration | `scripts/check_clean_room_consumer.sh --profile full` | ❌ Plan 01 creates | ⬜ pending |
| 74-01-02 | 01 | 1 | PKG-01, PKG-02 | T-74-01, T-74-03 | Source path is under artifact; compiled path is under isolated build; private support and checkout paths are unavailable | integration | `scripts/check_clean_room_consumer.sh --profile full` | ❌ Plan 01 creates | ⬜ pending |
| 74-02-01 | 02 | 2 | PKG-04, PKG-02 | T-74-05, T-74-06 | Separate package/host migrations from pristine DB support configured request/replay adapters | integration | `scripts/check_clean_room_consumer.sh --profile full` | ❌ Plan 02 creates | ⬜ pending |
| 74-02-02 | 02 | 2 | PKG-04 | T-74-06, T-74-07 | Migration reruns apply zero versions; concurrent duplicate store calls yield one success and one typed rejection | integration | `scripts/check_clean_room_consumer.sh --profile full` | ❌ Plan 02 creates | ⬜ pending |
| 74-03-01 | 03 | 3 | PKG-02 | T-74-08 | Required-file omission fails for the named package contract, never a generic prerequisite error | negative | `scripts/check_clean_room_consumer.sh --profile contracts --case omission` | ❌ Plan 03 creates | ⬜ pending |
| 74-03-02 | 03 | 3 | PKG-06, PKG-03 | T-74-09, T-74-10 | Fresh generated tree and installer receipt match exact golden files | integration | `scripts/check_clean_room_consumer.sh --profile contracts --case fresh` | ❌ Plan 03 creates | ⬜ pending |
| 74-03-03 | 03 | 3 | PKG-06, PKG-03 | T-74-09, T-74-10 | Prior scaffold is preserved, compiles, boots and completes signed ACS through preserved callbacks/router; force is separate | integration | `scripts/check_clean_room_consumer.sh --profile contracts --case prior` | ❌ Plan 03 creates | ⬜ pending |
| 74-04-01 | 04 | 4 | PKG-05, PKG-02 | T-74-11, T-74-12 | No-optional compile and two concurrent minimal consumers retain disjoint provenance | integration | `scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check` | ❌ Plan 04 creates | ⬜ pending |
| 74-04-02 | 04 | 4 | PKG-01..PKG-06 | T-74-13 | One unconditional security job runs full, minimal and contracts on both current OTP tuples | CI integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/adoption/package_consumer_ci_contract_test.exs --warnings-as-errors`; `actionlint .github/workflows/security-gates.yml` | ❌ Plan 04 creates test | ⬜ pending |

---

## Wave 0 Requirements

- [ ] A tracked harness builds and unpacks the local Hex artifact and creates disposable consumer/Mix/dependency/build/output paths.
- [ ] An owned PostgreSQL 16 data directory/container is created and removed per full-profile or prior-scaffold runtime run.
- [ ] The consumer exercises a valid signed ACS response using only shipped `Relyra.Testing` helpers and records the exact host-owned receipt after verification.
- [ ] A controlled omitted-file artifact and named expected diagnostic are covered.
- [ ] Fresh installer output has a golden comparison; the prior generated scaffold has byte-preservation and a current-runtime compile/boot/signed-ACS compatibility check.
- [ ] One blocking CI workflow invokes the selected profiles on Elixir 1.19.5 with OTP 27 and 28.

---

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency measured and below the agreed bound
- [ ] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** pending
