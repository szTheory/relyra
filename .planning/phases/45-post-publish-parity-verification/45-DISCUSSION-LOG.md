# Phase 45: Post-publish parity verification - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 45-post-publish-parity-verification
**Mode:** assumptions
**Areas analyzed:** Verification mechanism, Comparison scope, test_support defense-in-depth, PARITY-RESULT artifact, Runnable script, Metadata checks, CI wiring deferral

## Assumptions Presented

### Verification mechanism
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Implement `mix verify.release_parity 1.4.0` following scrypath DNA; compare package contents not outer tar SHA256 | Confident | scrypath `verify.release_parity.ex` moduledoc; live probe: extracted contents identical, outer SHA256 differs |

### Comparison scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Full `package.files` whitelist at tag `v1.4.0` (lib via package_lib_files, priv, docs, guides, root artifacts) | Confident | `mix.exs` package/0; live probe 166/167 paths match (hex_metadata.config excluded) |

### test_support defense-in-depth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Hard-fail if any published path matches test_support | Confident | ROADMAP SC#3; TD-02 chain; live Hex 1.4.0 has zero test_support entries |

### PARITY-RESULT.md artifact
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Capture Hex API checksum, local package checksum, path diff, test_support check, hex.audit + release hardening, PASS/FAIL | Confident | ROADMAP SC#2; PUB-04 |

### Runnable script location
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `verify-parity.sh` under phase dir invokes Mix task, writes PARITY-RESULT.md | Likely | ROADMAP SC#1 |

### hex.audit / metadata checks
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| mix hex.audit + release_hardening_test invariants documented in PARITY-RESULT | Likely | ROADMAP SC#4; hex.audit only checks retired deps |

### CI wiring
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Post-publish workflow + daily cron wiring deferred to backlog | Confident | ROADMAP Phase 45 scope is script + result; scrypath cron was separate phase |

## Corrections Made

No corrections — all assumptions confirmed by user (option 1: "Yes, proceed").

## External Research

- Live Hex tarball fetched via `mix hex.package fetch relyra 1.4.0 --unpack` — contents match tag `v1.4.0` (`diff -rq` clean).
- Hex API checksum for 1.4.0: `727594d614eaa1f65b3958c78b83d667debbf8e9d7ff0cde0240a193c60ce5b6` (outer tar; differs from local `mix hex.build` package checksum due to archive metadata).
- scrypath and rulestead sibling implementations reviewed for DNA alignment.
