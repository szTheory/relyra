# Phase 2: Protocol and Signature Core - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `02-CONTEXT.md`; this log preserves the assumption analysis.

**Date:** 2026-04-24
**Phase:** 02-protocol-and-signature-core
**Mode:** assumptions
**Areas analyzed:** Public core API surface, Validation pipeline and trust binding, RelayState and request intent, Algorithm and error policy, Architecture boundaries

## Assumptions Presented

### Public core API surface
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 2 should introduce public orchestration entrypoints `start_login/3` and `consume_response/3` while protocol internals stay private. | Likely | `.planning/research/ARCHITECTURE.md`, `.planning/ROADMAP.md`, `lib/relyra.ex` |

### Validation pipeline and trust binding
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Validation order must be parse -> issuer match -> signature verify -> signed-node selection -> protocol/time checks with typed failures. | Confident | `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/PITFALLS.md` |
| Signature verification trust source must be configured IdP certs only; no document `KeyInfo` trust root. | Confident | `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/research/ARCHITECTURE.md` |
| Duplicate XML IDs and wrapping indicators should be hard typed rejections in phase-2 core. | Confident | `.planning/REQUIREMENTS.md`, `.planning/phases/01-xml-security-adr-and-guardrails/01-CONTEXT.md`, `lib/relyra/security/xml.ex` |

### RelayState and request intent
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| RelayState should remain opaque (`rs_...`) and server-bound; raw redirect URLs are rejected by default. | Confident | `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/research/PITFALLS.md` |
| Consume flow should be shaped for enforced SP-initiated request intent (`InResponseTo`) in upcoming store phase. | Likely | `.planning/ROADMAP.md`, `.planning/research/ARCHITECTURE.md` |

### Algorithm and error policy
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| SHA-256+ is default and SHA-1 remains rejected unless explicit time-boxed legacy override exists. | Confident | `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md` |
| Phase-2 failures should use stable `%Relyra.Error{type, message, details}` contract. | Confident | `lib/relyra/error.ex`, `.planning/phases/01-xml-security-adr-and-guardrails/01-CONTEXT.md` |

### Architecture boundaries
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Protocol and signature core remains framework/storage agnostic in this phase; Phoenix/Ecto concerns stay in later phases. | Likely | `.planning/ROADMAP.md`, `.planning/research/ARCHITECTURE.md`, `mix.exs` |

## Corrections Made

No corrections — all assumptions confirmed.

