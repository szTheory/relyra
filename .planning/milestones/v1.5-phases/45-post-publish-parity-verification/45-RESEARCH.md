# Phase 45: Post-publish parity verification — Research

**Researched:** 2026-05-27  
**Phase:** 45 — Post-publish parity verification  
**Requirements:** PUB-04  
**Context:** `45-CONTEXT.md` (USER DECISIONS — authoritative for scope)

## Summary

Phase 45 closes the v1.5 publish wedge by proving Hex `relyra-1.4.0` package contents match git tag `v1.4.0`, that no `test_support` paths shipped (TD-02 defense-in-depth on the live artifact), and that release metadata checks pass. Phase 44 already published `1.4.0` — this phase **verifies only**, no publish.

**Primary recommendation:** Two-plan split — (1) `mix verify.release_parity` + unit tests (scrypath DNA, Relyra `package.files` scope), (2) `verify-parity.sh` + live `1.4.0` run + `PARITY-RESULT.md` milestone gate. Path-set equality is the primary gate; outer `.tar` SHA256 is recorded for audit but must not fail parity when contents match (live probe confirmed 2026-05-27).

---

## 1. Comparison Semantics (ROADMAP vs CONTEXT)

| ROADMAP wording | Actual gate (CONTEXT D-01) | Rationale |
|-----------------|----------------------------|-----------|
| "byte-equal" | Path-set equality on `package.files` scope | Outer tar bytes differ on metadata; `diff -rq` clean on extracted contents |
| SHA-256 in PARITY-RESULT | Record both tarball digests + explicit PASS/FAIL on **path drift** | Audit trail without false-failing on tar wrapper |

---

## 2. Relyra `package.files` Scope (vs scrypath)

scrypath compares `lib/ + guides/ + docs/` only. Relyra ships more:

| Source | Paths |
|--------|-------|
| `mix.exs` `package.files` | `priv`, `docs`, `guides`, `.formatter.exs`, `mix.exs`, `README.md`, `CONFORMANCE.md`, `CHANGELOG.md`, `LICENSE`, `SECURITY.md`, `SECURITY_REVIEW.md`, `SECURITY_REVIEW_EVIDENCE.md`, `BATTERIES_INCLUDED.md` |
| `package_lib_files/0` | All `lib/**/*` regular files **excluding** any path containing `test_support` |

**Git side:** `git ls-tree -r --name-only v1.4.0`, filter to the union above, reject `test_support` paths.  
**Hex side:** `mix hex.package fetch relyra VERSION --unpack`, glob regular files, drop `hex_metadata.config`, same filter.

**Tag format:** `v{version}` (`include-v-in-tag: true`) — not `scrypath-v{version}`.

---

## 3. DNA Source: scrypath `verify.release_parity`

| Element | scrypath | Relyra adaptation |
|---------|----------|-------------------|
| Exit codes | 0 parity, 2 drift, 1 runtime | Same (D-02) |
| Pure `compute/2` | MapSet diff | Reuse verbatim |
| `retry_until!/4` | CDN propagation | `RELYRA_RELEASE_VERIFY_ATTEMPTS` (default 10), `RELYRA_RELEASE_VERIFY_SLEEP_MS` (default 15000) |
| Version guard | Semver regex before subprocess | Same (Security V5) |
| `--json` | Jason.encode! | Jason available transitively; optional in plan |
| test_support | N/A | **Separate** `assert_no_test_support!/1` → halt(2) if any hex path matches `test_support` |
| Scope | lib/guides/docs | Full `package.files` (D-03) |

Reference: `/Users/jon/projects/scrypath/lib/mix/tasks/verify.release_parity.ex`, `/Users/jon/projects/scrypath/test/mix/tasks/verify_release_parity_test.exs`.

---

## 4. PARITY-RESULT.md Contract (D-06, D-08)

Required sections:

1. **Hex API metadata** — `curl -s https://hex.pm/api/packages/hexpm/releases/relyra/1.4.0` → store `checksum` field (outer tarball SHA256).
2. **Local rebuild** — checkout `v1.4.0`, `mix hex.build`, SHA256 of `relyra-1.4.0.tar` (informational; may differ from Hex outer digest).
3. **Path diff** — counts, `only_in_git`, `only_in_hex` (empty on PASS).
4. **test_support** — PASS/FAIL line (zero paths).
5. **Metadata** — `mix hex.audit` at tag (exit 0), `mix ci.release` (exit 0).
6. **Verdict** — explicit `**PASS**` or `**FAIL**` line; FAIL blocks `/gsd-complete-milestone v1.5`.

---

## 5. `verify-parity.sh` (D-07)

```bash
#!/usr/bin/env bash
set -euo pipefail
git fetch --tags
mix verify.release_parity 1.4.0   # exit 0/2/1 propagates
# capture output → PARITY-RESULT.md (script or task --report flag)
```

Script exit code = milestone gate (ROADMAP SC#1). Run from repo root on a machine with network + git tags.

---

## 6. Live Baseline (2026-05-27 probe — CONTEXT)

| Check | Result |
|-------|--------|
| Hex `1.4.0` fetch | Success |
| `diff -rq` Hex unpack vs `v1.4.0` tree | Clean |
| `test_support` in Hex paths | 0 |
| Outer tar SHA256 | Differs between Hex download and local `mix hex.build` |
| `hex_metadata.config` | Hex-only (excluded from diff) |

Expect Plan 45-02 to produce **PASS** if tree unchanged since probe.

---

## 7. Deferred (out of scope)

- `release-please.yml` post-publish hook (scrypath SHIP-03)
- Daily `verify-published-release.yml` cron + drift issue template
- Parameterized versions beyond documenting `mix verify.release_parity VERSION`

---

## 8. Validation Architecture

### Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) + Hex CLI + git |
| **Config file** | `mix.exs` |
| **Phase gate (unit)** | `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` |
| **Phase gate (live)** | `mix verify.release_parity 1.4.0` + `verify-parity.sh` |
| **Estimated runtime** | Unit ~2s; live parity ~30–90s (network) |

### Per-requirement verification map

| Requirement | Acceptance pattern | Automated command | Manual? |
|-------------|-------------------|-------------------|---------|
| PUB-04 SC#1 script | `verify-parity.sh` exists, executable, exit 0 on PASS | `test -x .planning/phases/45-*/verify-parity.sh && ./.planning/phases/45-*/verify-parity.sh` | Network |
| PUB-04 SC#2 PARITY-RESULT | Explicit PASS + checksums | `rg '\*\*PASS\*\*|^\*\*FAIL\*\*' .planning/phases/45-*/PARITY-RESULT.md` | No |
| PUB-04 SC#3 test_support | Zero paths in published tarball | Task output + PARITY-RESULT section | No |
| PUB-04 SC#4 hex.audit | No fixable warnings at tag | `git checkout v1.4.0 && mix hex.audit` (document in PARITY-RESULT) | Tag checkout |
| PUB-04 path parity | `mix verify.release_parity 1.4.0` exit 0 | Same | Network |

### Manual-only verifications

| Behavior | Why manual | Instructions |
|----------|------------|--------------|
| First live run against Hex CDN | Requires network; may need retries | Run `verify-parity.sh` once; if exit 1, check tag fetch |
| Milestone close | Human runs `/gsd-complete-milestone` | Only after PARITY-RESULT **PASS** |

---

## 9. Recommended Plan Split

| Plan | Wave | Scope | `autonomous` | Depends |
|------|------|-------|--------------|---------|
| **45-01** | 1 | `Mix.Tasks.Verify.ReleaseParity` + `test/mix/tasks/verify_release_parity_test.exs` | true | — |
| **45-02** | 2 | `verify-parity.sh`, live `1.4.0` execution, `PARITY-RESULT.md` | true | 45-01 |

Optional follow-up (not in plans): wire task into `mix ci.release` or `release-parity.yml` — deferred per CONTEXT.

---

## RESEARCH COMPLETE
