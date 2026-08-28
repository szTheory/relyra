---
status: complete
phase: 68-build-caching-correctness
source: [68-VERIFICATION.md]
started: 2026-06-19T20:30:00.000Z
updated: 2026-06-19T21:10:00.000Z
---

## Current Test

[testing complete]

## Tests

### 1. DKR-01 build-cache receipt: build, edit a source .ex, rebuild
expected: Dependency layer shows CACHED on rebuild; `mix deps.get`/`mix deps.compile` do not re-run.
result: pass

### 2. DKR-02 arch-correctness receipt: `up` and inspect container deps
expected: No `wrong ELF class`/NIF load error on boot; container `deps/` are Linux-compiled and distinct from the masked macOS host `demo/ledger_loop/deps`.
result: pass
note: "Passes after two blockers found+fixed during UAT (see Gaps: dev.exs E-modifier regex; Dockerfile base image too old for relyra). After fixes: container boots clean on Elixir 1.19.5/OTP 28, relyra (130 files) compiles, migrations+seeds run, Phoenix serves GET / → 200. No wrong ELF class/NIF error. Separately observed: :fs_poll live-reload watcher crash loop (tracked under Test 4 / DKR-04). Port 4000 conflict with an unrelated container was worked around with PORT=4001."

### 3. DKR-03 re-resolution receipt: down/up/up, then touch mix.lock and up
expected: 2nd `up` skips `deps.get`/`deps.compile` (lock-hash stamp unchanged); a changed `mix.lock` triggers re-resolution; `ecto.create`/`relyra.migrate`/`ecto.migrate`/seeds run idempotently on every boot.
result: pass
note: "2nd boot (volumes kept) printed '==> mix.lock unchanged — skipping deps.get/deps.compile.'; 'Migrations already up' + seeds reset cleanly = ecto idempotent. Re-resolve branch (stamp-absent, same `then` block as sha-mismatch) was observed firing on the two earlier boots. Gate is sha256 of mix.lock content (entrypoint L14), so a plain `touch` would NOT trigger it — the verification doc's 'touch mix.lock' instruction is imprecise; a content change is required. fs_poll :dirs fix also confirmed here: clean 'Polling file changes every 500ms' with zero File.stat! crashes."

### 4. DKR-04 live-reload receipt: edit a .heex with browser open
expected: Browser reloads within ~500ms with no container restart and no dependency work (`:fs_poll` crosses the macOS→Docker mount).
result: pass
note: "After the fs_poll :dirs fix (see Gaps), edited the <h1> in home.html.heex with http://localhost:4001 open; browser auto-reloaded within ~500ms — user confirmed 'fast'. No container restart, no deps work, no fs_poll crash."

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0
note: All 4 runtime receipts (DKR-01..04) pass. 3 real defects found and fixed inline during UAT (see Gaps, all status resolved): dev.exs E-modifier regex (blocker), Dockerfile base image too old for relyra (blocker), fs_poll :dirs scope vs dangling colocated symlink (major).

## Gaps

- truth: "demo_app container boots cleanly under `docker compose --profile core up` (precondition for DKR-02/03/04 runtime receipts)."
  status: failed
  reason: "User reported: demo_app exited with code 1 — (Regex.CompileError) invalid_option at position E, config/config.exs:43 importing dev.exs."
  severity: blocker
  test: 2
  root_cause: "demo/ledger_loop/config/dev.exs lines 58/60/61 use the `~r\"...\"E` regex sigil. `E` is not a valid Elixir regex modifier on Elixir 1.15.7 (the Dockerfile-pinned and mix.exs-declared `~> 1.15` version). Pre-existing since commit b66722d0 (v1.7 demo); surfaced now because phase 68 is the first time the demo actually boots in Docker. Not a phase-68 build-caching defect, but it gates the phase goal."
  artifacts:
    - path: "demo/ledger_loop/config/dev.exs"
      issue: "Three `~r\"...\"E` live_reload patterns use an invalid `E` modifier"
  missing:
    - "Strip the `E` modifier from the three live_reload regex sigils (lines 58, 60, 61)"
  debug_session: ""
  resolution: "FIXED inline during UAT — removed the `E` modifier from all three sigils in demo/ledger_loop/config/dev.exs. Verified: config now loads, container proceeds past config compile."

- truth: "demo_app container compiles the relyra path dependency and boots (precondition for DKR-02/03/04)."
  status: failed
  reason: "User reported: after the dev.exs fix, compilation reached :relyra and failed — `:relyra requires Elixir \"~> 1.19\" but you are running on v1.15.7`; `(UndefinedFunctionError) function :json.decode/1 is undefined (module :json is not available)` at corpus_gate.ex:54. Container exited code 1."
  severity: blocker
  test: 2
  root_cause: "Dockerfile.dev (68-01) pinned base image `hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4`. relyra (compiled via `{:relyra, path: \"../..\"}`) requires `elixir: ~> 1.19` and uses the `:json` module (OTP 27+). The pinned image (Elixir 1.15.7 / OTP 26) cannot compile relyra. The whole project's CI standardizes on Elixir 1.19.5 / OTP 28. The phase-68 file-level verification confirmed the FROM pin existed but never checked version-compatibility with the library being built — a genuine phase-68 defect."
  artifacts:
    - path: "demo/ledger_loop/Dockerfile.dev"
      issue: "Base image Elixir 1.15.7 / OTP 26.1.2 too old to compile relyra (needs Elixir ~> 1.19, OTP 27+ for :json)"
  missing:
    - "Bump FROM to the project-blessed Elixir 1.19.5 / OTP 28 pair (hexpm/elixir:1.19.5-erlang-28.5.0.2-alpine-3.21.7)"
  debug_session: ""
  resolution: "FIXED inline during UAT — bumped Dockerfile.dev FROM to hexpm/elixir:1.19.5-erlang-28.5.0.2-alpine-3.21.7 (matches CI). Verified: relyra compiles (130 files), :json resolves, container boots and serves GET / → 200."

- truth: "DKR-04 — :fs_poll live-reload watcher runs without crashing so .heex/CSS edits reload (phase goal: live reload across the mount)."
  status: failed
  reason: "Observed during the DKR-02 boot: repeated `(File.Error) could not read file stats \".../_build/dev/phoenix-colocated/ledger_loop/node_modules\"` from file_system fs_poll.ex:77, then `Application phoenix_live_reload exited: shutdown`. Live reload is dead, so DKR-04 cannot pass as shipped."
  severity: major
  test: 4
  root_cause: "phoenix_live_reload 1.6.2 defaults `:dirs` to `[\"\"]` (whole project tree). Under Phoenix 1.8, `_build/dev/phoenix-colocated/ledger_loop/node_modules` is a symlink to `assets/node_modules`, which does not exist in this backend-only demo (no JS pipeline). `:fs_poll` does `File.stat!` (follows symlinks) on every walked entry → ENOENT → the watcher GenServer crashes in a loop and the live_reload app shuts down. Phase 68 set `backend: :fs_poll` for DKR-04 but did not scope `:dirs`, so the crash gates the very behavior DKR-04 requires."
  artifacts:
    - path: "demo/ledger_loop/config/dev.exs"
      issue: "`config :phoenix_live_reload` set :fs_poll backend but no `:dirs` scope, so it polls _build and hits the dangling colocated node_modules symlink"
  missing:
    - "Add `dirs: [\"lib/ledger_loop_web\", \"priv/static\"]` to the :phoenix_live_reload block so fs_poll watches only the reload-pattern source dirs (avoids _build and the dead symlink)"
  debug_session: ""
  resolution: "FIXED inline during UAT — added `dirs: [\"lib/ledger_loop_web\", \"priv/static\"]` to the :phoenix_live_reload block in dev.exs. Verified: clean 'Polling file changes every 500ms' with zero File.stat! crashes; .heex edit live-reloads in ~500ms (DKR-04 pass)."
