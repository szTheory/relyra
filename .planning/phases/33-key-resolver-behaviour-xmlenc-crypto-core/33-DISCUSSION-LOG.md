# Phase 33: KeyResolver Behaviour + XMLEnc Crypto Core - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-25
**Phase:** 33-key-resolver-behaviour-xmlenc-crypto-core
**Mode:** assumptions
**Areas analyzed:** KeyResolver Behaviour Structure, XMLEnc.decrypt/3 Failure Surface and Crypto Wiring, DiagnosticBundle Key Exclusion

## Assumptions Presented

### KeyResolver Behaviour Structure
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Relyra.KeyResolver` at `lib/relyra/key_resolver.ex` with `resolve/1` callback; `KeyResolver.Default` reads `Application.get_env(:relyra, :sp_private_key_pem)` | Confident | All existing behaviours follow `lib/relyra/{name}.ex` + `lib/relyra/{name}/default.ex` pattern; `Application.get_env(:relyra, ...)` confirmed in `request_store/ets.ex:273` |

### XMLEnc.decrypt/3 Failure Surface and Crypto Wiring
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `decrypt/3` returns `:decryption_failed` atom for all failure paths; uses `:public_key.decrypt_private/3` with `{:rsa_padding, :rsa_pkcs1_oaep_padding}` (SHA-1 OAEP only); AlgorithmPolicy gates fire first | Confident | Phase 32 locked enforce functions and opaque atom; REQUIREMENTS.md line 50 documents `{:rsa_oaep_hash, :sha256}` raises `{:badarg}` on OTP 26-28; `signature.ex` rescue pattern is established precedent |

### DiagnosticBundle Key Exclusion
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No new AllowList entry needed; structural exclusion via config-only key storage | Likely | `diagnostic/allow_list.ex` is pure explicit allowlist; `audit_writer.ex:8-21` and `log_alerts.ex:33` already filter `private_key`; key never enters Ecto layer |

## Corrections Made

No corrections — all assumptions confirmed.

## External Research

One research topic flagged by the analyzer (`gsd-assumptions-analyzer`): exact OTP invocation
form for RSA-OAEP private decryption on OTP 26. Resolved from codebase without spawning a
research agent — REQUIREMENTS.md line 50 confirms the constraint (only `rsa_pkcs1_oaep_padding`
works; `{:rsa_oaep_hash, :sha256}` raises `{:badarg}` on OTP 26-28).
