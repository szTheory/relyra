# Phase 1: XML Security ADR and Guardrails - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `01-CONTEXT.md`; this log preserves alternatives and rationale.

**Date:** 2026-04-24
**Phase:** 01-xml-security-adr-and-guardrails
**Areas discussed:** XML strategy decision, Security XML seam contract, Security acceptance bar, NIF supply-chain policy

---

## XML strategy decision

| Option | Description | Selected |
|--------|-------------|----------|
| Pure-BEAM single-parser path | Lowest release/supply-chain complexity; strongest Elixir-native DX; requires high rigor on canonicalization correctness | ✓ |
| NIF-over-xmlsec | Highest mature XMLDSig/c14n confidence; higher CI/release/supply-chain burden | |
| Hybrid | Native verification confidence with mixed-path complexity and boundary risks | |

**User's choice:** Recommendation-driven default accepted.
**Selected decision:** Pure-BEAM single-parser default for v0.1, with explicit contingency trigger to switch to hybrid/xmlsec if acceptance gates fail.
**Notes:** Research emphasized parser-differential and signed-node binding footguns from Ruby/Node history; recommendation optimizes for both trust and maintainer sustainability.

---

## Security XML seam contract

| Option | Description | Selected |
|--------|-------------|----------|
| Primitive XML utility seam | Minimal API but leaks adapter internals and enables misuse | |
| Monolithic verify+extract seam | Strong guardrails but over-coupled and hard to evolve | |
| Staged opaque seam (`parse_safely`, `select_signed_node`, `canonicalize`) | Preserves invariants, adapter-swappability, and typed Elixir DX | ✓ |

**User's choice:** Recommendation-driven default accepted.
**Selected decision:** Staged opaque seam contract with typed signed-node handles and typed `%Relyra.Error{}` failures.
**Notes:** This keeps downstream phases stable even if implementation backend changes.

---

## Security acceptance bar

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal safety floor | Fastest delivery but materially weaker regression resistance | |
| Balanced strict gate | Covers known CVE classes while preserving phase velocity | ✓ |
| Release-grade paranoid gate | Maximum safety but excessive delay for Phase 1 | |

**User's choice:** Recommendation-driven default accepted.
**Selected decision:** Balanced strict gate with blocking adversarial corpus and mandatory CI lane contract before phase close.
**Notes:** Minimum corpus target set to 36 fixtures across required attack/failure classes.

---

## NIF supply-chain policy (conditional)

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal policy | Fastest shipping with weaker provenance controls | |
| Standard policy | Practical checksum/matrix/parity controls aligned with OSS norms | ✓ |
| High-assurance policy | Signed provenance and stricter controls, higher ops cost | |

**User's choice:** Recommendation-driven default accepted.
**Selected decision:** Standard policy if NIF/hybrid path is used; escalate to high-assurance only when NIF becomes default production trust path.
**Notes:** Recommended matrix includes Linux GNU x64/arm64, Linux musl x64, macOS arm64/x64; Windows source-build best effort.

---

## Claude's Discretion

- Parser choice between `saxy` and `simple_xml` within locked single-parser strategy.
- Detailed fixture naming and organization beyond the required class/count thresholds.
- CI workflow job naming/layout as long as required gate contracts remain intact.

## Deferred Ideas

- Apply recommendation-first, low-friction decision handling as a broader default across GSD workflows (except very high-impact choices requiring explicit user sign-off).
