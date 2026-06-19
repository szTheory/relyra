---
phase: 68
slug: build-caching-correctness
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-19
---

# Phase 68 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Docker/demo tooling — manual verification only.** No `lib/` change, so no `mix`
> gate is affected; `mix qa` / `mix ci.security` / `mix format --check-formatted` /
> `mix test --warnings-as-errors` stay green by construction (nothing this phase
> touches is compiled into the library or its test suite).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — Docker/Compose build + runtime behavior (manual receipts) |
| **Config file** | `docker-compose.yml`, `demo/ledger_loop/Dockerfile.dev` |
| **Quick run command** | `docker compose --profile core build` (dep-layer cache check) |
| **Full suite command** | `docker compose --profile core up` then exercise the 4 receipts below |
| **Estimated runtime** | ~60–180s cold build; <5s incremental edit/reload |

---

## Sampling Rate

- **After every task commit:** No automated suite — re-run the relevant manual receipt for the touched file (Dockerfile → build; entrypoint → `up`; dev.exs → live-reload).
- **After every plan wave:** Run the full `build` + `up` cycle and walk all four receipts.
- **Before `/gsd-verify-work`:** All four manual receipts must pass on the macOS host.
- **Max feedback latency:** ~180s (cold build) / <5s (incremental).

---

## Per-Task Verification Map

> No automated commands — every phase behavior is a manual Docker receipt (see table below).
> Tasks map to the four success criteria, not to a test runner.

| Criterion | Requirement | Threat Ref | Manual receipt | Status |
|-----------|-------------|------------|----------------|--------|
| Source-only edit doesn't re-run deps | DKR-01 | — | `build` once; edit a `.ex`; rebuild → dep layer `CACHED`, no `deps.get` | ⬜ pending |
| Named volumes mask bind mount, no NIF/arch breakage | DKR-02 | — | `up`; container boots, no `wrong ELF class`/NIF error; `exec demo_app ls deps` shows Linux-compiled deps distinct from host | ⬜ pending |
| Re-`up` re-resolves only when `mix.lock` changed | DKR-03 | — | `up` → `down` → `up`: second boot skips `deps.get` (stamp unchanged); touch `mix.lock` → next `up` re-resolves; ecto create/migrate/seed idempotent | ⬜ pending |
| `.heex`/CSS live reload across mount | DKR-04 | — | `up`; edit a `.heex`; browser reloads ~500ms, no restart, no `deps.get`. **Confirm corrected top-level `config :phoenix_live_reload` block (Pitfall 1) — #1 silent-failure risk** | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — no test framework needed for Docker tooling. The "tests" are the four manual receipts above.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dep-layer build cache | DKR-01 | BuildKit cache behavior is observable only in `docker build` output (`CACHED` layers), not assertable in Elixir | Build twice with a source edit between; confirm dep layer `CACHED` |
| Named-volume arch isolation | DKR-02 | Cross-OS (macOS host → Alpine container) NIF/arch correctness is a runtime property of the container, not a unit test | `up`, boot clean, inspect `deps` inside container vs host |
| Lock-hash gate idempotency | DKR-03 | Stamp-file gating spans `up`/`down`/volume lifecycle — only reproducible by cycling Compose | `up`/`down`/`up`; observe deps skipped unless `mix.lock` touched |
| Cross-mount live reload | DKR-04 | `:fs_poll` firing across the macOS→Docker bind-mount boundary is environment-specific; no in-process assertion | Edit `.heex` while `up`; observe browser auto-reload |

---

## Validation Sign-Off

- [x] All phase behaviors have a manual receipt (no automated suite applicable to Docker tooling)
- [x] Sampling continuity: each criterion has an explicit receipt
- [x] Wave 0 covers all MISSING references (none — no framework needed)
- [x] No watch-mode flags
- [x] Feedback latency acceptable for manual Docker workflow
- [x] `nyquist_compliant: true` set in frontmatter (manual-receipt regime for demo tooling)

**Approval:** approved 2026-06-19
