# Requirements: Relyra v1.11 First-Adopter Twin

**Defined:** 2026-09-09

**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.

## v1.11 Requirements

### Evidence Model

- [x] **EVID-01**: Maintainer can inspect a machine-checked ledger mapping evaluator, developer, tenant-admin, security-reviewer, SRE, and end-user journeys to automated evidence.
- [x] **EVID-02**: Every new acceptance criterion is enforced by deterministic automation in a mandatory CI lane.
- [x] **EVID-03**: External-provider canaries are clearly separated from deterministic merge gates and retain safe failure evidence.

### Packaged Consumer

- [x] **PKG-01**: A clean-room Phoenix consumer installs Relyra exclusively from the locally built and unpacked Hex artifact.
- [x] **PKG-02**: The consumer cannot access checkout-only files, root fixtures, or private `Relyra.TestSupport` modules.
- [x] **PKG-03**: A developer can run the installer, compile with warnings as errors, and boot the consumer from fresh state.
- [x] **PKG-04**: A developer can apply Relyra and adopter migrations to an empty PostgreSQL database.
- [x] **PKG-05**: The packaged consumer passes representative supported BEAM and optional-dependency profiles.
- [x] **PKG-06**: Installer regeneration or upgrade drift produces either an intentional compatible result or a precise automated failure.

### SaaS Digital Twin

- [x] **TWIN-01**: LedgerLoop represents multiple organizations with distinct users, administrators, roles, groups, and authorization outcomes.
- [x] **TWIN-02**: LedgerLoop represents multiple credible IdP/provider and connection states without conflating tenant data.
- [x] **TWIN-03**: LedgerLoop contains coherent metadata and certificate history covering draft, active, staged, expiring, retired, degraded, and recovered states.
- [x] **TWIN-04**: LedgerLoop presents a complete synthetic incident timeline from symptom through diagnosis, remediation, retry, and recovery.
- [x] **TWIN-05**: Twin fixtures are deterministic, resettable, comprehensible, isolated, and safe for logs, screenshots, and CI artifacts.

### Lifecycle Journeys

- [x] **JOUR-01**: An end user can complete SP-initiated login and receive the correctly mapped adopter-owned session and authorization outcome.
- [x] **JOUR-02**: Invalid digest, signature, issuer, audience, destination, time, and request-correlation inputs produce typed rejections and no session.
- [x] **JOUR-03**: Replaying an accepted assertion is rejected through the configured replay-store boundary.
- [x] **JOUR-04**: Multi-tenant connection resolution, mappings, sessions, traces, and audits remain isolated across organizations.
- [x] **JOUR-05**: A tenant administrator can progress through metadata import, connection enablement, staged certificate rollover, and recovery with co-committed audit evidence.
- [x] **JOUR-06**: An operator can diagnose and recover a failed login using correlated, redacted evidence without exposing assertions, certificates, credentials, or cookies.

### Code and Documentation Craftsmanship

- [x] **QUAL-01**: Maintainer can inspect a repository-wide, severity-ranked quality inventory covering correctness, security, integration, readability, documentation, and artifacts.
- [x] **QUAL-02**: Production code and tests use clear names and justified abstractions, with redundant comments removed and non-obvious invariants preserved.
- [x] **QUAL-03**: Security-sensitive cleanup is protected by characterization and adversarial tests and preserves every existing security invariant.
- [x] **QUAL-04**: Standalone source and product documentation contain timeless rationale rather than internal phase, plan, decision-code, or GSD references.
- [x] **QUAL-05**: The tracked directory tree contains only intentional source, configuration, fixtures, documentation, and automation artifacts.
- [x] **QUAL-06**: Every critical or high-value audit finding is fixed, explicitly constrained by an approval checkpoint, or retained with a concrete rationale.

### CI Quality

- [x] **PIPE-01**: Maintainer can inspect current CI duration, duplication, ownership, cache behavior, and failure-mode evidence before optimization.
- [x] **PIPE-02**: Every mandatory acceptance criterion has one clearly named owning lane without hollow or silently skipped gates.
- [x] **PIPE-03**: CI uses safe parallelism and caching where measurements show value while preserving independent security defenses.
- [x] **PIPE-04**: Workflows use consistent naming, least-privilege permissions, non-colliding concurrency, and redaction-safe artifacts.
- [x] **PIPE-05**: `mix qa`, warnings-as-errors tests, formatting, `mix ci.security`, consumer contracts, demo tests, and required browser journeys remain green.

### Repository and GitHub Hygiene

- [x] **REPO-01**: Main, tracked files, and registered worktrees end in an intentional clean state with no unexplained generated or scratch artifacts.
- [x] **REPO-02**: Maintainer can inspect a current inventory of pull requests, issues, branches, workflow health, and branch-protection state.
- [x] **REPO-03**: Remote GitHub mutations are presented as an exact batch and performed only after explicit approval.

### Governance and Exit

- [x] **GOV-01**: Public API, default-tightening, security-posture, and real SemVer-major changes stop at an explicit approval checkpoint.
- [x] **GOV-02**: The milestone introduces no speculative SAML protocol capability or unrelated product expansion.
- [ ] **EXIT-01**: Maintainer can inspect a final residual-risk assessment showing that remaining improvements are low-value, demand-gated, or costlier to maintain than the risk they retire.

## Future Requirements

### Extended Adoption Evidence

- **FUTURE-01**: Evaluators can use a hosted public digital twin maintained independently of the source checkout.
- **FUTURE-02**: Maintainer can validate exhaustive provider, browser, BEAM, and optional-dependency combinations when adopter demand justifies the cost.
- **FUTURE-03**: Maintainer can author scenarios through a generalized fixture framework after repeated duplication demonstrates the need.

## Out of Scope

| Feature | Reason |
|---|---|
| HTTP-POST signed AuthnRequests | Demand-gated protocol expansion; Redirect binding already ships |
| KMS/HSM adapters | Demand-gated infrastructure integration without a current adopter request |
| Signed SP metadata expansion | Demand-gated federation capability outside the feature-neutral milestone |
| Manual acceptance gates | New acceptance criteria require deterministic automated evidence |
| Security-seam simplification without equivalent or stronger proof | Cleanup cannot weaken established security invariants |
| Automatic GitHub mutations | Shared remote changes require an exact proposal and explicit approval |

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| EVID-01 | Phase 73 | Complete |
| EVID-02 | Phase 73 | Complete |
| EVID-03 | Phase 76 | Complete |
| PKG-01 | Phase 74 | Complete |
| PKG-02 | Phase 74 | Complete |
| PKG-03 | Phase 74 | Complete |
| PKG-04 | Phase 74 | Complete |
| PKG-05 | Phase 74 | Complete |
| PKG-06 | Phase 74 | Complete |
| TWIN-01 | Phase 75 | Complete |
| TWIN-02 | Phase 75 | Complete |
| TWIN-03 | Phase 75 | Complete |
| TWIN-04 | Phase 75 | Complete |
| TWIN-05 | Phase 75 | Complete |
| JOUR-01 | Phase 76 | Complete |
| JOUR-02 | Phase 76 | Complete |
| JOUR-03 | Phase 76 | Complete |
| JOUR-04 | Phase 76 | Complete |
| JOUR-05 | Phase 76 | Complete |
| JOUR-06 | Phase 76 | Complete |
| QUAL-01 | Phase 73 | Complete |
| QUAL-02 | Phase 77 | Complete |
| QUAL-03 | Phase 77 | Complete |
| QUAL-04 | Phase 77 | Complete |
| QUAL-05 | Phase 77 | Complete |
| QUAL-06 | Phase 77 | Complete |
| PIPE-01 | Phase 73 | Complete |
| PIPE-02 | Phase 78 | Complete |
| PIPE-03 | Phase 78 | Complete |
| PIPE-04 | Phase 78 | Complete |
| PIPE-05 | Phase 78 | Complete |
| REPO-01 | Phase 79 | Complete |
| REPO-02 | Phase 79 | Complete |
| REPO-03 | Phase 79 | Complete |
| GOV-01 | Phase 73 | Complete |
| GOV-02 | Phase 73 | Complete |
| EXIT-01 | Phase 79 | Pending |

**Coverage:**

- v1.11 requirements: 37 total
- Mapped to phases: 37
- Unmapped: 0 ✓

---

*Requirements defined: 2026-09-09*

*Last updated: 2026-09-09 after roadmap creation*
