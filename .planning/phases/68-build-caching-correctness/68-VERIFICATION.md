---
phase: 68-build-caching-correctness
verified: 2026-06-19T00:00:00Z
status: human_needed
score: 4/4 file-level contracts verified (4 runtime behaviors require human verification)
behavior_unverified: 4
overrides_applied: 0
behavior_unverified_items:
  - truth: "DKR-01 — a source-only edit rebuilds the demo image without re-running mix deps.get/deps.compile (dependency layer stays CACHED)."
    test: "Run `docker compose --profile core build` (first build compiles dep layer). Edit any .ex under demo/ledger_loop/lib/ (NOT mix.exs/mix.lock). Run `docker compose --profile core build` again."
    expected: "Second build shows the dependency layer as CACHED; `mix deps.get`/`mix deps.compile` do NOT re-run."
    why_human: "Requires a BuildKit build round-trip; cache-hit on rebuild is a runtime build-engine behavior grep cannot observe. The file-level contract (COPY-before-source split, two cache mounts, pinned base) is statically VERIFIED."
  - truth: "DKR-02 — named volumes mask the bind mount at the nested demo paths so macOS host artifacts never leak in; container boots with no `wrong ELF class`/NIF error."
    test: "Run `docker compose --profile core up`. Then `docker compose --profile core exec demo_app ls deps`."
    expected: "Container boots with NO `(RuntimeError) ... wrong ELF class`/NIF load failure; container deps/ are Linux-compiled and distinct from the masked macOS host demo/ledger_loop/deps."
    why_human: "Requires running the container and observing NIF load + arch correctness at runtime. The file-level contract (relyra_deps/relyra_build mounted at the nested /app/demo/ledger_loop/{deps,_build}; no generic /app/deps or /app/_build) is statically VERIFIED."
  - truth: "DKR-03 — a second `up` after `down` re-resolves dependencies only when mix.lock changed (lock-hash stamp) and runs ecto.create/migrate idempotently."
    test: "`up`, then `down`, then `up` again (observe no deps.get on 2nd boot). Then `touch demo/ledger_loop/mix.lock` and `up` (observe re-resolution). Confirm ecto.create/relyra.migrate/ecto.migrate/seeds run without error on every boot."
    expected: "Second boot skips deps.get/deps.compile (stamp in relyra_build volume unchanged); a changed mix.lock triggers re-resolution; ecto steps are idempotent across re-up."
    why_human: "Requires down/up cycles with persisted volume state — a runtime stamp-persistence + idempotency invariant. The file-level contract (sha256 lock-hash gate, stamp at _build/.docker/mix.lock.sha inside relyra_build, ecto ordering matching the ecto.setup alias) is statically VERIFIED."
  - truth: "DKR-04 — editing a LiveView .heex template or stylesheet live-reloads in the browser with no container restart and no dependency work (:fs_poll crosses the macOS→Docker mount)."
    test: "`up`; open the app in a browser. Edit a .heex template under demo/ledger_loop/lib/ledger_loop_web/ and save."
    expected: "Browser reloads within ~500ms with NO container restart and NO deps.get."
    why_human: "Requires a running server, the macOS→Docker bind mount, and a browser observing a live reload — none observable by grep. The file-level contract (top-level config :phoenix_live_reload, backend: :fs_poll, backend_opts: [interval: 500], correctly NOT inside the Endpoint live_reload: keyword) is statically VERIFIED."
human_verification:
  - test: "DKR-01 build-cache receipt: build, edit a source .ex, rebuild."
    expected: "Dependency layer shows CACHED; mix deps.get does not re-run."
    why_human: "BuildKit build round-trip; cache behavior is runtime-only."
  - test: "DKR-02 arch-correctness receipt: `up` and inspect container deps."
    expected: "No wrong ELF class/NIF error; container deps distinct from host."
    why_human: "Requires running container; NIF/arch correctness is runtime-only."
  - test: "DKR-03 re-resolution receipt: down/up/up, then touch mix.lock and up."
    expected: "2nd up skips deps.get; changed lock re-resolves; ecto idempotent."
    why_human: "Requires down/up cycles with persisted volume state."
  - test: "DKR-04 live-reload receipt: edit a .heex with browser open."
    expected: "Browser reloads ~500ms, no restart, no deps.get."
    why_human: "Requires running server + browser observing a cross-mount live reload."
---

# Phase 68: Build caching & correctness — Verification Report

**Phase Goal:** A developer iterates on the demo in Docker as fast as native — small source/style edits reload instantly and never trigger a dependency re-fetch or recompile.
**Verified:** 2026-06-19
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

This is a v1.10 Docker-DX phase. Every Success Criterion is a **runtime/behavioral** container or browser invariant (image rebuild cache behavior, NIF/arch correctness on boot, second-`up` lock-hash re-resolution, cross-mount browser live-reload). Per the verification mandate, the **file-level contracts** that enable each behavior are statically verified here; the behaviors themselves — which genuinely require a Docker build+up round-trip and a browser — are routed to human verification rather than failed.

All four file-level contracts are present, substantive, and wired. No file-level gap was found. No `lib/` or `test/` change exists (milestone invariant holds).

### Observable Truths

| # | Truth (Success Criterion) | Status | Evidence |
|---|---------------------------|--------|----------|
| 1 | DKR-01: source-only edit → dep layer stays CACHED, no deps.get/compile | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | File contract VERIFIED: `# syntax=docker/dockerfile:1.7` header (L1), pinned `FROM hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4` (L2), `COPY demo/ledger_loop/mix.exs demo/ledger_loop/mix.lock ./` (L16) BEFORE `RUN ... mix deps.get && mix deps.compile` (L22-25), 2 BuildKit cache mounts. No `COPY . .`. Runtime cache-hit needs a build round-trip → human verify. |
| 2 | DKR-02: named volumes mask bind mount; no NIF/arch error on boot | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | File contract VERIFIED: `relyra_deps:/app/demo/ledger_loop/deps` + `relyra_build:/app/demo/ledger_loop/_build` at NESTED paths (compose L27-28); zero generic `/app/deps`//`/app/_build`. Runtime boot + ELF/NIF check needs `up` → human verify. |
| 3 | DKR-03: 2nd `up` re-resolves only on lock change; ecto idempotent | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | File contract VERIFIED: sha256 lock-hash gate vs stamp `_build/.docker/mix.lock.sha` in relyra_build volume (entrypoint L13-24); ecto.create → ledger_loop.relyra.migrate → ecto.migrate → seeds (L29,34,37,40) matches mix.exs `ecto.setup` alias exactly. Runtime down/up persistence + idempotency needs containers → human verify. |
| 4 | DKR-04: `.heex`/CSS edit live-reloads cross-mount, no restart/deps | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | File contract VERIFIED: top-level `config :phoenix_live_reload, backend: :fs_poll, backend_opts: [interval: 500]` (dev.exs L69-71), correctly OUTSIDE the Endpoint `live_reload:` keyword (L53-63, no `backend:` inside — Pitfall 1 avoided). Runtime browser reload across the mount needs `up` + browser → human verify. |

**Score:** 4/4 file-level contracts verified; 4/4 runtime behaviors present-but-behavior-unverified (routed to human verification).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `demo/ledger_loop/Dockerfile.dev` | Cached dev image: 1.7 syntax, pinned FROM, D-03 apk list + curl, COPY-before-source, 2 cache mounts, COPY+chmod+ENTRYPOINT | ✓ VERIFIED | 33 lines. Header L1, pinned FROM L2, apk list L8 (inotify-tools bash postgresql-client build-base git openssl curl), COPY-before-RUN, 2 cache mounts, ENTRYPOINT L33. No `COPY . .`, no build-time relyra compile. |
| `demo/ledger_loop/docker-entrypoint.sh` | Boot gate: local.hex/rebar --if-missing, lock-hash gate, ecto.create→relyra.migrate→ecto.migrate→seeds, `exec "$@"` | ✓ VERIFIED | 43 lines, executable, `bash -n` clean, `set -euo pipefail`. Stamp at `_build/.docker/mix.lock.sha`. Real (non-comment) ordering: relyra.migrate L34 before ecto.migrate L37. `exec "$@"` L43. |
| `.dockerignore` | Repo-root build-context exclusions | ✓ VERIFIED | `.git/`, `.planning/`, root + demo-nested `_build/`/`deps/`, node_modules/, priv/static/assets/, docker-compose*.yml, *.tar, OS cruft all present. |
| `docker-compose.yml` | demo_app overlay: build, command, nested named volumes, top-level volumes keys | ✓ VERIFIED | `dockerfile: demo/ledger_loop/Dockerfile.dev` (context `.`), `command: mix phx.server`, 4 nested named volumes, top-level `volumes:` with all 4 keys. No inline `apk add`. PGPORT/db/keycloak/playwright untouched. `docker compose config` exits 0. |
| `demo/ledger_loop/config/dev.exs` | Top-level :phoenix_live_reload :fs_poll block | ✓ VERIFIED | Single `config :phoenix_live_reload` block L69-71; `backend: :fs_poll` + `backend_opts: [interval: 500]`; Endpoint `live_reload:` keyword unchanged (web_console_logger + patterns intact); no `backend:` nested in Endpoint. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| Dockerfile.dev | docker-entrypoint.sh | COPY + ENTRYPOINT | ✓ WIRED | COPY L31, ENTRYPOINT L33 both reference `/usr/local/bin/docker-entrypoint.sh`. |
| docker-compose.yml demo_app.build | Dockerfile.dev | build.dockerfile, context `.` | ✓ WIRED | compose L19-20. |
| docker-compose.yml demo_app.volumes | container deps/_build | nested-path named volumes | ✓ WIRED | compose L27-28 mount relyra_deps/relyra_build at the nested working_dir subpaths. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| compose file resolves | `docker compose config` | exit 0 | ✓ PASS |
| entrypoint valid bash | `bash -n docker-entrypoint.sh` | exit 0 | ✓ PASS |
| entrypoint executable | `test -x` | true | ✓ PASS |
| ecto ordering matches alias | compare entrypoint vs mix.exs `ecto.setup` | identical order | ✓ PASS |
| Container cache/boot/reload behaviors | requires `docker build`+`up`+browser | not run (>10s, starts services) | ? SKIP → human verify |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DKR-01 | 68-01 | Dedicated Dockerfile.dev, COPY mix files before source, cached dep layer + BuildKit cache mounts | ✓ SATISFIED (file contract) / ? NEEDS HUMAN (runtime cache) | Dockerfile.dev contract verified; cache-hit behavior → human verify |
| DKR-02 | 68-02 | deps/_build backed by container-private named volumes masking the bind mount | ✓ SATISFIED (file contract) / ? NEEDS HUMAN (runtime arch) | compose nested volumes verified; NIF/arch boot → human verify |
| DKR-03 | 68-01, 68-02 | Entrypoint re-resolves only on mix.lock change (hash stamp); idempotent ecto | ✓ SATISFIED (file contract) / ? NEEDS HUMAN (runtime persistence) | lock-hash gate + ecto ordering verified; re-up behavior → human verify |
| DKR-04 | 68-02 | `:fs_poll` live-reload across macOS→Docker mount | ✓ SATISFIED (file contract) / ? NEEDS HUMAN (runtime reload) | top-level fs_poll block verified; browser reload → human verify |

All 4 phase requirement IDs (DKR-01..04) are claimed in plan frontmatter, fully traced in REQUIREMENTS.md (lines 16-19, mapped to Phase 68 lines 60-63), and accounted for. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER markers in any of the 5 modified files. No stubs, no empty implementations. |

### Milestone Invariant

`git diff --name-only` across the 5 phase commits (ba263d0..b31b3cd) shows ZERO paths under `lib/` or `test/`. Touched files: `.dockerignore`, `demo/ledger_loop/Dockerfile.dev`, `demo/ledger_loop/docker-entrypoint.sh`, `demo/ledger_loop/config/dev.exs`, `docker-compose.yml` (plus `.planning/` docs). Milestone invariant HOLDS.

### Human Verification Required

All four phase requirements are runtime/behavioral container or browser invariants. The enabling file contracts are verified; the behaviors need a macOS host with Docker BuildKit/Compose v2:

1. **DKR-01 build-cache receipt** — `docker compose --profile core build`; edit a source `.ex`; rebuild. Expected: dependency layer CACHED, no `mix deps.get`.
2. **DKR-02 arch-correctness receipt** — `docker compose --profile core up`; `exec demo_app ls deps`. Expected: no `wrong ELF class`/NIF error; container deps distinct from host.
3. **DKR-03 re-resolution receipt** — `up`/`down`/`up` (2nd skips deps.get); `touch mix.lock`; `up` (re-resolves); ecto steps idempotent on every boot.
4. **DKR-04 live-reload receipt** — `up`; open browser; edit a `.heex`; expect reload ~500ms with no restart/deps.

### Gaps Summary

No file-level gaps. Every artifact, key link, and prohibition for all five files is verified, and the milestone invariant (no `lib/`/`test/` change) holds. The phase is not marked `passed` solely because the phase goal is entirely runtime-behavioral and four Docker/browser receipts cannot be exercised statically — they are routed to human verification, not failed. Once the four receipts pass on a Docker host, the phase goal is fully achieved.

---

_Verified: 2026-06-19_
_Verifier: Claude (gsd-verifier)_
