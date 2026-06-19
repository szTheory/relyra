---
status: testing
phase: 68-build-caching-correctness
source: [68-VERIFICATION.md]
started: 2026-06-19T20:30:00.000Z
updated: 2026-06-19T20:30:00.000Z
---

## Current Test

number: 1
name: DKR-01 build-cache receipt — build, edit a source .ex, rebuild
expected: |
  After a first `docker compose --profile core build`, editing any `.ex` under
  demo/ledger_loop/lib/ (NOT mix.exs/mix.lock) and rebuilding shows the dependency
  layer as CACHED; `mix deps.get`/`mix deps.compile` do NOT re-run.
awaiting: user response

## Tests

### 1. DKR-01 build-cache receipt: build, edit a source .ex, rebuild
expected: Dependency layer shows CACHED on rebuild; `mix deps.get`/`mix deps.compile` do not re-run.
result: [pending]

### 2. DKR-02 arch-correctness receipt: `up` and inspect container deps
expected: No `wrong ELF class`/NIF load error on boot; container `deps/` are Linux-compiled and distinct from the masked macOS host `demo/ledger_loop/deps`.
result: [pending]

### 3. DKR-03 re-resolution receipt: down/up/up, then touch mix.lock and up
expected: 2nd `up` skips `deps.get`/`deps.compile` (lock-hash stamp unchanged); a changed `mix.lock` triggers re-resolution; `ecto.create`/`relyra.migrate`/`ecto.migrate`/seeds run idempotently on every boot.
result: [pending]

### 4. DKR-04 live-reload receipt: edit a .heex with browser open
expected: Browser reloads within ~500ms with no container restart and no dependency work (`:fs_poll` crosses the macOS→Docker mount).
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
