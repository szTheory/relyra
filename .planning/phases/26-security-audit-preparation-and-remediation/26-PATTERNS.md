# Phase 26: Security Audit Preparation and Remediation - Pattern Map

**Mapped:** 2026-05-08
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `SECURITY_REVIEW.md` | config | transform | `CONFORMANCE.md` | role-match |
| `docs/security_boundary.md` | config | transform | `SECURITY.md` | role-match |
| `docs/security_findings.md` | config | transform | `CONFORMANCE.md` | role-match |
| `lib/mix/tasks/relyra.security_review.ex` | mix task | batch | `lib/mix/tasks/relyra.conformance.ex` | exact |
| `test/mix/tasks/relyra_security_review_test.exs` | test | batch | `test/mix/tasks/relyra_conformance_test.exs` | exact |
| `test/security/strict_default_proof_test.exs` | test | request-response | `test/security/signature_policy_test.exs` | exact |
| `test/relyra/ecto/escape_hatch_audit_test.exs` | test | event-driven | `test/relyra/ecto/audit_hardening_test.exs` | exact |
| `README.md` | config | transform | `README.md` | exact |
| `SECURITY.md` | config | transform | `SECURITY.md` | exact |
| `lib/relyra/security/algorithm_policy.ex` | service | request-response | `lib/relyra/security/algorithm_policy.ex` | exact |
| `lib/relyra/ecto/audit_writer.ex` | service | event-driven | `lib/relyra/ecto/audit_writer.ex` | exact |
| `lib/relyra/live_admin/query.ex` | service | request-response | `lib/relyra/live_admin/query.ex` | exact |

## Pattern Assignments

### `SECURITY_REVIEW.md` (config, transform)

**Analog:** `CONFORMANCE.md`

**Generated-doc header + provenance pattern** ([CONFORMANCE.md](/Users/jon/projects/relyra/CONFORMANCE.md:1)):
```markdown
# Conformance

Generated from executable manifest state in `priv/conformance/sp_manifest.json` and `priv/security_corpus.json`.
```

**Summary-first table pattern** ([CONFORMANCE.md](/Users/jon/projects/relyra/CONFORMANCE.md:5)):
```markdown
## Requirement Summary

| Requirement | pass | reject | unsupported | deferred | total |
| --- | --- | --- | --- | --- | --- |
| CONF-01 | 8 | 4 | 2 | 1 | 15 |
```

**Use for Phase 26:** Keep the reviewer entry doc generated from executable state, open with one provenance sentence, then use compact summary tables that link claims to proof lanes and rerun commands instead of hand-maintained prose.

---

### `docs/security_boundary.md` (config, transform)

**Analog:** `SECURITY.md`

**Threat-boundary framing** ([SECURITY.md](/Users/jon/projects/relyra/SECURITY.md:3)):
```markdown
## Threat model

Relyra sits on the SAML trust boundary. The library assumes the IdP is
untrusted input and treats all inbound XML, signatures, RelayState values,
and response metadata as potentially hostile.
```

**Non-negotiables list pattern** ([SECURITY.md](/Users/jon/projects/relyra/SECURITY.md:15)):
```markdown
## Non-negotiables

- DTDs and external entities stay disabled before parse.
- Signatures are verified against configured certificates only.
- Raw RelayState URLs are rejected.
- Replay protection is required.
- Raw assertions/responses must not be logged.
```

**Use for Phase 26:** Write the architecture-boundary doc as a narrow scope-and-assumptions document: in-scope trust seams, out-of-scope host-app seams, and fixed invariants in short bullets rather than narrative architecture prose.

---

### `docs/security_findings.md` (config, transform)

**Analog:** `CONFORMANCE.md`

**Ledger-table pattern** ([CONFORMANCE.md](/Users/jon/projects/relyra/CONFORMANCE.md:14)):
```markdown
| Scope | status | profile | rule | binding | provenance | notes |
| --- | --- | --- | --- | --- | --- | --- |
| sp-authn-request-build | pass | oasis-saml2-core | SAMLCore-3.4.1 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect | ... | ... |
```

**Compact evidence bullets** ([CONFORMANCE.md](/Users/jon/projects/relyra/CONFORMANCE.md:11)):
```markdown
- `CVE-REG-01` fixtures pinned: 7
- Families covered: xxe, signature_wrapping, CVE-2024-45409
```

**Use for Phase 26:** Model the findings ledger as a checked-in table with severity, disposition, owner, regression-proof link, and defer-rationale columns. Keep counts and status bullets above the ledger so auditors can scan outstanding risk quickly.

---

### `lib/mix/tasks/relyra.security_review.ex` (mix task, batch)

**Analog:** `lib/mix/tasks/relyra.conformance.ex`

**Task setup + option parsing** ([lib/mix/tasks/relyra.conformance.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.conformance.ex:11)):
```elixir
use Mix.Task

alias Relyra.ConformanceFixtures

@impl true
def run(args) do
  Mix.Task.run("app.start")

  {opts, _argv, invalid} =
    OptionParser.parse(args,
      strict: [output: :string, check: :boolean],
      aliases: [o: :output]
    )
```

**Write-vs-check branch** ([lib/mix/tasks/relyra.conformance.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.conformance.ex:33)):
```elixir
output_path = output_path(opts)
contents = render_report(load_report_rows())

if Keyword.get(opts, :check, false) do
  check_report!(output_path, contents)
else
  File.write!(output_path, contents)
  Mix.shell().info("relyra.conformance: wrote generated report to #{output_path}")
  :ok
end
```

**Drift-check error pattern** ([lib/mix/tasks/relyra.conformance.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.conformance.ex:58)):
```elixir
case File.read(output_path) do
  {:ok, existing} when existing == contents ->
    Mix.shell().info("relyra.conformance: #{output_path} matches generated manifest state")

  {:ok, _existing} ->
    Mix.raise("relyra.conformance drift detected for #{output_path}; rerun mix relyra.conformance")
```

**Supporting output-file pattern** ([lib/mix/tasks/relyra.diagnostic.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.diagnostic.ex:34)):
```elixir
case Relyra.Diagnostic.create_bundle(repo: repo) do
  {:ok, zip_binary} ->
    path = "./relyra_diagnostic_bundle.zip"
    File.write!(path, zip_binary)
```

**Use for Phase 26:** Keep one task that can generate the packet and optionally `--check` drift. If the task emits sidecar artifacts, keep the same explicit file-write + `Mix.shell().info/1` pattern.

---

### `test/mix/tasks/relyra_security_review_test.exs` (test, batch)

**Analog:** `test/mix/tasks/relyra_conformance_test.exs`

**Task reset pattern** ([test/mix/tasks/relyra_conformance_test.exs](/Users/jon/projects/relyra/test/mix/tasks/relyra_conformance_test.exs:1)):
```elixir
defmodule Mix.Tasks.Relyra.ConformanceTest do
  use ExUnit.Case, async: false

  @moduletag :conformance

  alias Mix.Tasks.Relyra.Conformance

  setup do
    Mix.Task.clear()
    :ok
  end
```

**Output assertions** ([test/mix/tasks/relyra_conformance_test.exs](/Users/jon/projects/relyra/test/mix/tasks/relyra_conformance_test.exs:12)):
```elixir
temp_output_path = temp_path!("CONFORMANCE.md")

Conformance.run(["--output", temp_output_path])

report = File.read!(temp_output_path)

assert report =~ "# Conformance"
assert report =~ "CONF-01"
assert report =~ "CVE-REG-01"
```

**Drift and missing-file checks** ([test/mix/tasks/relyra_conformance_test.exs](/Users/jon/projects/relyra/test/mix/tasks/relyra_conformance_test.exs:25)):
```elixir
assert_raise Mix.Error, ~r/--check.*missing|missing.*--check/i, fn ->
  Conformance.run(["--check", "--output", missing_output_path])
end

assert_raise Mix.Error, ~r/drift/i, fn ->
  Conformance.run(["--check", "--output", temp_output_path])
end
```

**Use for Phase 26:** Prove both generation and drift detection, and assert for Phase 26-specific markers like strict-default evidence, findings counts, and rerun command sections.

---

### `test/security/strict_default_proof_test.exs` (test, request-response)

**Analog:** `test/security/signature_policy_test.exs`

**Module shape + aliases** ([test/security/signature_policy_test.exs](/Users/jon/projects/relyra/test/security/signature_policy_test.exs:1)):
```elixir
defmodule Relyra.Security.SignaturePolicyTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.AlgorithmPolicy
```

**Fail-closed default test pattern** ([test/security/signature_policy_test.exs](/Users/jon/projects/relyra/test/security/signature_policy_test.exs:10)):
```elixir
test "default policy rejects sha1 methods with deprecated_algorithm" do
  policy = AlgorithmPolicy.default()

  assert %Error{type: :deprecated_algorithm} =
           AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)
```

**Explicit escape-hatch expiry proof** ([test/security/signature_policy_test.exs](/Users/jon/projects/relyra/test/security/signature_policy_test.exs:18)):
```elixir
override = %{
  reason: "Legacy IdP migration window",
  expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
}

policy = %{AlgorithmPolicy.default() | legacy_sha1: override}

assert :ok = AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)
```

**Supplemental integration describe style** ([test/relyra/metadata/auto_refresh_test.exs](/Users/jon/projects/relyra/test/relyra/metadata/auto_refresh_test.exs:1)):
```elixir
@moduledoc """
... The DESCRIBE-block names below ARE the contract ...
"""

describe "refresh/2 with require_signed_metadata: true and missing fingerprint trust anchor" do
  test "refuses with :trust_anchor_mismatch ..." do
```

**Use for Phase 26:** Keep strict-default proof mostly unit-fast, then add targeted describe blocks for trust-boundary rejections and time-boxed overrides when behavior spans more than one seam.

---

### `test/relyra/ecto/escape_hatch_audit_test.exs` (test, event-driven)

**Analog:** `test/relyra/ecto/audit_hardening_test.exs`

**Migration-backed ledger test shape** ([test/relyra/ecto/audit_hardening_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/audit_hardening_test.exs:1)):
```elixir
defmodule Relyra.Ecto.AuditHardeningTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{AuditEvent, AuditWriter, ...}
```

**Redaction + bounded-summary assertion pattern** ([test/relyra/ecto/audit_hardening_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/audit_hardening_test.exs:14)):
```elixir
assert {:ok, event} =
         AuditWriter.append_event(@repo, %{
           ...
           before_view: %{status: :draft, xml: "<xml>secret</xml>"},
           after_view: %{status: :enabled, certificate_pem: "..."},
           diff_summary: %{changed_fields: [:status, :pem]},
           metadata: %{pem: "..."}
         })

assert event.before_summary.xml == "[REDACTED]"
assert event.after_summary.certificate_pem == "[REDACTED]"
assert event.diff_summary.context.metadata.pem == "[REDACTED]"
```

**Attribution-required proof** ([test/relyra/ecto/audit_hardening_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/audit_hardening_test.exs:42)):
```elixir
assert {:error, %Relyra.Error{details: details}} =
         AuditWriter.append_event(@repo, %{...})

assert :actor in details.missing
assert :cause in details.missing
```

**Cross-domain reviewability pattern** ([test/relyra/ecto/audit_hardening_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/audit_hardening_test.exs:65)):
```elixir
assert Enum.all?(events, &reviewable_event?/1)
assert Enum.all?(events, &(present_text?(&1.actor) and present_text?(&1.cause)))
assert_redaction_safe!(events)
```

**Use for Phase 26:** Every escape hatch or bypass proof should assert four things together: explicit operator cause, correlation/reviewability, redaction safety, and a bounded lifetime or constrained scope.

---

### `README.md` (config, transform)

**Analog:** `README.md`

**Targeted section-link pattern** ([README.md](/Users/jon/projects/relyra/README.md:43)):
```markdown
## Guides

- [Getting Started](guides/getting_started.md)
- [Okta recipe](guides/recipes/okta.md)
- [Microsoft Entra ID recipe](guides/recipes/entra.md)
- [Google Workspace recipe](guides/recipes/google_workspace.md)
- [Security policy](SECURITY.md)
```

**Operations deep-link style** ([README.md](/Users/jon/projects/relyra/README.md:51)):
```markdown
## Operations: Bulk actions

Phase 20 ships a multi-select bulk-actions surface ...
```

**Use for Phase 26:** Keep README changes narrow: add one reviewer-facing link cluster that points to the canonical packet and boundary docs without turning README into the packet itself.

---

### `SECURITY.md` (config, transform)

**Analog:** `SECURITY.md`

**Algorithm policy statement** ([SECURITY.md](/Users/jon/projects/relyra/SECURITY.md:9)):
```markdown
## Supported algorithms

- SHA-256+ for signatures.
- SHA-256+ for digest methods.
- SHA-1 is rejected unless a time-boxed legacy override is explicitly configured.
```

**Release-gate checklist style** ([SECURITY.md](/Users/jon/projects/relyra/SECURITY.md:23)):
```markdown
## Release prerequisites

Before tagging or publishing a release:

- Confirm the public domain / namespace values still match ...
- Run the release parity lane (`mix ci.release`) before publish.
```

**Use for Phase 26:** Extend `SECURITY.md` with auditor-relevant guarantees and reviewer rerun hooks, but keep durable policy here and ephemeral evidence in generated packet files.

---

### `lib/relyra/security/algorithm_policy.ex` (service, request-response)

**Analog:** `lib/relyra/security/algorithm_policy.ex`

**Strict default struct pattern** ([lib/relyra/security/algorithm_policy.ex](/Users/jon/projects/relyra/lib/relyra/security/algorithm_policy.ex:16)):
```elixir
defstruct [:allowed_signature_methods, :allowed_digest_methods, :legacy_sha1]

@type legacy_sha1_override :: %{
  reason: String.t(),
  expires_at: DateTime.t()
}
```

**Fail-closed enforcement** ([lib/relyra/security/algorithm_policy.ex](/Users/jon/projects/relyra/lib/relyra/security/algorithm_policy.ex:74)):
```elixir
def enforce_signature_method(policy, method) do
  if method_allowed?(policy.allowed_signature_methods, method) do
    :ok
  else
    enforce_sha1_policy(policy.legacy_sha1, method, :signature_method, @sha1_signature_methods)
  end
end
```

**Time-boxed override expiry error** ([lib/relyra/security/algorithm_policy.ex](/Users/jon/projects/relyra/lib/relyra/security/algorithm_policy.ex:112)):
```elixir
case DateTime.compare(expires_at, DateTime.utc_now()) do
  :gt ->
    :ok

  _ ->
    Error.new(
      :legacy_algorithm_override_expired,
      "Legacy SHA-1 override has expired",
      %{algorithm: method, algorithm_type: method_type, reason: reason, expires_at: expires_at}
    )
end
```

**Use for Phase 26:** Any remediation in this area should preserve the current pattern: defaults encoded in code, overrides requiring structured reason + expiry, and typed refusal errors that tests and generated evidence can surface directly.

---

### `lib/relyra/ecto/audit_writer.ex` (service, event-driven)

**Analog:** `lib/relyra/ecto/audit_writer.ex`

**Entry-point + validation shape** ([lib/relyra/ecto/audit_writer.ex](/Users/jon/projects/relyra/lib/relyra/ecto/audit_writer.ex:30)):
```elixir
@spec append_event(module(), map()) :: {:ok, AuditEvent.t()} | {:error, Error.t()}
def append_event(repo, attrs) when is_atom(repo) and is_map(attrs) do
  with :ok <- ensure_optional_dependencies(repo),
       {:ok, normalized_attrs} <- normalize_attrs(attrs) do
    case %AuditEvent{} |> AuditEvent.changeset(normalized_attrs) |> repo.insert() do
```

**Required attribution pattern** ([lib/relyra/ecto/audit_writer.ex](/Users/jon/projects/relyra/lib/relyra/ecto/audit_writer.ex:114)):
```elixir
missing =
  Enum.filter(@required_attrs, fn key ->
    value = Map.get(attrs, key)
    is_nil(value) or value == ""
  end)
```

**Context merge + normalization pattern** ([lib/relyra/ecto/audit_writer.ex](/Users/jon/projects/relyra/lib/relyra/ecto/audit_writer.ex:133)):
```elixir
context =
  %{}
  |> maybe_put_context(:subject_ref, Map.get(attrs, :subject_ref))
  |> maybe_put_context(:metadata, Map.get(attrs, :metadata))
```

**Redaction and bounds pattern** ([lib/relyra/ecto/audit_writer.ex](/Users/jon/projects/relyra/lib/relyra/ecto/audit_writer.ex:175)):
```elixir
defp normalize_summary(value) when is_map(value) do
  value
  |> Enum.take(@max_map_entries)
  |> Enum.map(fn {key, nested_value} ->
    {normalize_key(key), normalize_value(key, nested_value)}
  end)
```

**Use for Phase 26:** If review findings require more escape-hatch attribution, add fields through this normalization path rather than ad hoc logging, and preserve the same redaction-first discipline.

---

### `lib/relyra/live_admin/query.ex` (service, request-response)

**Analog:** `lib/relyra/live_admin/query.ex`

**Admin detail aggregation pattern** ([lib/relyra/live_admin/query.ex](/Users/jon/projects/relyra/lib/relyra/live_admin/query.ex:56)):
```elixir
def get_connection_detail(repo, %Scope{} = scope, connection_id, audit_filters \\ %{}) do
  with :ok <- ensure_repo(repo, :get_connection_detail),
       {:ok, connection} <- fetch_connection(repo, scope, connection_id) do
    ...
    {:ok,
     %{
       connection: connection,
       metadata_source: metadata_source,
       metadata_revisions: metadata_revisions,
       mapping_revisions: mapping_revisions,
       audit_events: audit_events,
       risk_flags: risk_flags(connection)
     }}
```

**Derived health/risk summary pattern** ([lib/relyra/live_admin/query.ex](/Users/jon/projects/relyra/lib/relyra/live_admin/query.ex:185)):
```elixir
defp derive_auto_refresh_health(%MetadataSource{} = source, now) do
  cond do
    not is_nil(source.auto_suspended_until) and
        DateTime.compare(source.auto_suspended_until, now) == :gt ->
      :suspended

    (source.consecutive_failure_count || 0) >= 1 ->
      :degraded
```

**Structured operator-facing payload pattern** ([lib/relyra/live_admin/query.ex](/Users/jon/projects/relyra/lib/relyra/live_admin/query.ex:207)):
```elixir
defp build_auto_refresh_health_summary(%MetadataSource{} = source) do
  %{
    enabled?: source.auto_refresh_enabled || false,
    ...
    legacy_unsigned_metadata_policy: source.legacy_unsigned_metadata_policy,
    metadata_trust_fingerprints: source.metadata_trust_fingerprints || [],
    state: derive_auto_refresh_health(source, DateTime.utc_now())
  }
end
```

**Use for Phase 26:** Any audit-review surfacing in admin should stay derived and structured here, so the packet can point auditors to one query seam instead of scattered UI conditionals.

## Shared Patterns

### Generated Evidence
**Source:** [lib/mix/tasks/relyra.conformance.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.conformance.ex:19)
**Apply to:** `SECURITY_REVIEW.md`, `lib/mix/tasks/relyra.security_review.ex`, `test/mix/tasks/relyra_security_review_test.exs`
```elixir
def run(args) do
  Mix.Task.run("app.start")
  ...
  if Keyword.get(opts, :check, false) do
    check_report!(output_path, contents)
  else
    File.write!(output_path, contents)
```

### Strict Defaults And Escape Hatches
**Source:** [lib/relyra/security/algorithm_policy.ex](/Users/jon/projects/relyra/lib/relyra/security/algorithm_policy.ex:74), [lib/relyra/metadata/auto_refresh.ex](/Users/jon/projects/relyra/lib/relyra/metadata/auto_refresh.ex:125)
**Apply to:** strict-default proof docs/tests, security-boundary docs
```elixir
def enforce_signature_method(policy, method) do
  if method_allowed?(policy.allowed_signature_methods, method) do
    :ok
  else
    enforce_sha1_policy(policy.legacy_sha1, method, :signature_method, @sha1_signature_methods)
  end
end

defp verify_signature(xml, source, connection) do
  cond do
    legacy_unsigned_allowed?(source) -> {:ok, :legacy_unsigned}
    source.require_signed_metadata == true -> do_verify_signature(xml, source, connection)
    true -> {:ok, :legacy_unsigned}
  end
end
```

### Audit Attribution And Redaction
**Source:** [lib/relyra/ecto/audit_writer.ex](/Users/jon/projects/relyra/lib/relyra/ecto/audit_writer.ex:85)
**Apply to:** findings remediation proofs, bypass/override verification, admin risk surfacing docs
```elixir
{:ok,
 %{
   connection_record_id: Map.get(attrs, :connection_record_id),
   domain: Map.get(attrs, :domain),
   action: Map.get(attrs, :action),
   actor: normalize_required_string(attrs, :actor),
   cause: normalize_required_string(attrs, :cause),
   correlation_id: normalize_optional_string(Map.get(attrs, :correlation_id)),
   before_summary: before_summary,
   after_summary: after_summary,
   diff_summary: diff_summary
 }}
```

### Operator Risk Surfacing
**Source:** [lib/relyra/live_admin/query.ex](/Users/jon/projects/relyra/lib/relyra/live_admin/query.ex:96), [lib/relyra/live_admin/components/risk_panel.ex](/Users/jon/projects/relyra/lib/relyra/live_admin/components/risk_panel.ex:6)
**Apply to:** admin risk-surfacing seams, reviewer packet seam map
```elixir
%{
  ...
  risk_flags: risk_flags(connection),
  provider_label: provider_label(connection.provider_preset)
}
```

```elixir
<div :for={risk <- @risk_flags} ...>
  <strong>{risk.label}</strong>
  <pre ...>{Jason.encode!(risk.details, pretty: true)}</pre>
</div>
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `docs/security_boundary.md` | config | transform | No existing dedicated architecture-boundary doc exists; use `SECURITY.md` for scope/non-negotiables and keep the new doc narrow. |
| `docs/security_findings.md` | config | transform | No existing checked-in findings ledger exists; use `CONFORMANCE.md` table density and generated-doc posture. |

## Metadata

**Analog search scope:** `README.md`, `SECURITY.md`, `CONFORMANCE.md`, `lib/mix/tasks/**/*.ex`, `lib/relyra/{security,ecto,metadata,live_admin}/**/*.ex`, `test/{mix/tasks,security,relyra}/**/*`
**Files scanned:** 20+
**Pattern extraction date:** 2026-05-08
