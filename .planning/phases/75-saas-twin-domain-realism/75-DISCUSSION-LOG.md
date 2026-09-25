# Phase 75: SaaS Twin Domain Realism - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `75-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-09-25
**Phase:** 75-SaaS Twin Domain Realism
**Mode:** assumptions
**Areas analyzed:** Fixture Ownership and Reset, Tenant Identity and Authorization Shape, Trust History, Synthetic Incident Evidence

## Assumptions Presented

### Fixture Ownership and Reset
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Expand LedgerLoop's existing fixture and reset system as the canonical source for named Phase 75 scenarios. | Confident | `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex:16-47`; `demo/ledger_loop/lib/ledger_loop/demo/reset.ex:16-45`; `demo/ledger_loop/priv/repo/seeds.exs:5`; Phase 73 context |

### Tenant, Identity, and Authorization Shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Represent each organization through tenant-linked people, groups, memberships, and SAML identities, and associate its connections using the tenant organization identifier. | Likely | `demo/ledger_loop/lib/ledger_loop/accounts/user.ex:8-14`; `group.ex:8-14`; `membership.ex:8-13`; `saml_identity.ex:8-14`; `lib/relyra/ecto/connection.ex:28-38`; `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex:13-56` |

### Trust History
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Show trust history by combining readiness, certificate lifecycle and validity, metadata revisions, and audit events into a chronological scenario. | Likely | `lib/relyra/ecto/connection.ex:28-55`; `lib/relyra/ecto/certificate.ex:11-28`; `lib/relyra/ecto/metadata_revision.ex:15-35` |

### Synthetic Incident Evidence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend the existing support scenario with a pre-seeded symptom-to-recovery timeline using trace and audit records; reserve executing recovery for Phase 76. | Confident | `demo/ledger_loop/lib/ledger_loop/demo/reset.ex:46-83`; `lib/relyra/ecto/audit_event.ex:13-48`; `lib/relyra/login_trace/export.ex:70-103`; Phase 74 context |

## Corrections Made

No corrections — the user confirmed all assumptions.

## External Research

None; the codebase and existing phase decisions provided sufficient evidence.
