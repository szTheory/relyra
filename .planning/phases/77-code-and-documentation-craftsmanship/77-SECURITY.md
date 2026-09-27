---
phase: "77"
slug: "code-and-documentation-craftsmanship"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-26"
---

# Phase 77 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Maintainer prose to adopter guide | Internal CI/planning details can mislead adopters about integration actions. | Documentation and acceptance-policy text |
| Planning examples to acceptance policy | Quoted policy examples must not become completion instructions; active directives remain rejected. | Markdown examples and policy directives |
| IdP XML to signature gate | Untrusted signature material reaches one verifier using configured certificates. | XML signature data and configured trust anchors |
| Metadata fetch to trust anchor | Metadata-root signatures rely on pinned fingerprints before deep parsing. | Fetched metadata and operator-pinned certificate fingerprints |
| Git index to artifact assertion | Worktree noise must not be promoted into tracked-artifact findings. | Indexed paths and ownership evidence |
| Test/QA output to finding ledger | A dated observation must not be presented as current closure evidence. | Command results and finding dispositions |
| Security proof to finding disposition | Historical critical closure remains valid only with configured-certificate and adversarial regression proof. | Security test and proof references |
| Source diff to approval classifier | Broad AST normalization could hide an executable signature-policy mutation. | Signature source history and approval classification |
| Planning metadata to governance evidence | Incorrect task commands or commit claims could make incomplete work appear proven. | Plan commands, task ownership, and commit history |
| Tracked repository to Phase 73 proof/reports | Stale or manually transcribed proof data could misstate current source and findings. | Tracked source inventory and generated reconciliation reports |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-77-01 | Tampering | Documentation policy scanner | medium | mitigate | `test/docs/demo_guide_drift_test.exs` distinguishes active directives from quoted examples and rejects required UAT artifacts. | closed |
| T-77-02 | Repudiation | `mix ci.docs` ownership | low | mitigate | The docs owner checks roadmap-derived incomplete phases and is wired into `ci.docs`. | closed |
| T-77-03 | Spoofing | Signature verifier trust source | high | mitigate | Configured certificates are required; document `KeyInfo`, forged signatures, wrong keys, and tampered inputs are rejected by the independent adversarial suite. | closed |
| T-77-04 | Tampering | SignedInfo and Reference digest | high | mitigate | SignedInfo verification and Reference digest recomputation remain required and are covered by adversarial rejection cases. | closed |
| T-77-05 | Elevation of privilege | Metadata-root trust | high | mitigate | Metadata is verified before deep parsing and uses operator-pinned certificates for root verification. | closed |
| T-77-06 | Tampering | Baseline finding status | high | mitigate | Governance assertions require resolved Phase 77 findings to carry dated named-lane evidence. | closed |
| T-77-07 | Repudiation | Tracked artifact inventory | medium | mitigate | Governance inventory derives paths from the Git index, ignores untracked controls, and requires path-specific ownership. | closed |
| T-77-08 | Spoofing | Historical signature closure | high | mitigate | The critical finding retains its adversarial-proof reference; configured-certificate rejection remains gated by the unchanged security lane. | closed |
| T-77-09 | Tampering | Signature AST approval classifier | high | mitigate | Comment-only changes pass only after normalized AST equality; documentation, semantic, and malformed-source controls remain mutations. | closed |
| T-77-10 | Repudiation | Plan verification and commit provenance | medium | mitigate | Direct test owners and command ownership are enforced; independent security-suite processes remain in place. | closed |
| T-77-11 | Tampering | Phase 73 proof and reports | high | mitigate | Capture and repository validation bind the source manifest and identical report blocks; the mandatory reconciliation owner replays the proof. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above the high threshold count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).* 

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-26 | 11 | 11 | 0 | gsd-security-auditor (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-26
