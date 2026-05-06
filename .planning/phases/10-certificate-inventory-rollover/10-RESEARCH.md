# Phase 10: Certificate inventory + rollover - Research

**Researched:** 2026-05-05 [VERIFIED: system date]  
**Domain:** Elixir/Ecto certificate inventory lifecycle, expiry tracking, and staged rollover for persisted SAML trust state [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: locked phase context, current codebase inspection, local test execution, Hex registry, and official Ecto/Erlang docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Certificate lifecycle model
- **D-01:** Extend `Relyra.Ecto.Certificate` with explicit per-row lifecycle fields for certificate role/state and rollover timing.
- **D-02:** Keep certificate lifecycle state on the durable certificate inventory rows themselves rather than introducing a separate rollover table.
- **D-03:** Metadata revisions remain provenance records and trust-fact history, not the authoritative source for live rollover state.

### Apply and promotion semantics
- **D-04:** Stop replacing the full certificate association wholesale during metadata apply or refresh-driven trust changes.
- **D-05:** New certificates discovered through metadata or manual trust updates should enter inventory as staged non-active rows first.
- **D-06:** Promotion, overlap, retirement, and rollback should be modeled as explicit state transitions on existing certificate rows.

### Runtime trust window
- **D-07:** Runtime hydration continues to expose only the currently trusted active overlap set through canonical `idp_certificates`.
- **D-08:** Persisted `next` and `retired` certificate rows remain available for rollout bookkeeping but are excluded from runtime trust material until their trust window explicitly changes.
- **D-09:** Phase 10 must add an explicit trust-set selection rule at the persistence-to-runtime seam so rollover windows are deliberate and observable instead of implied by “all rows currently preload.”

### the agent's Discretion
- Exact enum atoms, field names, and date/window columns for lifecycle timing, as long as active/next/retired intent is explicit and queryable.
- Whether certificate role and lifecycle state live as separate fields or one bounded enum, provided promotion and rollback remain unambiguous.
- Exact service/module split for staging, promotion, and rollback operations, provided replace-in-place deletion stops being the trust update mechanism.

### Deferred Ideas (OUT OF SCOPE)
- Scheduled or background certificate rollover automation.
- Admin-facing rollover timeline and approval UX.
- Broader cross-domain audit export/reporting beyond the rollover model itself.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CFG-04 | User can manage certificate inventory for a connection with expiry tracking and staged rollover. [VERIFIED: .planning/REQUIREMENTS.md] | The codebase already stages metadata certificates as `:next`, filters runtime hydration to `:active` signing certs, and exposes activate/retire/rollback helpers; Phase 10 planning should therefore focus on expiry derivation, invariant-safe transition orchestration, eliminating remaining replace-on-update paths, and validation coverage for overlap/rollback semantics. [VERIFIED: lib/relyra/ecto/metadata_apply.ex, lib/relyra/ecto/certificate_inventory.ex, lib/relyra/ecto/connection_snapshot.ex, test/relyra/ecto/metadata_apply_test.exs, test/relyra/ecto/ecto_connection_resolver_test.exs] |
</phase_requirements>

## Summary

The planner does not need another slice for lifecycle enums, staged `:next` rows, activate/retire/rollback entrypoints, or runtime filtering to active certs; those mechanics already exist in code and tests. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/ecto/certificate_inventory.ex, lib/relyra/ecto/connection_snapshot.ex, test/relyra/ecto/metadata_apply_test.exs, test/relyra/ecto/ecto_connection_resolver_test.exs, test/relyra/connection_snapshot_test.exs]

What still needs planning is the safety and completeness layer around those mechanics. Four gaps remain. `CFG-04` is still incomplete on expiry tracking because `not_before` and `not_after` are stored on certificate rows but never populated by metadata import or inventory writes. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/metadata/import.ex, lib/relyra/metadata/parser.ex] The generic connection changeset still leaves a delete-by-omission path open through `cast_assoc(:certificates)` plus `on_replace: :delete`, so the planner needs an explicit slice that removes certificate rollover from generic connection updates entirely. [VERIFIED: lib/relyra/ecto/connection.ex, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] The transition helpers need a bounded state matrix and typed failure coverage, because current activation/retirement checks do not fully constrain source states. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex] Finally, the planner must choose a concurrency contract and DB invariant posture, because current rollover writes have no lock/version strategy and no lifecycle-specific indexes or constraints beyond fingerprint uniqueness. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex, priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs, priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]

The planning recommendation is to treat Phase 10 as a hardening phase with three concrete deliveries: populate certificate validity facts, seal the write boundary so rollover can only happen through explicit inventory services, and add the invariant/concurrency coverage that makes promotions and rollbacks unambiguous under real writes. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md] [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

**Primary recommendation:** Plan three slices and no more: `1)` expiry-fact extraction and persistence, `2)` removal of generic association replacement for certificate writes, and `3)` invariant, concurrency, and validation hardening around the existing activate/retire/rollback surface. [VERIFIED: lib/relyra/ecto/connection.ex, lib/relyra/ecto/certificate_inventory.ex, lib/relyra/metadata/import.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Certificate validity extraction from PEM | API / Backend | Database / Storage | PEM decode and X.509 validity parsing are trust-bearing backend concerns whose output becomes persisted certificate facts. [VERIFIED: lib/relyra/metadata/import.ex, lib/relyra/ecto/certificate.ex] [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html] |
| Certificate inventory persistence | Database / Storage | API / Backend | The canonical lifecycle state lives on certificate rows and is the authoritative trust inventory. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md, lib/relyra/ecto/certificate.ex] |
| Promotion / retirement / rollback orchestration | API / Backend | Database / Storage | Transition logic must validate preconditions, run atomically, and return typed errors before any row mutation becomes live. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Active trust-set selection for runtime | API / Backend | Database / Storage | The persistence-to-runtime seam remains the single place that converts lifecycle-rich rows into runtime `idp_certificates`. [VERIFIED: lib/relyra/ecto/connection_loader.ex, lib/relyra/ecto/connection_snapshot.ex, .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] |
| Metadata-driven certificate staging | API / Backend | Database / Storage | Metadata apply should keep using staged `:next` rows and must not directly rewrite the active trust set. [VERIFIED: lib/relyra/ecto/metadata_apply.ex, test/relyra/ecto/metadata_apply_test.exs, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | repo constraint `~> 3.13`; locked `3.13.5`; latest `3.13.6` published `2026-05-05` [VERIFIED: mix.exs, hex registry] | Schema changesets, lifecycle validation, and transaction orchestration for trust-bearing writes. [CITED: https://hexdocs.pm/ecto/Ecto.html] | The current certificate inventory and connection aggregate already use Ecto as the persistence boundary. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/ecto/connection.ex, lib/relyra/ecto/certificate_inventory.ex] |
| Ecto SQL | repo constraint `~> 3.13`; locked `3.13.5`; latest `3.13.5` published `2026-03-03` [VERIFIED: mix.exs, hex registry] | Migrations for lifecycle constraints and lookup indexes. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] | Phase 10 should extend the existing Postgres/Ecto migration model instead of introducing a side table or non-SQL state mechanism. [VERIFIED: priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs, priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs] |
| Postgrex | locked `0.22.0`; latest `0.22.1` published `2026-05-05` [VERIFIED: hex registry] | Postgres adapter for migration and integration-test coverage of rollover invariants. [VERIFIED: mix.exs, test/support/ecto_test_repo.ex] | Current migration-backed tests already execute against Postgres. [VERIFIED: test/support/migration_case.ex, mix test output 2026-05-05] |
| OTP `:public_key` | available in local OTP 28 runtime [VERIFIED: elixir --version, erl system_info] | Decode PEM/X.509 certificates and extract validity windows without adding a new dependency. [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html] | Phase 10 still needs real expiry tracking, and OTP already ships the certificate decode APIs needed for `not_before`/`not_after`. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/metadata/import.ex, lib/relyra/metadata/parser.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | repo constraint `~> 1.8`; locked `1.8.5`; latest `1.8.6` published `2026-05-05` [VERIFIED: mix.exs, hex registry] | Existing request-time resolver consumers. [VERIFIED: lib/relyra/phoenix/controllers/login_controller.ex, lib/relyra/phoenix/controllers/metadata_controller.ex] | Use only to verify Phase 10 does not change the runtime boundary consumed by controllers. [VERIFIED: .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md] |
| telemetry | locked `1.4.1`; latest `1.4.1` published `2026-03-09` [VERIFIED: mix.exs, hex registry] | Non-authoritative measurements around rollover operations. [VERIFIED: lib/relyra/telemetry.ex] | Use for timings and counts only; do not treat telemetry as the durable lifecycle ledger. [VERIFIED: .planning/PROJECT.md, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| OTP `:public_key` for validity extraction | Custom regex/string parsing of PEM bodies | Official OTP docs already provide PEM decode and PKIX decode APIs; hand-parsing validity windows is unnecessary and brittle. [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html] |
| Explicit service-level rollover operations | Parent `cast_assoc(:certificates)` updates on `Relyra.Ecto.Connection` | Ecto treats the provided association list as canonical and will apply the association’s `:on_replace` behavior to missing children, which is the exact outage-prone path this phase is meant to avoid. [VERIFIED: lib/relyra/ecto/connection.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| `Repo.transact/2` for fixed transition flows | `Ecto.Multi` for every rollover path | Current Ecto docs say `Ecto.Multi` is particularly useful when the operation set is dynamic; fixed promotion/retirement flows are simpler in `Repo.transact/2`, while composite rollback helpers may still benefit from `Ecto.Multi`. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** [VERIFIED: hex registry]
```bash
mix hex.info ecto
mix hex.info ecto_sql
mix hex.info postgrex
mix hex.info phoenix
mix hex.info telemetry
```

## Architecture Patterns

### System Architecture Diagram

```text
Metadata import / manual trust update / rollover command
                    |
                    v
         Certificate facts extraction
      (PEM decode -> fingerprint -> validity)
                    |
                    v
    CertificateInventory service boundary
  stage | promote | retire | rollback | query
                    |
                    v
           Repo.transact / Ecto.Multi
                    |
    +---------------+------------------+
    |                                  |
    v                                  v
certificate row lifecycle        connection-level guard/
updates and timestamps           concurrency coordination
    |                                  |
    +---------------+------------------+
                    |
                    v
      persisted certificate inventory
                    |
                    v
        ConnectionLoader preload + guard
                    |
                    v
 ConnectionSnapshot active-signing filter
                    |
                    v
 runtime idp_certificates trust set
```

The critical boundary is unchanged: persistence may store `:active`, `:next`, and `:retired`, but runtime still hydrates only the active signing trust set. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md, lib/relyra/ecto/connection_snapshot.ex, test/relyra/connection_snapshot_test.exs]

### Recommended Project Structure
```text
lib/relyra/
├── ecto/
│   ├── certificate.ex              # schema + lifecycle field validation
│   ├── certificate_inventory.ex    # stage/promote/retire/rollback service boundary
│   ├── certificate_facts.ex        # PEM/X.509 decode -> not_before/not_after
│   ├── connection.ex               # remove generic certificate replacement path
│   └── metadata_apply.ex           # keep staging via certificate inventory only
└── metadata/
    └── import.ex                   # attach certificate facts during candidate build/apply
```

`certificate_facts.ex` is a recommended new seam, not a verified existing file; its purpose is only to fill the current expiry/facts gap. [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html] [VERIFIED: absence from `rg --files lib/relyra/ecto` search 2026-05-05]

### Pattern 1: Facts-First Certificate Staging
**What:** Extract PEM fingerprint and validity facts before inserting or updating inventory rows so staged certificates carry usable expiry data immediately. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/metadata/import.ex] [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html]
**When to use:** Metadata import, refresh, and any future manual certificate add/update path. [VERIFIED: lib/relyra/metadata/import.ex, lib/relyra/metadata/refresh.ex, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md]
**Example:**
```elixir
# Source: https://www.erlang.org/docs/27/apps/public_key/public_key.html
[entry] = :public_key.pem_decode(pem)
der = :public_key.pem_entry_decode(entry)
cert = :public_key.pkix_decode_cert(der, :otp)
```

### Pattern 2: Explicit Transition API, Not Parent Association Replacement
**What:** Keep certificate state changes behind inventory APIs that load the connection, validate allowed transitions, and persist only the intended row changes. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
**When to use:** Promotion, retirement, and rollback operations. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex, test/relyra/ecto/ecto_connection_resolver_test.exs]
**Example:**
```elixir
# Source: /Users/jon/projects/relyra/lib/relyra/ecto/certificate_inventory.ex
repo.transact(fn ->
  do_transition(repo, connection, fingerprint, :active, :activate_signing_certificate)
end)
```

### Pattern 3: DB-Assisted Invariants for Hot Queries and Safety
**What:** Add explicit index names and partial indexes for active signing lookups or state-specific uniqueness when the rule belongs in storage, not only in Elixir guards. [VERIFIED: current migrations lack lifecycle-specific indexes] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]
**When to use:** Queries that repeatedly load active trust rows and invariants that should survive concurrent writers. [VERIFIED: lib/relyra/ecto/connection_loader.ex, lib/relyra/ecto/connection_snapshot.ex]
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto_sql/Ecto.Migration.html
create index(
  :relyra_connection_certificates,
  [:connection_record_id, :lifecycle_state],
  where: "role = 'signing' AND lifecycle_state = 'active'",
  name: :relyra_certificates_active_signing_idx
)
```

### Anti-Patterns to Avoid
- **Generic connection updates that include `certificates`:** `Relyra.Ecto.Connection.update_changeset/2` still conditionally `cast_assoc(:certificates)` against a `has_many ... on_replace: :delete`, which is the wrong write path for rollover state. [VERIFIED: lib/relyra/ecto/connection.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]
- **Fingerprint-only “expiry tracking”:** The schema has validity columns, but Phase 10 is not complete if those fields remain unused. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/metadata/import.ex]
- **Transitioning rows without source-state checks:** Activation currently checks only `role == :signing`, not whether the source row was actually `:next`. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex]
- **Assuming in-memory checks are enough under concurrent writes:** Current helpers load, validate, and update inside transactions, but no version column or row-lock rule is present in the schema today. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex, lib/relyra/ecto/connection.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PEM and X.509 validity parsing | Regex extraction of certificate dates | OTP `:public_key.pem_decode/1`, `pem_entry_decode/1`, and `pkix_decode_cert/2` [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html] | OTP already ships certificate decode primitives; Phase 10 needs facts, not a bespoke ASN.1 parser. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/metadata/import.ex] |
| Multi-row rollover writes | Hand-managed “if step fails, undo prior update” branches | `Repo.transact/2` and selective `Ecto.Multi` composition [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | Promotion/retirement/rollback mutate trust-bearing state and must stay atomic. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex, test/relyra/ecto/metadata_apply_test.exs] |
| Rollover updates through parent association replacement | `cast_assoc(:certificates)` on the connection record | Dedicated `CertificateInventory` APIs and targeted row updates [VERIFIED: lib/relyra/ecto/certificate_inventory.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] | Parent-association replacement reintroduces delete-by-omission semantics. [VERIFIED: lib/relyra/ecto/connection.ex, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md] |
| Invariant enforcement only in application code | Ad hoc post-write cleanup | Named DB indexes/constraints where the invariant belongs in storage [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] | Storage-backed trust state should fail closed even under concurrent writers. [VERIFIED: current lifecycle migrations define columns but no lifecycle-specific indexes or check constraints] |

**Key insight:** The risky part of Phase 10 is not adding more lifecycle atoms; it is making sure every trust-set change is explicit, atomic, and reconstructable from persisted facts. [VERIFIED: .planning/PROJECT.md, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md, lib/relyra/ecto/certificate_inventory.ex]

## Common Pitfalls

### Pitfall 1: Leaving the generic `certificates` association writable
**What goes wrong:** A future connection update can still treat the provided certificate list as canonical and delete omitted rows through `on_replace: :delete`. [VERIFIED: lib/relyra/ecto/connection.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]
**Why it happens:** The connection changeset still supports `cast_assoc(:certificates)` when `attrs` includes a certificates key. [VERIFIED: lib/relyra/ecto/connection.ex]
**How to avoid:** Remove certificate casting from generic connection update/publish flows or change the association behavior so certificate writes must go through inventory services only. [VERIFIED: lib/relyra/ecto/connection.ex, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md]
**Warning signs:** Tests update a connection with a shortened `certificates` list, or plans keep using `Connection.update_changeset/2` for rollover workflows. [VERIFIED: lib/relyra/ecto/connection.ex, existing Phase 10 tests do not yet cover this path]

### Pitfall 2: Shipping “expiry tracking” without populating validity fields
**What goes wrong:** Operators can stage and promote certificates, but `not_before` and `not_after` remain `nil`, so there is no real expiry signal or query surface. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/metadata/import.ex, lib/relyra/metadata/parser.ex]
**Why it happens:** The metadata pipeline currently normalizes only certificate PEMs and SHA-256 fingerprints. [VERIFIED: lib/relyra/metadata/import.ex, lib/relyra/metadata/candidate.ex]
**How to avoid:** Add a certificate-facts extraction step before row insert/update and verify it on both metadata import and direct inventory mutations. [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html]
**Warning signs:** Integration tests assert only lifecycle states and PEM ordering, with no assertions on `not_before` or `not_after`. [VERIFIED: test/relyra/ecto/metadata_apply_test.exs, test/relyra/ecto/ecto_connection_resolver_test.exs]

### Pitfall 3: Allowing invalid lifecycle transitions
**What goes wrong:** A row can be re-activated or retired from an unexpected source state, producing a history that is technically persisted but semantically ambiguous. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex]
**Why it happens:** Current activation validates signing role, and retirement validates “not last active,” but neither helper enforces a bounded source-state transition matrix. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex]
**How to avoid:** Encode allowed source→target transitions explicitly and test every invalid edge with typed errors. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md, lib/relyra/ecto/certificate_inventory.ex]
**Warning signs:** Tests cover happy-path overlap and rollback only, with no assertions that `:active -> :active`, `:retired -> :active`, or `:next -> :retired` are rejected when unsupported. [VERIFIED: test/relyra/ecto/metadata_apply_test.exs, test/relyra/ecto/ecto_connection_resolver_test.exs]

### Pitfall 4: Ignoring concurrent rollover mutations
**What goes wrong:** Two operators or automation hooks can stage conflicting promotions or retirements and the “last write wins” behavior becomes the real trust policy. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [VERIFIED: no `lock_version` field or lock-specific migration exists in current certificate/connection schemas]
**Why it happens:** The current schema has no optimistic-lock column, and current transition helpers rely on a fresh preload plus row update without an explicit concurrency contract. [VERIFIED: lib/relyra/ecto/connection.ex, lib/relyra/ecto/certificate_inventory.ex]
**How to avoid:** Plan either optimistic locking on the parent connection row or explicit row locking around transition orchestration before adding more mutation entrypoints. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
**Warning signs:** No tests race promotion and rollback attempts, and no migration adds a version field or lock-related invariant. [VERIFIED: test/relyra/ecto/metadata_apply_test.exs, test/relyra/ecto/ecto_connection_resolver_test.exs, priv/repo/migrations/* search 2026-05-05]

## Code Examples

Verified patterns from official sources:

### Atomic Trust Transition
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
Repo.transact(fn repo ->
  {:ok, certificate} = repo.update(certificate_changeset)
  {:ok, certificate}
end)
```

### Dynamic Composite Transition
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.update(:activate, activate_changeset)
|> Ecto.Multi.update(:retire, retire_changeset)
|> Repo.transact()
```

### Partial Index For Active Signing Lookup
```elixir
# Source: https://hexdocs.pm/ecto_sql/Ecto.Migration.html
create index(
  :relyra_connection_certificates,
  [:connection_record_id, :lifecycle_state],
  where: "role = 'signing' AND lifecycle_state = 'active'",
  name: :relyra_certificates_active_signing_idx
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Repo.transaction/2` | `Repo.transact/2` [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | Current Ecto docs mark `transaction/2` deprecated in favor of `transact/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | New Phase 10 services should use `transact/2` in code and examples so the planner does not bake in an outdated API. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Replace-whole-association certificate updates | Row-level staged inventory plus explicit promotion/retirement semantics [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md, lib/relyra/ecto/certificate_inventory.ex] | The v0.2 certificate model shifted in Phase 09/10 groundwork when lifecycle columns and inventory services landed. [VERIFIED: priv/repo/migrations/20260505140000_add_certificate_lifecycle_to_relyra_connection_certificates.exs, test/relyra/ecto/metadata_apply_test.exs] | Planning should optimize for explicit row transitions, not for richer connection changesets. [VERIFIED: lib/relyra/ecto/connection.ex, lib/relyra/ecto/certificate_inventory.ex] |
| “Any persisted cert is runtime trust” | Runtime snapshot filters to active signing rows only [VERIFIED: lib/relyra/ecto/connection_snapshot.ex, test/relyra/connection_snapshot_test.exs] | This filter is already present in current Phase 08/09 code. [VERIFIED: lib/relyra/ecto/connection_snapshot.ex, test/relyra/connection_snapshot_test.exs] | Phase 10 should preserve this seam and make the upstream lifecycle rules more explicit, not broaden runtime reads. [VERIFIED: .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md] |

**Deprecated/outdated:**
- `Repo.transaction/2`: deprecated in current Ecto docs; use `Repo.transact/2` for new Phase 10 services. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- Generic connection-level certificate replacement for rollover writes: still present in `Relyra.Ecto.Connection`, but outdated for this trust domain because it conflicts with the phase’s explicit state-transition model. [VERIFIED: lib/relyra/ecto/connection.ex, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited — no user confirmation needed. [VERIFIED: research artifact contents]

## Open Questions (RESOLVED)

1. **Should Phase 10 persist lightweight operator/cause metadata on lifecycle transitions now, or only in Phase 11?**
   - Resolution: Phase 10 does not block on a new audit subsystem. If execution can add `actor` and `cause` passthrough into certificate-row `metadata` cheaply and without widening the public API surface, that is acceptable as forward-compatible groundwork. Otherwise lifecycle attribution is explicitly deferred to Phase 11, and `CFG-04` is satisfied by explicit state transitions, expiry facts, and typed rollover errors alone. [VERIFIED: existing `metadata` map field on certificate rows, .planning/REQUIREMENTS.md, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md]

2. **Which concurrency contract should the planner choose for trust-changing operations?**
   - Resolution: Phase 10 uses optimistic locking on the parent connection row as the default concurrency contract for promotion, retirement, and rollback. This gives host apps a deterministic stale/conflict failure mode without requiring heavier row-lock semantics across the whole write path. If optimistic lock conflicts later prove too noisy in real operator workflows, explicit row locking becomes a follow-on refinement rather than the baseline plan. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and run Phase 10 services/tests | ✓ [VERIFIED: local shell] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Erlang/OTP | `:public_key` certificate parsing and runtime execution | ✓ [VERIFIED: local shell] | `28` [VERIFIED: `erl ... system_info(otp_release)`] | — |
| Mix | Test/migration commands | ✓ [VERIFIED: local shell] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL | Migration-backed certificate inventory tests | ✓ [VERIFIED: local shell] | `14.17` [VERIFIED: `psql --version`] | Docker-backed local Postgres is available if the local server setup changes. [VERIFIED: `docker --version`] |
| Docker | Optional isolated DB fallback | ✓ [VERIFIED: local shell] | `29.4.1` [VERIFIED: `docker --version`] | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: environment audit 2026-05-05]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment audit 2026-05-05]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix on Elixir `1.19.5` [VERIFIED: mix.exs, `mix --version`] |
| Config file | none — test aliases and dependencies are defined in `mix.exs`. [VERIFIED: mix.exs] |
| Quick run command | `mix test test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors` [VERIFIED: local test run 2026-05-05] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: mix.exs alias posture and existing test layout] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-04 | Metadata-imported certificates stage as `:next` while runtime trust stays on active rows. [VERIFIED: current behavior] | integration | `mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors` | ✅ [VERIFIED: test file exists and passed 2026-05-05] |
| CFG-04 | Promotion and retirement change `idp_certificates` explicitly and preserve overlap/rollback semantics. [VERIFIED: current behavior] | integration | `mix test test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs --warnings-as-errors` | ✅ [VERIFIED: test files exist and passed 2026-05-05] |
| CFG-04 | Runtime hydration excludes `:next` and `:retired` rows. [VERIFIED: current behavior] | unit | `mix test test/relyra/connection_snapshot_test.exs --warnings-as-errors` | ✅ [VERIFIED: test file exists and passed 2026-05-05] |
| CFG-04 | Certificate validity fields are derived and persisted for staged/manual certificates. [VERIFIED: not currently covered] | integration | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs --warnings-as-errors` | ❌ Wave 0 [VERIFIED: file absent from current tree] |
| CFG-04 | Invalid lifecycle transitions fail with typed errors. [VERIFIED: not currently covered] | unit/integration | `mix test test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors` | ❌ Wave 0 [VERIFIED: file absent from current tree] |
| CFG-04 | Concurrent promotion/rollback conflicts fail closed. [VERIFIED: not currently covered] | integration/manual stress | `mix test test/relyra/ecto/certificate_inventory_concurrency_test.exs --warnings-as-errors` | ❌ Wave 0 [VERIFIED: file absent from current tree] |

### Sampling Rate
- **Per task commit:** `mix test test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors` [VERIFIED: local pass 2026-05-05]
- **Per wave merge:** `mix test --warnings-as-errors` [VERIFIED: project test posture in `mix.exs`]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: Nyquist validation enabled in `.planning/config.json`]

### Wave 0 Gaps
- [ ] `test/relyra/ecto/certificate_inventory_expiry_test.exs` — covers CFG-04 expiry derivation and persistence for imported/staged certs. [VERIFIED: file absent; no existing assertions on `not_before`/`not_after`] 
- [ ] `test/relyra/ecto/certificate_inventory_transition_test.exs` — covers invalid source→target transitions and typed errors. [VERIFIED: file absent; current tests are happy-path heavy]
- [ ] `test/relyra/ecto/certificate_inventory_concurrency_test.exs` — covers concurrent promotion/rollback behavior or lock-version failure mode. [VERIFIED: file absent]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: Phase 10 is inventory/rollover, not user auth] | Host application auth is outside this phase boundary. [VERIFIED: .planning/PROJECT.md out-of-scope rules] |
| V3 Session Management | no [VERIFIED: Phase 10 does not manage sessions] | — |
| V4 Access Control | yes [VERIFIED: promotion/retirement/rollback are privileged trust mutations] | Keep rollover behind explicit backend APIs so host apps can authorize the caller before invoking them; do not expose mutation through generic connection updates. [VERIFIED: lib/relyra/ecto/certificate_inventory.ex, lib/relyra/ecto/connection.ex] |
| V5 Input Validation | yes [VERIFIED: PEMs, fingerprints, and lifecycle transitions are untrusted inputs] | Use changesets plus explicit transition validation and reject malformed or incomplete certificate facts. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/ecto/certificate_inventory.ex] |
| V6 Cryptography | yes [VERIFIED: certificate validity and trust material are cryptographic artifacts] | Use OTP `:public_key` and existing SHA-256 hashing; never hand-roll ASN.1/X.509 parsing. [VERIFIED: lib/relyra/metadata/import.ex uses SHA-256] [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html] |

### Known Threat Patterns for Elixir/Ecto trust inventory rollover

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental trust deletion through parent association replacement | Tampering | Remove or block generic `cast_assoc(:certificates)` rollover writes and use dedicated lifecycle APIs only. [VERIFIED: lib/relyra/ecto/connection.ex, lib/relyra/ecto/certificate_inventory.ex] |
| Invalid certificate promoted without validity facts | Tampering | Derive and persist `not_before`/`not_after` before the row can become active. [VERIFIED: lib/relyra/ecto/certificate.ex] [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html] |
| Concurrent lifecycle writes cause ambiguous active set | Tampering / Repudiation | Add optimistic locking or explicit row locking plus tests for conflict behavior. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| PEM/XML leakage in logs during trust operations | Information Disclosure | Keep telemetry/logs redacted and avoid logging raw PEM or XML payloads from rollover paths. [VERIFIED: .planning/PROJECT.md explainable-but-redacted posture, lib/relyra/log.ex, lib/relyra/metadata/refresh.ex] |
| Expired cert remains trusted because state and validity are disconnected | Elevation of Privilege | Make expiry facts queryable and cover promotion/retirement rules with tests that exercise expired or missing-validity rows. [VERIFIED: current schema supports dates but tests do not cover them] |

## Sources

### Primary (HIGH confidence)
- Local phase context and requirements files — scope, locked decisions, and success criteria checked. [VERIFIED: .planning/REQUIREMENTS.md, .planning/PROJECT.md, .planning/ROADMAP.md, .planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md, .planning/phases/07-schema-connection-aggregate/07-CONTEXT.md, .planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md, .planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md]
- Local code and tests — current lifecycle fields, runtime filtering, metadata staging, and transition helpers checked. [VERIFIED: lib/relyra/ecto/certificate.ex, lib/relyra/ecto/certificate_inventory.ex, lib/relyra/ecto/connection.ex, lib/relyra/ecto/connection_loader.ex, lib/relyra/ecto/connection_snapshot.ex, lib/relyra/ecto/metadata_apply.ex, lib/relyra/metadata/import.ex, lib/relyra/metadata/parser.ex, test/relyra/ecto/metadata_apply_test.exs, test/relyra/ecto/ecto_connection_resolver_test.exs, test/relyra/connection_snapshot_test.exs]
- Local verification commands — package versions, environment availability, and targeted tests checked. [VERIFIED: `mix hex.info ecto`, `mix hex.info ecto_sql`, `mix hex.info postgrex`, `mix hex.info phoenix`, `mix hex.info telemetry`, `elixir --version`, `mix --version`, `psql --version`, `docker --version`, targeted `mix test` run on 2026-05-05]
- Official Ecto docs — transaction, association replacement, optimistic locking, and migration-index guidance checked. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]
- Official Erlang `public_key` docs — PEM decode and PKIX decode APIs checked. [CITED: https://www.erlang.org/docs/27/apps/public_key/public_key.html]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: research used codebase, Hex registry, and official docs only]

### Tertiary (LOW confidence)
- None. [VERIFIED: no uncited web-only claims were used]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase uses the repo’s existing Ecto/Postgres stack plus official OTP certificate APIs, all verified against current code and registry data. [VERIFIED: mix.exs, hex registry, Erlang docs]
- Architecture: HIGH - the current runtime seam, metadata staging behavior, and inventory primitives are already present in code and tests, leaving the remaining work narrowly scoped. [VERIFIED: lib/relyra/ecto/connection_snapshot.ex, lib/relyra/ecto/certificate_inventory.ex, test/relyra/ecto/metadata_apply_test.exs]
- Pitfalls: HIGH - each pitfall maps to an observed current code path or an official Ecto behavior. [VERIFIED: lib/relyra/ecto/connection.ex, lib/relyra/ecto/certificate_inventory.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

**Research date:** 2026-05-05 [VERIFIED: system date]  
**Valid until:** 2026-06-04 for repo-internal findings; re-check Hex versions and docs if planning starts later. [VERIFIED: volatile sources are package versions and current docs]
