# Phase 26: Security Audit Preparation and Remediation - Research

**Researched:** 2026-05-08 [VERIFIED: current session date]
**Domain:** Third-party security review preparation, executable evidence, and remediation workflow for an Elixir/Phoenix SAML SP library [VERIFIED: `.planning/ROADMAP.md`] [VERIFIED: `.planning/milestones/v1.0-REQUIREMENTS.md`]
**Confidence:** HIGH [VERIFIED: local repo evidence dominates the recommendation surface]

<user_constraints>
## User Constraints (from CONTEXT.md) [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`]

### Locked Decisions

### Auditor artifact package
- **D-01:** Phase 26 should produce a compact, repo-native audit packet rather than a README-only rewrite, a separate docs site, or a code-only handoff.
- **D-02:** The audit packet should be one canonical reviewer entry point that links to security boundary docs, conformance evidence, strict-default and escape-hatch proof, canonical code seams, and exact rerun commands.
- **D-03:** Auditor-facing material should live in-repo and stay diffable alongside the code and tests it describes. Avoid introducing a second truth surface for security claims.
- **D-04:** README changes in this phase should stay targeted to pointing reviewers and adopters at the right canonical security docs, not expand into general onboarding polish.

### Remediation policy
- **D-05:** All High and Critical external-audit findings block v1.0 until remediated, regression-tested, and captured in verification artifacts.
- **D-06:** Medium findings require explicit disposition before release: either fix in Phase 26 or defer with written rationale, compensating controls, owner, and revisit phase/date.
- **D-07:** Low and Informational findings may defer only if they are still recorded in a findings ledger with scope, rationale, and follow-up ownership.
- **D-08:** Severity handling must bias toward exploitability at the SAML trust boundary rather than cosmetic or style-oriented audit commentary.
- **D-09:** Every accepted security bug fixed in Phase 26 should become permanent regression coverage where practical, following the same corpus-minded discipline established in Phase 25.

### Proof style for strict defaults and escape hatches
- **D-10:** Proof should use a mixed bundle with an executable core: concise reviewer docs plus rerunnable ExUnit evidence and generated artifacts.
- **D-11:** Executable evidence remains primary. Narrative docs should map invariants to seams and tests, not replace proof with prose.
- **D-12:** Strict-default evidence must explicitly show fail-closed behavior for unsafe algorithms, signed-content trust rules, replay/trust boundaries, and other relevant rejection paths.
- **D-13:** Escape-hatch evidence must explicitly show that risky compatibility or bypass paths are time-boxed or constrained, attributable, correlated, and redaction-safe in the audit trail.
- **D-14:** Reviewer artifacts for Phase 26 should mirror the successful Phase 25 pattern: generated evidence derived from executable state, not hand-maintained status prose.

### External review target surface
- **D-15:** The external review should be trust-boundary-first: XML parsing, signed-node selection, signature trust, protocol validation, RelayState handling, request/replay protection, metadata trust anchors and refresh, certificate lifecycle, SLO, audit/redaction guarantees, and library-owned Phoenix/admin seams.
- **D-16:** The library-owned Phoenix surface is in scope only where Relyra defines the contract: routes/controllers, LiveView mount boundaries, admin risk/override surfacing, and other library-owned trust seams.
- **D-17:** Host-application-specific authn/authz, custom `ScopeProvider` logic, app router policy beyond Relyra's contract, and generic admin UX polish are out of scope for the third-party review and must be called out as assumptions.
- **D-18:** The scope must be narrow enough to preserve audit depth on real exploit paths, but broad enough to include the operational trust boundary beyond the original protocol core.

### DX and reviewer ergonomics
- **D-19:** Reviewer UX should optimize for least surprise: one entry doc, one rerun path, one map from claim to seam to test to artifact.
- **D-20:** Planning and execution for this phase should remain recommendation-first and low-friction. Low-risk shape decisions should be auto-resolved by downstream agents; escalate only unusually impactful product, security, or architecture choices.

### Claude's Discretion
- Exact naming and file layout of the audit packet, provided there is one canonical reviewer entry point and no duplicate truth surfaces.
- Exact generated artifact format for strict-default and bypass evidence, provided it is executable-state-derived and easy for auditors to rerun.
- Exact severity rubric phrasing, provided it remains exploitability-first and consistent with the locked remediation policy.
- Exact split between tests, generated docs, and concise seam docs, provided executable proof remains primary.

### Deferred Ideas (OUT OF SCOPE)
- Broad adopter-onboarding polish, case studies, and README expansion beyond what the auditor packet needs — Phase 27.
- Separate docs-site or enterprise-portal style presentation layer for security review material.
- Full adopter-application security review guidance beyond Relyra's own library-owned trust boundary.
- Project-level GSD preference tuning to make recommendation-first, agent-resolved decision handling even more automatic across future workflows; desirable, but not Phase 26 delivery scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEC-REVIEW-01 | Complete third-party security audit preparation and remediate high-priority findings. [VERIFIED: `.planning/milestones/v1.0-REQUIREMENTS.md`] | Use one repo-native audit packet that maps scope, trust boundaries, rerun commands, generated evidence, and a severity-disposition ledger onto the existing `mix ci.security`, `mix ci.verify`, `mix relyra.conformance --check`, targeted strict-default tests, and redaction-safe diagnostic/audit seams. [VERIFIED: `mix.exs`] [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] [VERIFIED: `test/security/signature_policy_test.exs`] [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] [VERIFIED: `lib/relyra/diagnostic.ex`] |
</phase_requirements>

## Summary

Relyra already has the core evidence substrate this phase needs: generated conformance output with drift checking, targeted security test lanes, strict-default algorithm enforcement, typed metadata-trust escape hatches, redaction-safe audit writing, and a redacted diagnostic bundle export. [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] [VERIFIED: `mix.exs`] [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] [VERIFIED: `lib/relyra/metadata/auto_refresh.ex`] [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] [VERIFIED: `lib/relyra/diagnostic.ex`] Phase 26 should package those seams into a reviewer workflow instead of inventing new security machinery. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`]

The highest-value deliverable is not a broad doc rewrite. It is a narrow, executable audit packet with one entry document, a boundary map, a generated proof artifact for strict defaults and escape hatches, a findings ledger, and exact rerun commands. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] [VERIFIED: `.planning/phases/25-conformance-and-cve-regression-fixtures/25-RESEARCH.md`] The packet should explicitly separate library-owned trust seams from host-app-owned authn/authz policy so third-party reviewers spend time on exploit paths Relyra actually controls. [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`]

The main planning risks are duplicate truth surfaces, prose-only security claims, and weak disposition handling after findings arrive. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] The repo already shows the right precedent: `CONFORMANCE.md` is generated from executable manifest state, and `AuditWriter` plus `Diagnostic.AllowList` prove that reviewer-facing evidence can be attributable without leaking XML, PEM, RelayState, or actor PII. [VERIFIED: `CONFORMANCE.md`] [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`]

**Primary recommendation:** Implement a single `SECURITY_REVIEW.md`-style reviewer entry point plus one generated evidence artifact and one findings ledger, all derived from rerunnable Mix/Test commands and existing trust-boundary seams. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Security review packet generation | API / Backend | CDN / Static | The repo already generates reviewer-facing markdown through Mix tasks, so packet assembly belongs in backend build tooling and emits static docs. [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] |
| Strict-default proof | API / Backend | Frontend Server (SSR) | SHA-1 rejection, signature trust checks, replay handling, and protocol validation live in library code and tests, not the browser. [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] [VERIFIED: `lib/relyra.ex`] [VERIFIED: `lib/relyra/protocol/validation_pipeline.ex`] |
| Escape-hatch proof | API / Backend | Frontend Server (SSR) | Legacy SHA-1 and unsigned-metadata exceptions are encoded in policy structs and metadata refresh paths, while the admin surface only displays their state. [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] [VERIFIED: `lib/relyra/metadata/auto_refresh.ex`] [VERIFIED: `lib/relyra/live_admin/query.ex`] |
| Audit/redaction evidence | Database / Storage | API / Backend | Audit rows, metadata revisions, and diagnostic exports are persisted or derived from persisted state and then normalized by library-owned redaction seams. [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] [VERIFIED: `lib/relyra/diagnostic.ex`] |
| Reviewer-visible admin risk surfacing | Frontend Server (SSR) | API / Backend | LiveView renders risk flags and metadata-health/risk panels, but the underlying risk state is computed by query and metadata layers. [VERIFIED: `lib/relyra/live_admin/query.ex`] [VERIFIED: `test/relyra/live_admin/connection_metadata_live_test.exs`] |
| Findings remediation workflow | API / Backend | Database / Storage | High/Critical fixes should land as code plus regression coverage and be tracked in a repo ledger, not in an external spreadsheet alone. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] [VERIFIED: `CONFORMANCE.md`] [ASSUMED] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit [VERIFIED: `mix.exs`] | Elixir 1.19.5 built-in [VERIFIED: `elixir --version`] | Executable proof for strict defaults, escape hatches, and regressions. [VERIFIED: `test/security/signature_policy_test.exs`] [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] | The repo already uses ExUnit-tagged lanes for conformance, security corpus, verification, and integration checks. [VERIFIED: `mix.exs`] |
| Mix tasks [VERIFIED: `mix.exs`] | Mix 1.19.5 [VERIFIED: `mix --version`] | Generate and drift-check reviewer-facing artifacts. [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] | `mix relyra.conformance --check` already proves generated-doc drift enforcement is a first-class repo pattern. [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] [VERIFIED: command `mix relyra.conformance --check`] |
| `Relyra.Ecto.AuditWriter` [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] | Repo-local module [VERIFIED: codebase] | Canonical attribution and redaction normalization for trust mutations and operator-intent events. [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] | Reusing the single audit seam avoids divergent reviewer exports and redaction rules. [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] |
| `Relyra.Diagnostic` + `Diagnostic.AllowList` [VERIFIED: `lib/relyra/diagnostic.ex`] | Repo-local module [VERIFIED: codebase] | Generate redacted evidence bundles for auditors without leaking secrets or raw XML. [VERIFIED: `lib/relyra/diagnostic.ex`] [VERIFIED: `test/relyra/diagnostic_test.exs`] | The diagnostic bundle already exports curated JSON files and hashes correlation IDs in audit logs. [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix LiveView [VERIFIED: `mix.lock`] | 1.1.30 [VERIFIED: `mix.lock`] | Reviewer-visible risk and override surfacing on the optional admin boundary. [VERIFIED: `lib/relyra/live_admin/query.ex`] | Use only to prove library-owned risk presentation and scope enforcement, not to audit generic UX polish. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] |
| Ecto / Ecto SQL [VERIFIED: `mix.lock`] | 3.13.5 / 3.13.5 [VERIFIED: `mix.lock`] | Persisted audit rows, metadata source state, and repo-backed verification tests. [VERIFIED: `lib/relyra/ecto/metadata_source.ex`] [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] | Use for repo-backed proof and findings reproduction where runtime state matters. [VERIFIED: codebase] |
| Sobelow [VERIFIED: `mix.lock`] | 0.14.1 [VERIFIED: `mix.lock`] | Static Phoenix-focused security scanning inside the existing security lane. [VERIFIED: `mix.exs`] | Use as one audit packet rerun command, but do not present it as a substitute for trust-boundary tests. [VERIFIED: `mix.exs`] [ASSUMED] |
| `mix_audit` / `hex.audit` [VERIFIED: `mix.lock`] | 2.1.5 / Hex built-in [VERIFIED: `mix.lock`] | Dependency vulnerability evidence in the existing security lane. [VERIFIED: `mix.exs`] | Use for third-party component review and findings disposition support. [VERIFIED: `mix.exs`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One repo-native audit packet [VERIFIED: Phase 26 D-01..D-04] | Separate docs site or slide deck [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] | Rejected because a second truth surface drifts away from code, tests, and generated evidence. [VERIFIED: Phase 26 D-03] |
| Generated evidence artifact [VERIFIED: Phase 26 D-10..D-14] | Hand-maintained security status prose [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] | Rejected because the repo already enforces generated conformance drift checks and should reuse that pattern. [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] |
| Findings ledger in-repo [ASSUMED] | External spreadsheet only [ASSUMED] | Spreadsheet-only tracking breaks traceability between finding, fix, regression test, and release disposition. [ASSUMED] |

**Installation:**
```bash
# No new Hex packages are required by the recommended Phase 26 shape.
mix deps.get
```
[VERIFIED: `mix.exs`]

**Version verification:** Elixir 1.19.5, OTP 28, Mix 1.19.5, OpenSSL 3.6.2, PostgreSQL client 14.17, and a local PostgreSQL server on `/tmp:5432` are available in this environment. [VERIFIED: `elixir --version`] [VERIFIED: `mix --version`] [VERIFIED: `openssl version`] [VERIFIED: `psql --version`] [VERIFIED: `pg_isready`]

## Architecture Patterns

### System Architecture Diagram

```text
Reviewer opens canonical audit packet entry doc
        |
        v
Scope + assumptions + trust-boundary map
  - what Relyra owns
  - what host apps own
        |
        +------------------------------+
        |                              |
        v                              v
Executable rerun commands        Named code seams
  mix ci.security                  algorithm policy
  mix ci.verify                    validation pipeline
  mix relyra.conformance --check   metadata auto-refresh
  targeted strict-default tests    audit writer / diagnostic bundle
        |                              |
        +---------------+--------------+
                        |
                        v
Generated evidence artifact(s)
  - conformance drift proof
  - strict-default / escape-hatch matrix
  - redaction-safe bundle example or rerun instructions
                        |
                        v
Findings ledger
  - severity
  - exploit path
  - disposition
  - regression link
  - release blocker?
```
[VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] [VERIFIED: `mix.exs`] [ASSUMED]

### Recommended Project Structure
```text
docs/
├── security_review/
│   ├── README.md                 # Canonical reviewer entry point
│   ├── BOUNDARIES.md             # Library-owned trust seams and explicit exclusions
│   ├── FINDINGS.md               # Severity/disposition ledger
│   └── GENERATED_EVIDENCE.md     # Executable-state-derived proof artifact

test/
├── security_review/              # Packet-generation and proof tests
└── security/                     # Existing strict-default and corpus lanes

lib/mix/tasks/
└── relyra.security_review.ex     # Generates/diff-checks reviewer artifacts
```
[ASSUMED]

### Pattern 1: Canonical Reviewer Entry Point
**What:** One entry document should map claims to scope, seam, rerun command, and artifact. [VERIFIED: Phase 26 D-01..D-04]  
**When to use:** For the initial external handoff and every follow-up remediation drop. [VERIFIED: Phase 26 D-19]  
**Example:**
```markdown
# Security Review Packet

## Scope
- In scope: XML parsing, signed-node selection, metadata trust anchors, replay protection.
- Out of scope: host application authz policies and custom ScopeProvider logic.

## Rerun
- `mix ci.security`
- `mix ci.verify`
- `mix relyra.conformance --check`
```
[VERIFIED: `mix.exs`] [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] [ASSUMED]

### Pattern 2: Generated Evidence, Not Hand-Maintained Status
**What:** Generate reviewer-facing proof from executable state the same way `CONFORMANCE.md` is generated today. [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`]  
**When to use:** For strict-default matrices, escape-hatch inventories, and any drift-sensitive security claim. [VERIFIED: Phase 26 D-10..D-14]  
**Example:**
```elixir
defmodule Mix.Tasks.Relyra.SecurityReview do
  use Mix.Task

  @shortdoc "Generate or drift-check security review artifacts"

  def run(_args) do
    Mix.Task.run("app.start")
    # Load manifest/test truth and render markdown artifacts.
  end
end
```
[CITED: https://hexdocs.pm/mix/Mix.Task.html] [ASSUMED]

### Pattern 3: Escape Hatches Must Be Time-Boxed and Attributable
**What:** Reviewer proof for unsafe compatibility should show expiry or allow-until semantics plus audit visibility. [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] [VERIFIED: `lib/relyra/metadata/auto_refresh.ex`]  
**When to use:** For legacy SHA-1 support and unsigned metadata compatibility windows. [VERIFIED: `.planning/PROJECT.md`]  
**Example:**
```elixir
override = %{
  reason: "Legacy IdP migration window",
  expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
}

policy = %{AlgorithmPolicy.default() | legacy_sha1: override}
assert :ok = AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)
```
Source: [test/security/signature_policy_test.exs](/Users/jon/projects/relyra/test/security/signature_policy_test.exs). [VERIFIED: `test/security/signature_policy_test.exs`]

### Pattern 4: Redaction-Safe Evidence Export
**What:** Reuse allow-list exports and bounded summaries instead of exposing raw XML, PEM, RelayState, or operator identity in reviewer artifacts. [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] [VERIFIED: `lib/relyra/diagnostic.ex`]  
**When to use:** For sample evidence bundles, audit excerpts, and findings attachments. [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`]  
**Example:**
```elixir
assert event.before_summary.xml == "[REDACTED]"
assert event.after_summary.certificate_pem == "[REDACTED]"
assert event.diff_summary.context.metadata.pem == "[REDACTED]"
```
Source: [test/relyra/ecto/audit_hardening_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/audit_hardening_test.exs). [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`]

### Anti-Patterns to Avoid
- **README-first audit packet:** This phase is explicitly not general onboarding polish, so spreading review claims across `README.md` and ad hoc docs violates the locked phase boundary. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`]
- **Prose-only strict-default claims:** The repo already has executable tests for algorithm policy and audit hardening; not wiring them into the packet wastes existing proof. [VERIFIED: `test/security/signature_policy_test.exs`] [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`]
- **Second redaction path for auditors:** Duplicating `AuditWriter` or `Diagnostic.AllowList` logic risks reviewer packets leaking data the runtime path already learned to suppress. [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`]
- **Auditing host-app authz as if Relyra owns it:** `PROJECT.md` explicitly scopes generic auth/session systems and app policy out of core ownership. [VERIFIED: `.planning/PROJECT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reviewer evidence generation | Manual markdown snapshots [ASSUMED] | Mix-task-driven generated artifacts patterned after `CONFORMANCE.md` [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] | Drift-checkable artifacts are already a proven repo convention. [VERIFIED: command `mix relyra.conformance --check`] |
| Audit export redaction | New ad hoc serializer [ASSUMED] | `Relyra.Ecto.AuditWriter` and `Relyra.Diagnostic.AllowList` [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] [VERIFIED: `lib/relyra/diagnostic.ex`] | The existing seams already redact XML, PEM, RelayState, secrets, actor, and correlation IDs appropriately for evidence export. [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`] |
| Escape-hatch inventory | Narrative checklist only [ASSUMED] | Generated matrix from algorithm policy, metadata sources, and admin risk flags [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] [VERIFIED: `lib/relyra/live_admin/query.ex`] [VERIFIED: `lib/relyra/ecto/metadata_source.ex`] | Reviewers need exact override state and expiry semantics, not vague prose. [VERIFIED: Phase 26 D-13] |
| Findings tracking | External spreadsheet as sole source [ASSUMED] | In-repo findings ledger linked to tests and artifacts [ASSUMED] | The repo-native path keeps severity, fix, regression, and release disposition diffable alongside code. [ASSUMED] |

**Key insight:** Phase 26 should reuse the repo’s proven pattern of "generated artifact + rerun command + narrow seam documentation" rather than creating a new security-review delivery style. [VERIFIED: `CONFORMANCE.md`] [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] [VERIFIED: `.planning/phases/25-conformance-and-cve-regression-fixtures/25-RESEARCH.md`]

## Common Pitfalls

### Pitfall 1: Duplicate truth surfaces for security claims
**What goes wrong:** Reviewers see different answers in `README.md`, packet docs, and generated artifacts. [ASSUMED]  
**Why it happens:** Security work is documented in multiple places without a canonical entry point. [ASSUMED]  
**How to avoid:** Keep `README.md` limited to pointer links and drive substantive claims from one packet entry doc plus generated artifacts. [VERIFIED: Phase 26 D-02..D-04]  
**Warning signs:** A strict-default claim appears in prose but has no named rerun command or artifact. [ASSUMED]

### Pitfall 2: Treating escape hatches as config instead of security exceptions
**What goes wrong:** Legacy SHA-1 or unsigned metadata modes look like normal options rather than time-boxed risk acceptances. [VERIFIED: `.planning/PROJECT.md`]  
**Why it happens:** The code paths already exist and can be mistaken for routine compatibility behavior. [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] [VERIFIED: `lib/relyra/metadata/auto_refresh.ex`]  
**How to avoid:** Generate an override inventory that includes expiry/allow-until, reason, and audit visibility, and surface the same semantics in admin/boundary docs. [VERIFIED: `lib/relyra/live_admin/query.ex`] [VERIFIED: `test/relyra/live_admin/connection_metadata_live_test.exs`] [ASSUMED]  
**Warning signs:** Reviewer-facing docs say "supported for legacy IdPs" without an expiry field or attribution story. [ASSUMED]

### Pitfall 3: Leaking sensitive material in evidence exports
**What goes wrong:** Audit packets include raw assertions, PEM blocks, RelayState, or operator identity. [ASSUMED]  
**Why it happens:** Evidence export paths bypass the existing allow-list and redaction seams. [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] [VERIFIED: `lib/relyra/diagnostic.ex`]  
**How to avoid:** Route exported evidence through bounded summaries and allow-listed bundle files only. [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`]  
**Warning signs:** Reviewer artifacts contain XML tags, PEM headers, unhashed correlation IDs, or actor emails. [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`] [ASSUMED]

### Pitfall 4: Auditing the wrong boundary
**What goes wrong:** The review spends time on host-router policy or custom scope-provider code that Relyra does not own. [VERIFIED: `.planning/PROJECT.md`]  
**Why it happens:** The library ships Phoenix and LiveView helpers, so reviewers may blur library contracts with host-app implementation. [VERIFIED: `lib/relyra/live_admin/query.ex`] [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`]  
**How to avoid:** Put explicit in-scope/out-of-scope language in the packet boundary doc and map each claim to a library-owned seam. [VERIFIED: Phase 26 D-15..D-18] [ASSUMED]  
**Warning signs:** Findings cite generic host authz or unrelated UI polish without touching a Relyra seam. [ASSUMED]

### Pitfall 5: Parallelizing repo-backed verification lanes that bootstrap migrations
**What goes wrong:** DB-backed verification can fail with schema-migration collisions even when the underlying tests are valid. [VERIFIED: current session command output for parallel `mix test` run]  
**Why it happens:** `MigrationCase.bootstrap!/0` creates migration state, and concurrent test processes can collide on `schema_migrations`. [VERIFIED: current session command output for `duplicate key ... schema_migrations`]  
**How to avoid:** Keep repo-backed packet verification commands serialized, or document that packet reruns should not invoke migration-bootstrapping tests in parallel. [VERIFIED: current session command output] [ASSUMED]  
**Warning signs:** Postgrex `unique_violation` on `pg_type_typname_nsp_index` or `schema_migrations` during otherwise-targeted verification. [VERIFIED: current session command output]

## Code Examples

Verified patterns from the current repo:

### Strict-default SHA-1 rejection and time-boxed override
```elixir
test "default policy rejects sha1 methods with deprecated_algorithm" do
  policy = AlgorithmPolicy.default()

  assert %Error{type: :deprecated_algorithm} =
           AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)
end
```
Source: [test/security/signature_policy_test.exs](/Users/jon/projects/relyra/test/security/signature_policy_test.exs). [VERIFIED: `test/security/signature_policy_test.exs`] [VERIFIED: command `mix test test/security/signature_policy_test.exs --warnings-as-errors`]

### Redaction-safe audit proof
```elixir
assert event.before_summary.xml == "[REDACTED]"
assert event.after_summary.certificate_pem == "[REDACTED]"
assert event.diff_summary.context.metadata.pem == "[REDACTED]"
```
Source: [test/relyra/ecto/audit_hardening_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/audit_hardening_test.exs). [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] [VERIFIED: command `mix test test/relyra/ecto/audit_hardening_test.exs --warnings-as-errors`]

### Generated conformance drift check
```elixir
if Keyword.get(opts, :check, false) do
  check_report!(output_path, contents)
else
  File.write!(output_path, contents)
end
```
Source: [lib/mix/tasks/relyra.conformance.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.conformance.ex). [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] [VERIFIED: command `mix relyra.conformance --check`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual security status prose [ASSUMED] | Generated, drift-checkable conformance evidence [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] | Phase 25 completed on 2026-05-07. [VERIFIED: `.planning/ROADMAP.md`] | Phase 26 should extend this pattern for audit proof instead of regressing to narrative-only status docs. [VERIFIED: Phase 26 D-14] |
| Broad README as primary reviewer surface [ASSUMED] | Narrow packet plus targeted README pointers [VERIFIED: Phase 26 D-01..D-04] | Locked in Phase 26 context on 2026-05-08. [VERIFIED: `26-CONTEXT.md`] | Keeps audit prep inside scope and avoids Phase 27 onboarding work. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] |
| Security findings tracked outside code [ASSUMED] | Findings ledger linked to fix, regression, and disposition in-repo [ASSUMED] | Recommended for Phase 26. [ASSUMED] | Makes release-blocking severity decisions reviewable and diffable. [VERIFIED: Phase 26 D-05..D-09] [ASSUMED] |

**Deprecated/outdated:**
- README-only audit prep as the canonical security review surface is outdated for this repo because generated executable evidence already exists and Phase 26 explicitly forbids broad README expansion. [VERIFIED: `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md`] [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The canonical reviewer entry file should be named something like `docs/security_review/README.md` or `SECURITY_REVIEW.md`; the exact path is not locked. [ASSUMED] | Architecture Patterns | Low; file naming can change without changing the packet model. |
| A2 | Findings should be tracked in a repo-native markdown ledger rather than only in an external spreadsheet or ticketing tool. [ASSUMED] | Summary / Don't Hand-Roll / State of the Art | Medium; if the audit vendor requires another system, the repo will still need a mirrored source of truth. |
| A3 | A dedicated `mix relyra.security_review` task is the cleanest generation entry point for Phase 26 artifacts. [ASSUMED] | Architecture Patterns | Low; the repo could fold this into existing aliases or another task name. |

## Open Questions (RESOLVED)

1. **What exact file format should Phase 26 use for findings exchange?**
   - Decision: `docs/security_findings.md` is the canonical findings/disposition artifact for Phase 26, and no CSV, SARIF, issue-sync, or portal-export work is planned unless an external reviewer later requires it. [RESOLVED]
   - Why: This satisfies D-01, D-03, and D-05 through D-07 by keeping severity, ownership, disposition, and regression linkage in-repo and diffable next to code and tests. [VERIFIED: Phase 26 D-01..D-07]

2. **Should the packet include a committed sample diagnostic bundle or only rerun instructions?**
   - Decision: Phase 26 should not commit a sample diagnostic ZIP or unpacked bundle; it should link to rerun instructions plus the existing redaction-proof tests and named diagnostic seams. [RESOLVED]
   - Why: `Relyra.Diagnostic.create_bundle/1` and its tests already prove the bundle/redaction contract, while checking in bundle payloads would create churn and a second evidence surface. [VERIFIED: `lib/relyra/diagnostic.ex`] [VERIFIED: `test/relyra/diagnostic_test.exs`] [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`]

3. **How broad should the optional Phoenix/admin review surface be?**
   - Decision: The admin/Phoenix review surface is limited to library-owned seams only: routes/controllers the library defines, LiveView mount boundaries, scope enforcement, and risk/override surfacing already owned by Relyra. Host-app authn/authz, router policy, and custom scope-provider behavior remain out of scope. [RESOLVED]
   - Why: This is the narrowest scope consistent with D-15 through D-18 and keeps reviewer effort on exploit paths Relyra actually controls. [VERIFIED: Phase 26 D-15..D-18] [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `lib/relyra/live_admin/query.ex`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks and ExUnit evidence lanes [VERIFIED: `mix.exs`] | ✓ [VERIFIED: `command -v elixir`] | 1.19.5 [VERIFIED: `elixir --version`] | None |
| Erlang/OTP | Runtime and test execution [VERIFIED: `elixir --version`] | ✓ [VERIFIED: `elixir --version`] | 28 [VERIFIED: `elixir --version`] | None |
| Mix | Generated artifact and verification commands [VERIFIED: `mix.exs`] | ✓ [VERIFIED: `command -v mix`] | 1.19.5 [VERIFIED: `mix --version`] | None |
| PostgreSQL server | Repo-backed verification tests [VERIFIED: `test/support/migration_case.ex`] | ✓ [VERIFIED: `pg_isready`] | local server accepting on `/tmp:5432` [VERIFIED: `pg_isready`] | Pure unit tests only; repo-backed evidence would be blocked |
| OpenSSL | Certificate/fingerprint sanity checks during audit prep [VERIFIED: `README.md`] | ✓ [VERIFIED: `command -v openssl`] | 3.6.2 [VERIFIED: `openssl version`] | Erlang crypto for hashes; weaker reviewer ergonomics [ASSUMED] |
| Git | Diffable artifact workflow and release review [VERIFIED: project workflow] | ✓ [VERIFIED: `command -v git`] | 2.41.0 [VERIFIED: `git --version`] | None |

**Missing dependencies with no fallback:**
- None identified in this environment. [VERIFIED: current session tool probes]

**Missing dependencies with fallback:**
- None identified in this environment. [VERIFIED: current session tool probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 [VERIFIED: `mix.exs`] [VERIFIED: `elixir --version`] |
| Config file | No standalone `test_helper` config file was required by the research recommendations; the active contract is in `mix.exs` aliases and test modules. [VERIFIED: `mix.exs`] [ASSUMED] |
| Quick run command | `mix test test/security/signature_policy_test.exs --warnings-as-errors` [VERIFIED: command output] |
| Full suite command | `mix ci.security` [VERIFIED: `mix.exs`] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEC-REVIEW-01 | Strict defaults reject SHA-1 unless a time-boxed override is active. [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] | unit | `mix test test/security/signature_policy_test.exs --warnings-as-errors` | ✅ [VERIFIED: command output] |
| SEC-REVIEW-01 | Audit evidence remains attributable and redaction-safe across connection, metadata, certificate, and mapping domains. [VERIFIED: `test/relyra/ecto/audit_hardening_test.exs`] | integration | `mix test test/relyra/ecto/audit_hardening_test.exs --warnings-as-errors` | ✅ [VERIFIED: command output] |
| SEC-REVIEW-01 | Generated conformance evidence remains in sync with manifest truth. [VERIFIED: `lib/mix/tasks/relyra.conformance.ex`] | smoke | `mix relyra.conformance --check` | ✅ [VERIFIED: command output] |
| SEC-REVIEW-01 | Existing security and dependency lanes are rerunnable from one command. [VERIFIED: `mix.exs`] | integration | `mix ci.security` | ✅ command exists [VERIFIED: `mix.exs`] |

### Sampling Rate
- **Per task commit:** `mix test test/security/signature_policy_test.exs --warnings-as-errors` plus any directly touched packet-generation test. [VERIFIED: command output] [ASSUMED]
- **Per wave merge:** `mix test test/relyra/ecto/audit_hardening_test.exs --warnings-as-errors` and `mix relyra.conformance --check`. [VERIFIED: command output]
- **Phase gate:** `mix ci.security` and packet/artifact drift checks must pass before `/gsd-verify-work`. [VERIFIED: `mix.exs`] [ASSUMED]

### Wave 0 Gaps
- [ ] Add packet-generation tests for the Phase 26 reviewer entry artifact and any generated strict-default/escape-hatch evidence file. [ASSUMED]
- [ ] Add findings-ledger schema or format tests if the ledger is generated or machine-validated. [ASSUMED]
- [ ] Decide whether repo-backed Phase 26 verification commands should be serialized in docs to avoid `schema_migrations` bootstrap collisions when contributors parallelize them manually. [VERIFIED: current session command output]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [CITED: https://owasp.org/www-project-application-security-verification-standard/] | Signed-response/assertion validation, issuer/destination/audience/recipient checks, and typed login rejection paths in `ValidationPipeline` and related protocol code. [VERIFIED: `lib/relyra/protocol/validation_pipeline.ex`] |
| V3 Session Management | no for host sessions, yes for replay/request-intent safeguards [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `lib/relyra/replay_store.ex`] | Relyra owns replay/request intent semantics, but host applications own final session establishment policy. [VERIFIED: `.planning/PROJECT.md`] |
| V4 Access Control | yes [CITED: https://owasp.org/www-project-application-security-verification-standard/] | Library-owned admin scoping goes through `ScopeProvider`, `Scope`, and scoped queries rather than raw unscoped reads. [VERIFIED: `lib/relyra/live_admin/query.ex`] [VERIFIED: `test/phoenix/live_admin_test.exs`] |
| V5 Input Validation | yes [CITED: https://owasp.org/www-project-application-security-verification-standard/] | XML pre-parse guards, corpus gates, HTTPS metadata URL validation, trust-anchor checks, and protocol field validation are all explicit trust-boundary controls. [VERIFIED: `lib/relyra/security/xml/corpus_gate.ex`] [VERIFIED: `lib/relyra/ecto/metadata_source.ex`] [VERIFIED: `lib/relyra/metadata/trust_anchor.ex`] |
| V6 Cryptography | yes [CITED: https://owasp.org/www-project-application-security-verification-standard/] | SHA-256+-only default algorithm policy, configured-cert signature trust, and no document `KeyInfo` trust. [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] [VERIFIED: `.planning/PROJECT.md`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XXE / entity abuse at XML ingress [VERIFIED: `SECURITY.md`] | Information Disclosure / Tampering | DTDs and entities disabled before parse; corpus gate and parser reject known-bad shapes. [VERIFIED: `SECURITY.md`] [VERIFIED: `lib/relyra/security/xml/corpus_gate.ex`] |
| Signature wrapping / duplicate ID confusion [VERIFIED: `CONFORMANCE.md`] | Spoofing / Tampering | Consume only the verified signed node and keep regression fixtures pinned in the corpus. [VERIFIED: `CONFORMANCE.md`] [VERIFIED: `priv/security_corpus.json`] |
| Untrusted signature certificate / document `KeyInfo` trust [VERIFIED: `.planning/PROJECT.md`] | Spoofing | Verify against configured certificates or pinned metadata trust anchors only. [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `lib/relyra/metadata/trust_anchor.ex`] |
| Replay of assertions [VERIFIED: `lib/relyra/replay_store.ex`] | Replay / Spoofing | Require an atomic replay-store adapter and reject duplicate replay keys. [VERIFIED: `lib/relyra/replay_store/default.ex`] [VERIFIED: `lib/relyra/replay_store/ecto.ex`] [VERIFIED: `lib/relyra/replay_store/ets.ex`] |
| Sensitive logging / evidence leakage [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html] | Information Disclosure | Central redaction and allow-list export paths remove XML, PEM, RelayState, actor, and raw correlation IDs from reviewer evidence. [VERIFIED: `lib/relyra/ecto/audit_writer.ex`] [VERIFIED: `test/relyra/diagnostic/allow_list_test.exs`] |
| Unsafe compatibility drift [VERIFIED: `.planning/PROJECT.md`] | Tampering / Repudiation | Time-box legacy overrides, surface them in admin risk panels, and record operator-attributed audit events. [VERIFIED: `lib/relyra/security/algorithm_policy.ex`] [VERIFIED: `lib/relyra/live_admin/query.ex`] [VERIFIED: `test/relyra/live_admin/connection_metadata_live_test.exs`] |

## Sources

### Primary (HIGH confidence)
- Local repo code and planning artifacts listed in the user prompt. [VERIFIED: current session file reads]
- `mix.exs`, `mix.lock`, and targeted command execution for verification lanes. [VERIFIED: `mix.exs`] [VERIFIED: command outputs]
- `lib/mix/tasks/relyra.conformance.ex` and `CONFORMANCE.md` for generated-evidence precedent. [VERIFIED: file reads]
- `lib/relyra/security/algorithm_policy.ex`, `lib/relyra/metadata/auto_refresh.ex`, `lib/relyra/metadata/trust_anchor.ex`, `lib/relyra/ecto/audit_writer.ex`, `lib/relyra/diagnostic.ex`, and related tests. [VERIFIED: file reads]

### Secondary (MEDIUM confidence)
- OWASP ASVS project page for current 5.0.0 status and requirement-referencing guidance: https://owasp.org/www-project-application-security-verification-standard/ [CITED: https://owasp.org/www-project-application-security-verification-standard/]
- OWASP Logging Cheat Sheet for audit/evidence logging principles and data-exclusion guidance: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html]

### Tertiary (LOW confidence)
- None. [VERIFIED: no unverified web-only source was used]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended building blocks already exist in the repo and were verified by code reads plus command execution. [VERIFIED: current session]
- Architecture: HIGH - the packet shape is strongly constrained by locked Phase 26 decisions and existing Phase 25 evidence-generation patterns. [VERIFIED: `26-CONTEXT.md`] [VERIFIED: `25-RESEARCH.md`]
- Pitfalls: HIGH - they are grounded in local escape-hatch, audit, and verification seams, plus one directly observed repo-backed test collision. [VERIFIED: current session command output]

**Research date:** 2026-05-08 [VERIFIED: current session date]
**Valid until:** 2026-06-07 for repo-local architecture and 2026-05-15 for external standards/version snapshots. [ASSUMED]
