# Phase 32: AlgorithmPolicy Extension + Schema Migrations - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 32-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-25
**Phase:** 32-algorithm-policy-extension-schema-migrations
**Mode:** assumptions
**Areas analyzed:** AlgorithmPolicy API Extension, RSA-PKCS1v1.5 No-Hatch + AES-CBC Hatch, Certificate Migration (`party` + `use`), `sign_authn_requests` Migration

## Assumptions Presented

### AlgorithmPolicy API Extension Pattern
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New enforce functions return bare `:ok \| Error.t()`, struct gains `key_transport`/`content_encryption` allowlist fields and `legacy_aes_cbc` escape hatch mirroring `legacy_sha1` | Confident | `algorithm_policy.ex:16-27` (struct), `algorithm_policy.ex:101-116` (existing enforce return types), REQUIREMENTS.md ENC-03 |

### RSA-PKCS1v1.5 No-Hatch + AES-CBC Hatch Field Naming
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| PKCS1v1.5 hard-rejected via URI blocklist with no escape hatch; AES-CBC gets `legacy_aes_cbc` field with identical `%{reason, expires_at}` type | Confident | `algorithm_policy.ex:88-99` (ECDSA no-hatch pattern), REQUIREMENTS.md ENC-03 ("no escape hatch — no legitimate production use case") |

### Certificate Migration: `party` + `use` as `:string` with `up/down` + Backfill
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `up/down` migration with `execute` UPDATE backfill; `:string` storage; defaults `party: "idp"`, `use: "signing"`; Ecto.Enum schema fields | Confident | `20260505140000` migration (canonical pattern), all existing enum columns are strings |

### `sign_authn_requests` Migration and Connection Schema Placement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `change`-based migration `add :sign_authn_requests, :boolean, default: false, null: false`; top-level `Connection` field, not in `RuntimePolicy` | Confident | `20260506232319` migration (exact precedent), `connection.ex:39` (`allow_idp_initiated` at top level) |

## Corrections Made

No corrections — all assumptions confirmed by user.

## External Research

None required — codebase provided sufficient evidence for all decisions:
migration naming convention, `up/down` vs `change` selection criterion, string-vs-Postgres-enum
storage choice, escape hatch struct pattern, and enforcement function return-type convention were
all directly observable from existing source files.
