# Roadmap: Relyra

## Overview

Relyra is shipped through v1.10 as a strict-by-default SAML 2.0 Service Provider library
with a realistic LedgerLoop demo, broad deterministic security gates, and recurring
real-IdP canaries. v1.11 turns that foundation into a digital first adopter: a clean-room
consumer proves the exact package boundary, LedgerLoop models a credible SaaS lifecycle,
and the resulting evidence supports a repository-wide quality ratchet to diminishing
returns.

## Milestones

- Complete: **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- Complete: **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- Complete: **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- Complete: **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- Complete: **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- Complete: **v0.6 — Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- Complete: **v1.0 — Security review, conformance, and onboarding** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- Complete: **v1.1 — Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- Complete: **v1.3 — Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- Complete: **v1.4 — Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- Complete: **v1.5 — Publish, Prove, Polish** (shipped 2026-05-27). See `.planning/milestones/v1.5-ROADMAP.md`.
- Complete: **v1.6 — Adoption Truth** (shipped 2026-05-28). See `.planning/milestones/v1.6-ROADMAP.md`.
- Complete: **v1.7 — Adoption Evidence Demo** (shipped 2026-06-13). See `.planning/milestones/v1.7-ROADMAP.md`.
- Complete: **v1.8 — Brand System & Identity** (shipped 2026-06-14). See `.planning/milestones/v1.8-ROADMAP.md`.
- Complete: **v1.9 — Loose Ends & Adoption Honesty** (shipped 2026-06-19). See `.planning/milestones/v1.9-ROADMAP.md`.
- Complete: **v1.10 — Docker DX & Fleet Proxy** (shipped 2026-08-27). See `.planning/milestones/v1.10-ROADMAP.md`.
- Active: **v1.11 — First-Adopter Twin** (Phases 73–79, 37 requirements).

## Milestone Guardrails

- Preserve the configured-certificate-only signature trust source, one XML parse path,
  raw-binary pre-parse guards, genuine digest/signature verification, transactional audit
  co-commit, and production replay protection.
- Stop for explicit approval before changing a published API or behaviour callback,
  tightening a default, changing security posture, or making a real SemVer-major release.
- Add no speculative protocol feature. `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01`
  remain demand-gated.
- Give every new acceptance criterion deterministic automated evidence in mandatory CI.
  External services remain scheduled canaries, not required human or network gates.
- Make no remote GitHub mutation until the exact action batch is approved.
- Prefer demonstrated correctness, clarity, and maintenance gains over aesthetic churn.

## v1.11 First-Adopter Twin

- [x] **Phase 73: Twin Contract and Baseline** — Define the executable adopter model, evidence ownership, quality baseline, and immutable guardrails.
- [ ] **Phase 74: Clean-Room Package Consumer** — Prove a fresh Phoenix application can adopt only the files Relyra actually ships.
- [ ] **Phase 75: SaaS Twin Domain Realism** — Expand LedgerLoop into a coherent multi-tenant adopter with credible humans, trust history, and incidents.
- [ ] **Phase 76: Lifecycle and Recovery Journeys** — Exercise representative login, rejection, isolation, trust-change, diagnosis, and recovery flows end to end.
- [ ] **Phase 77: Code and Documentation Craftsmanship** — Remove high-value quality debt and temporary planning narration behind the twin's safety net.
- [ ] **Phase 78: CI Efficiency and Reliability** — Give every gate clear ownership and improve measured CI cost without weakening independent defenses.
- [ ] **Phase 79: Adopter-Ready Closeout** — Finish with green intentional repository state, approved GitHub hygiene, and a diminishing-returns assessment.

## Phase Details

### Phase 73: Twin Contract and Baseline

**Goal:** A maintainer can see exactly which adopter jobs v1.11 proves, where each proof
runs, what the current quality/CI baseline is, and which changes require approval.

**Depends on:** Nothing (first phase of v1.11)

**Requirements:** EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02

**Success Criteria** (what must be TRUE):

1. A machine-checked ledger maps every in-scope persona and lifecycle outcome to named,
   deterministic evidence or an explicitly scheduled external canary.
2. The repository has a severity-ranked baseline inventory for correctness, security,
   integration, readability, documentation, artifacts, and CI cost/duplication.
3. Automated policy checks prevent new acceptance criteria from being closed without a
   mandatory deterministic owner.
4. Plans and execution stop at named checkpoints for public API, default, security,
   SemVer-major, or remote GitHub changes, and exclude speculative protocol work.

**Plans:** 33/33 plans complete

Plans:

- [x] 73-33-PLAN.md

- [x] 73-32-PLAN.md

- [x] 73-31-PLAN.md

**Wave 1**

- [x] 73-01-PLAN.md — Trace adopter evidence from a literal ledger through deterministic ownership into mandatory CI.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 73-02-PLAN.md — Capture and machine-check the severity-ranked repository and CI baseline.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 73-03-PLAN.md — Enforce approval checkpoints, feature-neutral scope, and deterministic completion policy.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 73-04-PLAN.md — Close deterministic evidence-owner bypasses from ledger rows through mandatory CI.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 73-05-PLAN.md — Make approval, exclusion, remote-batch, and baseline provenance checks fail closed.

**Wave 6** *(blocked on Wave 5 completion; Plans 06 and 07 may execute in parallel)*

- [x] 73-06-PLAN.md — Close command, effective-selector, module-tag, and mandatory-workflow evidence gaps.
- [x] 73-07-PLAN.md — Close task vocabulary, positive authorization, scope, completed-plan diff, and universal exclusion gaps.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 73-08-PLAN.md — Close single-operation remote authorization and tracked/executable baseline provenance gaps.

**Wave 8** *(gap closure; blocked on Wave 7 completion; Plans 09 and 10 may execute in parallel)*

- [x] 73-09-PLAN.md — Close non-shell command, real Mix/ExUnit owner, job fallibility, and GitHub path-filter gaps.
- [x] 73-10-PLAN.md — Bind active governance and completed-plan changed surfaces to trusted project and git execution identity.

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 73-11-PLAN.md — Bind singular tracked remote inputs to declared desired/current state and run the complete mandatory evidence lane.

**Wave 10** *(gap closure; blocked on Wave 9 completion; Plans 12 and 13 may execute in parallel)*

- [x] 73-12-PLAN.md — Close empty-effective alias ownership and restrictive mandatory-workflow trigger gaps.
- [x] 73-13-PLAN.md — Close incomplete branch-protection state, ambient script execution, and manifest-selected provenance gaps.

**Wave 11** *(gap closure; blocked on Wave 10 completion; Plans 14 and 15 may execute in parallel)*

- [x] 73-14-PLAN.md — Close mandatory workflow branch, activity, duplicate, and unsupported event-grammar gaps.
- [x] 73-15-PLAN.md — Remove script-backed authorization and govern every post-SUMMARY exact-scope descendant.

**Wave 12** *(gap closure; blocked on Wave 11 completion)*

- [x] 73-16-PLAN.md — Reconcile CR-06 through CR-08 evidence with the Phase 73 security verdict.

**Wave 13** *(gap closure; blocked on Wave 12 completion)*

- [x] 73-17-PLAN.md — Replace repeated registered-test process discovery with one immutable owner snapshot and bounded mandatory-lane proof.

**Wave 14** *(gap closure; blocked on Wave 13 completion)*

- [x] 73-18-PLAN.md — Reject unsupported GitHub path metacharacters and bind owners to tracked non-symlink lexical paths.

**Wave 15** *(gap closure; blocked on Waves 13 and 14 completion)*

- [x] 73-19-PLAN.md — Reconcile the current review threats and seal security status only after repeated deterministic evidence.

**Wave 16** *(gap closure; blocked on Wave 15 completion)*

- [x] 73-20-PLAN.md — Reopen the stale security verdict and record the current red deterministic-owner evidence before repairs begin.

**Wave 17** *(gap closure; blocked on Wave 16 completion; Plans 21 and 22 may execute in parallel)*

- [x] 73-21-PLAN.md — Accept the checked-in ready-for-verification lifecycle state through the exact fail-closed governance identity.
- [x] 73-22-PLAN.md — Enforce caller-independent single-flight discovery and exact normalized governed-input inventory.

**Wave 18** *(gap closure; blocked on Wave 17 completion)*

- [x] 73-23-PLAN.md — Prove the repairs through focused and repeated mandatory lanes before resealing the security verdict.

**Wave 19** *(gap closure; blocked on Wave 18 completion)*

- [x] 73-24-PLAN.md — Register current blockers, bind snapshot/workflow authority, and close Mix owner selection grammar.

**Wave 20** *(gap closure; blocked on Wave 19 completion)*

- [x] 73-25-PLAN.md — Consume all task syntax and classify completion-boundary and merge provenance.

**Wave 21** *(gap closure; blocked on Wave 20 completion)*

- [x] 73-26-PLAN.md — Prove every repair and reconcile security and validation from one current proof set.

**Wave 22** *(gap closure; blocked on Wave 21 completion; Plans 27 and 29 may execute in parallel)*

- [x] 73-27-PLAN.md — Reopen stale reports and bind proof identity, live state, and security inventory to independent authority.
- [x] 73-29-PLAN.md — Reject duplicate task children and assign every plan-shaped descendant before governance classification.

**Wave 23** *(gap closure; blocked on Plan 73-27)*

- [x] 73-28-PLAN.md — Anchor required events beneath top-level `on:` and wire real reconciliation into the mandatory security job.

**Wave 24** *(gap closure; blocked on Plans 73-27 through 73-29)*

- [x] 73-30-PLAN.md — Capture, stage, and mandatorily replay one authoritative final proof before resealing reports.

### Phase 74: Clean-Room Package Consumer

**Goal:** A Phoenix developer can install, compile, migrate, boot, and safely exercise
Relyra from the locally built Hex artifact without any checkout-private support.

**Depends on:** Phase 73

**Requirements:** PKG-01, PKG-02, PKG-03, PKG-04, PKG-05, PKG-06

**Success Criteria** (what must be TRUE):

1. The harness builds and unpacks the Hex tarball, and the consumer resolves Relyra only
   from that artifact under isolated Mix, dependency, build, database, and output paths.
2. The consumer cannot load `Relyra.TestSupport`, root fixtures, or unshipped checkout
   files, and a controlled package omission makes the contract fail.
3. From empty state, the consumer runs the installer, compiles with warnings as errors,
   applies host and Relyra migrations, boots, and responds over its real Phoenix router.
4. Representative supported BEAM and optional-dependency profiles compile and execute
   their owned smoke evidence.
5. Reinstallation or upgrade drift is either compatible and intentional or fails with a
   precise diagnostic that identifies the broken adopter contract.

**Plans:** 4/4 planned

Plans:

- [ ] 74-01-PLAN.md — Prove the packaged Phoenix ACS success path from an isolated consumer.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 74-02-PLAN.md — Run library and host migrations and verify persistent store behavior.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 74-03-PLAN.md — Add the package omission negative control and installer drift contracts.

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 74-04-PLAN.md — Exercise the minimal dependency profile and wire the mandatory OTP matrix owner.

### Phase 75: SaaS Twin Domain Realism

**Goal:** LedgerLoop behaves like a small, comprehensible SaaS adopter whose people,
tenants, providers, trust states, and operational history support realistic journeys.

**Depends on:** Phase 74

**Requirements:** TWIN-01, TWIN-02, TWIN-03, TWIN-04, TWIN-05

**Success Criteria** (what must be TRUE):

1. Deterministic fixtures model multiple organizations with distinct admins, end users,
   groups, roles, identities, and authorization outcomes.
2. Connections vary meaningfully by tenant, provider, readiness, and health without
   leaking data or collapsing into copies of one Northstar configuration.
3. Metadata revisions and active, next, expiring, retired, degraded, and recovered
   certificate/trust states form an understandable history.
4. One synthetic support incident has a visible symptom, diagnosis, remediation, retry,
   and recovered state with corresponding trace and audit evidence.
5. Reset produces the same isolated, redaction-safe story every time, with every fixture
   row serving a named scenario.

**Plans:** TBD

### Phase 76: Lifecycle and Recovery Journeys

**Goal:** End users, tenant admins, security reviewers, and operators can complete or
diagnose the high-risk workflows a real adopter will depend on.

**Depends on:** Phase 75

**Requirements:** EVID-03, JOUR-01, JOUR-02, JOUR-03, JOUR-04, JOUR-05, JOUR-06

**Success Criteria** (what must be TRUE):

1. SP-initiated login crosses the real adopter router and behaviour seams, verifies the
   assertion, maps identity/groups, and establishes the adopter-owned session and role.
2. Representative digest, signature, issuer, audience, destination, time, correlation,
   and replay failures yield stable typed rejections and never establish a session.
3. Two organizations remain isolated through resolver, mapping, replay, session, trace,
   audit, and authorization outcomes.
4. A tenant administrator completes metadata review, enablement, staged rollover, and
   recovery while every trust mutation co-commits redaction-safe audit evidence.
5. An operator diagnoses and recovers the seeded incident through correlated redacted
   evidence; browser and scheduled real-IdP canaries have explicit safe failure ownership.

**Plans:** TBD

### Phase 77: Code and Documentation Craftsmanship

**Goal:** A fresh maintainer or adopter encounters clear, self-documenting code and
standalone documentation, with high-value findings resolved and security rationale intact.

**Depends on:** Phase 76

**Requirements:** QUAL-02, QUAL-03, QUAL-04, QUAL-05, QUAL-06

**Success Criteria** (what must be TRUE):

1. Production code and tests use precise names, small justified abstractions, and comments
   only where they explain contracts, intent, or non-obvious security rationale.
2. Public docs, module docs, tests, and demo-facing prose contain no stale phase, plan,
   decision-code, UAT-path, or GSD narration; archived planning history remains intact.
3. Changes near XML, canonicalization, signatures, algorithm policy, replay, and audit
   seams are characterized by existing or strengthened adversarial evidence.
4. The tracked tree contains no unexplained scratch, generated, duplicate, or obsolete
   artifact, and every retained exceptional file has a clear owner.
5. Every critical/high baseline finding is fixed, stopped at an approval checkpoint, or
   dispositioned with concrete evidence and rationale.

**Plans:** TBD

### Phase 78: CI Efficiency and Reliability

**Goal:** Required evidence runs in clearly named, reliable, efficient CI lanes whose
cost and security independence are understandable.

**Depends on:** Phase 77

**Requirements:** PIPE-02, PIPE-03, PIPE-04, PIPE-05

**Success Criteria** (what must be TRUE):

1. Every mandatory requirement has exactly one named owning lane, with intentional
   independent security defenses documented and hollow/skipped Mix gates prohibited.
2. Measured safe parallelism, caching, and setup reuse reduce or justify CI duration
   without allowing checkout leakage, stale consumer state, or cache trust.
3. Workflows consistently use least-privilege permissions, non-colliding concurrency,
   clear names, current actions, and redaction-safe failure artifacts.
4. `mix qa`, formatting, warnings-as-errors tests, `mix ci.security`, package-consumer,
   LedgerLoop, and required browser gates all pass from clean state.

**Plans:** TBD

### Phase 79: Adopter-Ready Closeout

**Goal:** The repository and collaboration surface are intentionally clean, main is
green, and remaining work is demonstrably below the milestone's diminishing-returns line.

**Depends on:** Phase 78

**Requirements:** REPO-01, REPO-02, REPO-03, EXIT-01

**Success Criteria** (what must be TRUE):

1. Main, tracked files, and registered worktrees are clean and intentional, with no
   unexplained generated or scratch artifact.
2. A current inventory reports pull requests, issues, local/remote branches, required
   checks, workflow health, and branch-protection state.
3. Any proposed remote close, label, comment, merge, deletion, or protection mutation is
   presented as an exact batch and occurs only after explicit approval.
4. The full mandatory CI surface is green on main, or any external canary incident is
   explicitly diagnosed and separated from deterministic release readiness.
5. A residual-risk report shows that every remaining idea is low-value, demand-gated,
   approval-blocked, or more costly to maintain than the risk it would retire.

**Plans:** TBD

## Progress

**Execution order:** 73 → 74 → 75 → 76 → 77 → 78 → 79

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---|---|---|
| 73. Twin Contract and Baseline | v1.11 | 33/33 | Complete    | 2026-09-24 |
| 74. Clean-Room Package Consumer | v1.11 | 0/4 | Planned | — |
| 75. SaaS Twin Domain Realism | v1.11 | 0/TBD | Not started | — |
| 76. Lifecycle and Recovery Journeys | v1.11 | 0/TBD | Not started | — |
| 77. Code and Documentation Craftsmanship | v1.11 | 0/TBD | Not started | — |
| 78. CI Efficiency and Reliability | v1.11 | 0/TBD | Not started | — |
| 79. Adopter-Ready Closeout | v1.11 | 0/TBD | Not started | — |

---

*Roadmap proposed: 2026-09-09 — v1.11 First-Adopter Twin (Phases 73–79)*
