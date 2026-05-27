---
phase: 45-post-publish-parity-verification
status: passed
verified: 2026-05-27
requirements: [PUB-04]
---

# Phase 45 Verification

**Status:** passed

## Must-haves

| Truth | Verified |
|-------|----------|
| `mix verify.release_parity 1.4.0` compares git tag `v1.4.0` to Hex paths over full `package.files` scope | Live run exit 0; unit tests green |
| Exit codes 0/2/1 match scrypath convention | Moduledoc + `System.halt(2)` on drift and test_support |
| Pure functions unit-tested without live Hex in CI | 17 tests, :integration excluded |
| test_support hard-fail before path diff | `assert_no_test_support!/1` + PARITY-RESULT count 0 |
| `verify-parity.sh` runs fetch + parity task; exit code is gate | Script exit 0 |
| `PARITY-RESULT.md` with checksums, test_support, metadata, **PASS** | Committed artifact dated 2026-05-27 |
| Live Hex 1.4.0 vs tag v1.4.0 parity | `./verify-parity.sh` **PASS** |

## Success Criteria (ROADMAP)

1. Verification script committed and runnable — `verify-parity.sh` exits 0
2. PARITY-RESULT.md with SHA-256, path diff, explicit pass/fail — **PASS** recorded
3. Zero test_support paths in published tarball — count 0, Result PASS
4. mix hex.audit + release metadata — both exit 0 in PARITY-RESULT

## Evidence

- `lib/mix/tasks/verify.release_parity.ex`
- `.planning/phases/45-post-publish-parity-verification/verify-parity.sh`
- `.planning/phases/45-post-publish-parity-verification/PARITY-RESULT.md`
- Hex API checksum: `727594d614eaa1f65b3958c78b83d667debbf8e9d7ff0cde0240a193c60ce5b6`

## Automated Checks

```
mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors  # 17/0
mix verify.release_parity 1.4.0                                               # exit 0
./.planning/phases/45-post-publish-parity-verification/verify-parity.sh       # exit 0
mix test --warnings-as-errors                                                 # 718/0
```

## Requirements

- **PUB-04**: Complete — path-set parity verified, test_support absent, auditable PASS artifact
