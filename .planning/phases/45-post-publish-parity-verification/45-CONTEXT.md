# Phase 45: Post-publish parity verification - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the published Hex `relyra-1.4.0` tarball matches the `v1.4.0` git tag (OSS-discipline contract from PROJECT.md), confirm the published artifact contains no `test_support` paths, and capture an auditable pass/fail result. Phase 44 already published `1.4.0` to Hex — this phase verifies, it does not publish. README/installer DX is Phase 46.
</domain>

<decisions>
## Implementation Decisions

### Verification mechanism
- **D-01:** Implement `mix verify.release_parity 1.4.0` following scrypath DNA (`scrypath/lib/mix/tasks/verify.release_parity.ex`), adapted for Relyra. Compare **package contents**, not outer `.tar` SHA256 — outer archive bytes differ due to tar metadata even when extracted contents are identical (confirmed by live probe: `diff -rq` clean between Hex `1.4.0` unpack and tag checkout; outer SHA256 differs).
- **D-02:** Exit codes follow scrypath convention: `0` = parity, `2` = drift detected, `1` = runtime error (network, missing tag, fetch failure). Script and Mix task share these semantics.

### Comparison scope
- **D-03:** Compare the full `mix.exs` `package.files` whitelist at tag `v1.4.0`: `lib/` paths from `package_lib_files/0`, `priv/`, `docs/`, `guides/`, and root artifacts (`README.md`, `CHANGELOG.md`, `LICENSE`, `SECURITY.md`, `SECURITY_REVIEW.md`, `SECURITY_REVIEW_EVIDENCE.md`, `CONFORMANCE.md`, `BATTERIES_INCLUDED.md`, `mix.exs`, `.formatter.exs`). **Not** scrypath's lib/guides/docs-only subset — Relyra ships priv migrations and root security docs in the tarball.
- **D-04:** Git side: `git ls-tree -r --name-only v1.4.0` filtered to `package.files` scope. Hex side: `mix hex.package fetch relyra 1.4.0 --unpack`. Exclude Hex-injected `hex_metadata.config` from comparison. Tag format is `v1.4.0` (release-please `include-v-in-tag: true`).

### test_support defense-in-depth
- **D-05:** Hard-fail (exit 2) if any path in the published tarball matches `test_support` — separate assertion from path diff, chaining Phase 41 TD-02 onto the live artifact. Live probe confirms zero `test_support` entries in Hex `1.4.0` (2026-05-27).

### PARITY-RESULT.md artifact
- **D-06:** Write `.planning/phases/45-post-publish-parity-verification/PARITY-RESULT.md` capturing: Hex API tarball checksum (`curl hex.pm/api/.../releases/1.4.0`), local `mix hex.build` package checksum from `v1.4.0` tag checkout, path-diff summary (counts + any drift paths), test_support assertion result, `mix hex.audit` + release-hardening metadata check results, explicit **PASS** or **FAIL** line. Any drift blocks milestone close — no unconditional pass.

### Runnable script
- **D-07:** Shell wrapper `.planning/phases/45-post-publish-parity-verification/verify-parity.sh` invokes the Mix task from a fresh checkout (with `git fetch --tags` prerequisite), captures output, and writes/updates `PARITY-RESULT.md`. Script exit code is the milestone-close gate per ROADMAP SC#1.

### Metadata / hex.audit checks
- **D-08:** Run `mix hex.audit` at `v1.4.0` tag checkout (retired-package check — already in `mix ci.security`) and `mix ci.release` / `test/release/release_hardening_test.exs` invariants (license, CHANGELOG link, workflow wiring). Document both in PARITY-RESULT — ROADMAP SC#4 "mix hex.audit or equivalent" is satisfied by the combination.

### Claude's Discretion
- Whether to add rulestead-style content-digest comparison (`changed` file list via SHA256 per path) in addition to path-set diff — recommend path-set as primary gate, optional digest for `lib/**/*.ex` if planner sees value.
- Retry knobs (`RELYRA_RELEASE_VERIFY_ATTEMPTS` / `RELYRA_RELEASE_VERIFY_SLEEP_MS`) mirroring scrypath CDN propagation handling.
- Unit test structure: pure `compute/2` in `test/mix/tasks/verify_release_parity_test.exs` plus optional `:integration` canary against live Hex `1.4.0`.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 45 goal, success criteria, PUB-04 requirement.
- `.planning/REQUIREMENTS.md` — PUB-04 definition; TD-02 tarball audit chain.
- `.planning/STATE.md` — TD-02 sequencing rationale (test_support must be absent before parity passes meaningfully).
- `.planning/PROJECT.md` — OSS discipline contract (post-publish parity verification).

### Prior Phase Context
- `.planning/phases/44-release-please-pipeline-diagnosis-v1-4-0-hex-publish/44-CONTEXT.md` — Publish complete; parity deferred to Phase 45.
- `.planning/phases/44-release-please-pipeline-diagnosis-v1-4-0-hex-publish/44-VERIFICATION.md` — `v1.4.0` tag exists; Hex lists 1.4.0.
- `.planning/phases/44-release-please-pipeline-diagnosis-v1-4-0-hex-publish/RELEASE-PLEASE-DIAGNOSIS.md` — Publish evidence and CI run IDs.
- `.planning/phases/41-pre-publish-hygiene-tech-debt-sweep-security-hardening/41-02-SUMMARY.md` — TD-02 dual-layer test_support exclusion.

### Sibling-Lib Pattern (DNA source)
- `/Users/jon/projects/scrypath/lib/mix/tasks/verify.release_parity.ex` — Path-set parity task, exit codes, retry model, `hex.package fetch --unpack`.
- `/Users/jon/projects/scrypath/test/mix/tasks/verify_release_parity_test.exs` — Pure `compute/2` unit tests + integration canary.
- `/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/verify.release_parity.ex` — Content-digest `changed` file detection (optional enhancement).

### Release Infrastructure
- `mix.exs` — `package/0` whitelist, `package_lib_files/0`, `prod_elixirc_paths/0`, `ci.release` alias.
- `test/release/release_hardening_test.exs` — Release discipline artifact checks.
- `.github/workflows/release-parity.yml` — Existing `mix ci.release` lane (does not yet run parity diff).
- `.github/workflows/release-please.yml` — Post-publish hook point for future parity wiring.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` `package_lib_files/0` — canonical list of lib paths shipped to Hex (test_support already excluded).
- `test/release/release_hardening_test.exs` — release artifact presence checks reusable in parity gate.
- `mix ci.release` alias — thin wrapper over release hardening test; safe pre/post parity lane.
- `mix hex.package fetch --unpack` — standard Hex CLI for downloading published tarball contents.

### Established Patterns
- scrypath DNA: path-set equality between git tag and Hex unpack; outer tar byte equality explicitly deferred.
- Phase 41 verified locally: `mix hex.build` tarball contains zero test_support entries.
- Phase 44 verified: Hex API checksum stored at publish time; tag `v1.4.0` points to published commit.
- Live probe (2026-05-27): extracted Hex `1.4.0` vs tag `v1.4.0` — `diff -rq` clean, 0 test_support paths, 1 Hex-only injected file (`hex_metadata.config`).

### Integration Points
- Tag anchor: `v1.4.0` on GitHub (created by Phase 44 release-please merge).
- Hex tarball: `https://repo.hex.pm/tarballs/relyra-1.4.0.tar` / `mix hex.package fetch relyra 1.4.0`.
- Milestone gate: `PARITY-RESULT.md` PASS line required before `/gsd-complete-milestone v1.5`.
</code_context>

<specifics>
## Specific Ideas

- ROADMAP "byte-equal" language means **package contents parity** (path-set + optional digest), not outer `.tar` SHA256 — naive outer-byte comparison false-fails on archive metadata while contents match.
- scrypath moduledoc rationale applies directly: git tree and hex.build read the same locked sources; path drift catches the v1.2 incident class (wrong files shipped).
- Daily cron + post-publish workflow wiring (scrypath Phase 18-06 pattern) is valuable but explicitly deferred — Phase 45 delivers the task, script, and one-time `1.4.0` result.
</specifics>

<deferred>
## Deferred Ideas

- Wire `mix verify.release_parity` into `release-please.yml` post-publish step (scrypath SHIP-03 pattern) — backlog, not Phase 45 scope.
- Scheduled daily parity monitor + drift GitHub issue template (scrypath `verify-published-release.yml` + `.github/ISSUE_TEMPLATE/release-parity-drift.md`) — backlog.
- Parameterized reuse for future versions beyond `1.4.0` — Mix task accepts version arg; Phase 45 execution targets `1.4.0` only.

</deferred>

---

*Phase: 45-post-publish-parity-verification*
*Context gathered: 2026-05-27*
