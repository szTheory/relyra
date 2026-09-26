 Phase 77: Code and Documentation Craftsmanship - Pattern Map

**Mapped:** 2026-09-26  
**Files analyzed:** 10 likely touch points  
**Analogs found:** 10 / 10 (one conditional fixture item)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| lib/relyra/security/signature.ex | security module | request-response | same module, verify_metadata_root/4 and do_verify/4 | exact |
| test/security/xml/adversarial_crypto_test.exs | test | transform / request-response | same permanent adversarial corpus | exact |
| guides/getting_started.md | adopter documentation | request-response | test/docs/demo_guide_drift_test.exs guide assertions | role-match |
| docs/jtbd_gap_map.md | maintainer documentation | transform | guides/jtbd_user_flows.md and its current coverage structure | role-match |
| test/docs/demo_guide_drift_test.exs | test | batch policy scan | same file's incomplete-phase checker | exact |
| .planning/phases/73-twin-contract-and-baseline/73-BASELINE.md | governance document | disposition ledger | test/governance/milestone_scope_test.exs | exact |
| test/governance/milestone_scope_test.exs | test | batch filesystem/Git evidence | same file's baseline and tracked-path validation | exact |
| docs/security_findings.md | security evidence document | transform | finding ledger and adversarial corpus | role-match |
| mix.exs | config | batch CI orchestration | ci.docs, ci.evidence, ci.security aliases | exact; only if needed |
| test/fixtures/demo_host/golden/config/relyra_snippet.exs | fixture | file I/O | test/adoption/journey_01_install_parity_test.exs | conditional |

All named analogs were verified with git ls-files. The golden snippet is tracked; three other historical warning paths are absent from the current tracked fixture inventory.

## Pattern Assignments

### lib/relyra/security/signature.ex (security module, request-response)

**Analog:** Same module's verify_metadata_root/4, delegated to shared do_verify/4.

**Security contract excerpt** (lib/relyra/security/signature.ex:49-65):

```elixir
@doc """
Verifies the XMLDSig signature on a SAML metadata root (EntityDescriptor
or EntitiesDescriptor) using the SAME do_verify/4 trust primitive
verify/4 uses. The only difference is the telemetry payload's flow
tag (:metadata_refresh instead of :sp_initiated) so adopters can
attach distinct handlers to the unattended metadata-refresh channel.

Phase 21 contract per D-16: this MUST be called BEFORE the candidate is
parsed deeply (no Parser.parse invocation between fetch and this call
on the scheduled path).

cert_chain MUST be the operator-pinned PEM list resolved from
MetadataSource.metadata_trust_fingerprints per D-17 — NEVER the IdP's
assertion certs.
"""
```

Rewrite historical labels as current caller contracts. Preserve verification-before-deep-parse ordering, shared primitive, telemetry behavior, and operator-pinned metadata trust source. Do not restructure crypto or parser paths.

### test/security/xml/adversarial_crypto_test.exs (test, transform / request-response)

**Analog:** The same file's permanent corpus and exact typed-result assertions.

**Corpus excerpt** (test/security/xml/adversarial_crypto_test.exs:78-102):

```elixir
describe "forged signature (ASSUR-01, T-30-06)" do
  test "same-length random-base64 SignatureValue → :invalid_signature" do
    signed = XmldsigSigner.signed_response()
    {:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])

    [candidate] = parsed_doc.signed_candidates
    {:ok, genuine_bytes} = Base.decode64(candidate.signature_value_b64)
    forged_b64 = Base.encode64(:crypto.strong_rand_bytes(byte_size(genuine_bytes)))
    parsed_doc = put_candidate(parsed_doc, :signature_value_b64, forged_b64)

    assert {:error, %Error{type: :invalid_signature}} =
             Signature.verify(parsed_doc, connection(), signed.cert_chain)
  end
end
```

Comments may be made timeless, but retain all attack categories, genuine positive control, exact error assertions, configured-certificate trust, and parse-to-verify path. Never weaken this corpus or its separate fresh-process ci.security gate.

### guides/getting_started.md (adopter guide, request-response)

**Analog:** test/docs/demo_guide_drift_test.exs assertions for user-facing guides.

**Existing boundary** (guides/getting_started.md:7-24):

```markdown
This page is the canonical Day-1 onboarding path. For the full doc map by job,
see the documentation overview.

Follow the sections in order:

1. Install
2. Scaffold
3. Prove local login with Relyra.Testing
4. Choose one provider runbook
5. Production follow-ons
```

Keep current adopter behavior, journey order, examples, and useful links. Move maintainer-only CI/GSD details out of this guide into repository governance or tests.

### docs/jtbd_gap_map.md (maintainer documentation, transform)

**Analog:** guides/jtbd_user_flows.md for adopter flows; retain the map's current coverage assessment structure.

**Current coverage excerpt** (docs/jtbd_gap_map.md:30-51):

```markdown
## Current coverage map

### Phoenix SaaS adopter

Status: Strong

What is clearly supported:
- install and scaffold into a Phoenix app
- prove the path locally with public Relyra.Testing fixtures

What is still rough:
- the generic SAML path is supported but not preset-backed
```

Refresh coverage, remaining gaps, and intentionally out-of-scope areas. Remove stale release-by-release history and dates. Keep maintainer ownership clear and direct adopter flow readers to the guide; the gap map is intentionally outside Hex docs.

### test/docs/demo_guide_drift_test.exs (test, batch policy scan)

**Analog:** Same module's active-incomplete-phase acceptance policy.

**Active scope and markers** (test/docs/demo_guide_drift_test.exs:901-946):

```elixir
roadmap
|> incomplete_phase_numbers()
|> Enum.flat_map(&automation_policy_violations/1)

defp automation_policy_violations(phase) do
  phase_dirs = Path.wildcard(".planning/phases/#{phase}-*")

  document_violations =
    for phase_dir <- phase_dirs,
        path <- Path.wildcard(Path.join(phase_dir, "*.md")),
        marker <- ["<human-check>", "## Manual-Only Verifications", "status: human_needed"],
        String.contains?(File.read!(path), marker),
        do: "#{path} contains #{inspect(marker)}"

  uat_violations =
    for phase_dir <- phase_dirs,
        path <- Path.wildcard(Path.join(phase_dir, "*-UAT.md")),
        do: "#{path} requires a UAT artifact"

  document_violations ++ uat_violations
end
```

Keep deterministic enforcement scoped to incomplete roadmap phases. Preserve intentional policy vocabulary in the checker. Do not blanket-exempt .planning/ or delete archives. Add a focused fixture only if live-tree evidence cannot demonstrate archived examples are outside scan scope.

### .planning/phases/73-twin-contract-and-baseline/73-BASELINE.md (governance ledger)

**Analog:** test/governance/milestone_scope_test.exs validates baseline severity, columns, non-empty fields, evidence references, and finding descriptions.

**Ledger shape** (.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md:7-18):

```markdown
## Severity and Disposition Policy

The only allowed severities are Critical, High, Medium, Low, and Informational.

## Findings Ledger

| Finding ID | Severity | Category | Finding | Reproducible Evidence | Disposition | Owner | Target Phase | Approval Class | Blocker State | Revisit Date |
```

Preserve the baseline as historical evidence while updating only planned dispositions. Validate each status against current tracked-tree/evidence observations and the established severity policy. Preserve Phase 74 and 79 ownership and critical-finding proof links.

### test/governance/milestone_scope_test.exs (test, batch / filesystem and Git evidence)

**Analog:** Same module's baseline contract and provenance tests.

**Baseline contract excerpt** (test/governance/milestone_scope_test.exs:1880-1929):

```elixir
test "dated baseline publishes the complete severity-ranked findings contract" do
  baseline = File.read!(@baseline_path)
  sections = baseline_sections(baseline)

  assert Map.keys(sections) |> MapSet.new() == MapSet.new([...])
  {columns, rows} = baseline_rows(baseline)
  assert columns == @finding_columns
  assert rows != []

  for row <- rows, column <- @finding_columns do
    assert String.trim(row[column]) != ""
  end
end
```

For tracked-artifact claims, use Git's index as tracked-path truth and reject missing, untracked, or symlink evidence. Existing provenance tests at lines 2275-2310 create temporary paths and clean them with on_exit; keep incidental user worktree state outside the policy.

### docs/security_findings.md (security evidence ledger, transform)

**Analog:** Its own finding row and regression-proof fields, plus the adversarial crypto test as proof owner.

**Critical closure row** (docs/security_findings.md:14-16):

```markdown
| Finding ID | Severity | Exploit Path | Disposition | Owner | Regression Proof | Blocker State | Revisit Date |
| RELYRA-2026-001 | Critical | forged SignatureValue accepted | Fixed in v1.1 | maintainers | adversarial corpus + ci_gate_integrity_test under ci.security | resolved | at release |
```

Carry forward closure references. Do not re-open the resolved security fix as implementation work; preserve the corpus and configured-certificate trust path.

### mix.exs (config, batch CI orchestration)

**Analog:** Existing aliases in the same file.

**Named lane excerpts** (mix.exs:211-239,243-269):

```elixir
"ci.docs": [
  "cmd mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors",
  ...
],
"ci.evidence": [
  "cmd mix test test/adoption/evidence_contract_test.exs test/adoption/external_canary_contract_test.exs test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors"
],
"ci.security": [
  # Security suites are each separate cmd mix test processes.
  "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
  "cmd mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors",
  ...
]
```

Use existing owners: ci.docs for docs/policy, ci.evidence for tracked paths and finding contracts, ci.security for crypto proof. Keep each security suite in its own fresh process; do not consolidate repeated test tasks.

### test/fixtures/demo_host/golden/config/relyra_snippet.exs (fixture, file I/O)

**Analog:** test/adoption/journey_01_install_parity_test.exs compares installer output against checked-in golden configuration.

The snippet is tracked; mix.exs:16 configures test_ignore_filters: [~r{^test/fixtures/}]. Three other historical warning paths are no longer tracked. Do not edit golden output or filters based on the old list. Obtain current deterministic warning output first; retain install parity and fixture coverage.

## Shared Patterns

### Finding ownership and evidence

**Source:** .planning/phases/73-twin-contract-and-baseline/73-BASELINE.md; validator test/governance/milestone_scope_test.exs.  
**Apply to:** dispositions, security proof references, tracked artifact decisions.

Revalidate ownership and evidence before disposition. Preserve baseline columns and controlled severity/blocker vocabulary. Keep Phase 74/78/79 work with its existing owner.

### Documentation ownership boundary

**Source:** guides/getting_started.md, docs/jtbd_gap_map.md, and test/docs/demo_guide_drift_test.exs.  
**Apply to:** adopter guides and maintainer documentation.

Adopter docs explain current supported behavior and user steps. Repository workflow and CI policy live in maintainer docs or governance tests. Historical planning records remain in .planning/.

### Deterministic policy checks

**Source:** test/docs/demo_guide_drift_test.exs:901-946; aliases in mix.exs:211-239.  
**Apply to:** documentation drift and incomplete-phase acceptance.

Extend the existing test and named CI owner. Broad text search discovers candidates; it is not proof of staleness or an acceptance oracle.

### Security seam preservation

**Source:** lib/relyra/security/signature.ex:49-80, test/security/xml/adversarial_crypto_test.exs, and mix.exs:243-269.  
**Apply to:** signature and metadata trust comments or characterization.

Preserve configured IdP/operator-pinned trust, one parsing path and sequencing, digest recomputation, real public-key verification, and all adversarial cases. Behavioral/security posture changes exceed this phase.

## No Analog Found

None for likely in-scope work. The golden-fixture warning item is conditional and requires current lane output before any change.

## Metadata

**Analog search scope:** security module, guides, docs, docs/security, test/docs, test/security/xml, test/governance, test/adoption, and Mix aliases.  
**Files scanned:** 10 primary files plus baseline, guide, and test excerpts.  
**Pattern extraction date:** 2026-09-26.

