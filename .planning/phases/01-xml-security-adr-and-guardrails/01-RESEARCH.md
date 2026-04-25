# Phase 01 Research: XML Security ADR and Guardrails

## Scope of This Research

Phase 01 exists to lock the XML trust boundary before protocol code lands. Planning should treat this phase as a hard gate for downstream phases, not an exploratory spike. The phase must produce three concrete outcomes:

1. XML strategy ADR with explicit decision logic and fallback criteria.
2. Frozen `Relyra.Security.XML` seam contract and typed error shape.
3. Hardened parse baseline + adversarial seed corpus + CI gate contract.

Project-local planning constraints discovered:

- Canonical planning sources are in `.planning/*` and `.planning/research/*`.
- No repo-local `.cursor/rules/`, `.cursor/skills/`, or `.agents/skills/` directories currently exist, so there are no additional repository-specific rule overrides to account for.

---

## Recommended XML Strategy (GATE-01)

### Recommendation

Adopt **pure BEAM, single-parser trust path for v0.1**, behind a frozen seam, with a **pre-committed fallback trigger to hybrid/xmlsec** if acceptance gates fail.

### Why this is the best planning default

- Minimizes operational and supply-chain complexity in early lifecycle.
- Keeps behavior fully observable/debuggable in Elixir during phase 1-2 hardening.
- Preserves future swapability because the seam is frozen now.
- Aligns with current project decisions favoring least surprise and strict defaults.

### Strategy tradeoff summary

| Option | Security correctness confidence | Operational complexity | Supply-chain risk | Planning recommendation |
|---|---:|---:|---:|---|
| Pure BEAM | Medium (depends on corpus rigor) | Low | Low | **Default for Phase 01** |
| NIF over xmlsec | High (mature XMLDSig primitives) | High (cross-platform binaries + release process) | High | Not default in Phase 01 |
| Hybrid (BEAM + xmlsec verify path) | High | Medium/High | High | Pre-approve as fallback path |

### Decision rule to encode in ADR

Choose pure BEAM now **unless** any of these fail before phase close:

- Signed-node correctness cannot be demonstrated against adversarial corpus.
- Canonicalization acceptance threshold is not met.
- Deterministic typed rejection cannot be maintained for malicious classes.

If any fail, switch to hybrid/xmlsec **without changing seam API**.

### GATE-03 handling in this phase

Even if pure BEAM is selected, Phase 01 must still lock a conditional NIF policy so downstream work is not blocked later:

- Precompiled target matrix (if NIF selected): Linux GNU `x86_64/aarch64`, Linux musl `x86_64`, macOS `x86_64/aarch64`; Windows source-build best effort.
- Committed checksum manifest required.
- CI checksum verification required before release publish.

---

## Frozen Seam Contract: `Relyra.Security.XML`

Freeze this contract in Phase 01 and mark as downstream-invariant API for phases 2+.

### Behaviour surface

- `parse_safely/2`
- `select_signed_node/2`
- `canonicalize/2`

### Recommended contract shape (planning-level)

```elixir
@type xml_error_type ::
        :doctype_forbidden
        | :entity_expansion_forbidden
        | :external_reference_forbidden
        | :payload_too_large
        | :malformed_xml
        | :duplicate_xml_id
        | :missing_signature
        | :invalid_signature
        | :signature_wrapping_suspected
        | :canonicalization_failed
        | :untrusted_certificate
        | :unsigned_or_partial_signature

@type xml_error_details :: %{
        optional(:reason) => String.t(),
        optional(:expected) => term(),
        optional(:received) => term(),
        optional(:fixture_id) => String.t(),
        optional(:parser) => atom(),
        optional(:signed_node_id) => String.t()
      }

@callback parse_safely(binary(), keyword()) ::
  {:ok, parsed_doc :: term()} |
  {:error, %Relyra.Error{type: xml_error_type(), message: String.t(), details: xml_error_details()}}

@callback select_signed_node(parsed_doc :: term(), keyword()) ::
  {:ok, signed_node_handle :: term()} |
  {:error, %Relyra.Error{type: xml_error_type(), message: String.t(), details: xml_error_details()}}

@callback canonicalize(signed_node_handle :: term(), keyword()) ::
  {:ok, canonical_bytes :: binary()} |
  {:error, %Relyra.Error{type: xml_error_type(), message: String.t(), details: xml_error_details()}}
```

### Seam invariants to freeze

- Exactly one parser trust path for all trust decisions.
- No downstream code consumes raw XML for trust decisions.
- `select_signed_node/2` output is the only input allowed to canonicalization/verification path.
- Duplicate XML IDs are hard rejection.
- Typed error atoms are stable and deterministic for same input.
- `KeyInfo` is never a trust root source.
- No network/entity/DTD expansion at parse time.
- Size limits enforced before expensive parsing/canonicalization work.

---

## Adversarial Fixture Taxonomy and Minimum Corpus (SEC-01, GATE-02)

Phase 01 should define and seed a minimum adversarial corpus of **36 fixtures** (minimum), with explicit class coverage.

### Minimum taxonomy and counts

| Class | Min fixtures | Primary expected rejection atoms |
|---|---:|---|
| XXE / entity abuse | 6 | `:doctype_forbidden`, `:entity_expansion_forbidden`, `:external_reference_forbidden` |
| Decompression / size bounds | 4 | `:payload_too_large`, `:malformed_xml` |
| Signature wrapping variants | 8 | `:signature_wrapping_suspected`, `:invalid_signature` |
| Parser differential / canonicalization ambiguity | 6 | `:canonicalization_failed`, `:signature_wrapping_suspected` |
| Duplicate XML IDs | 4 | `:duplicate_xml_id` |
| KeyInfo misuse / trust confusion | 4 | `:untrusted_certificate`, `:invalid_signature` |
| Unsigned/partially signed structures | 4 | `:missing_signature`, `:unsigned_or_partial_signature` |

Total minimum: **36**

### Minimum corpus structure

```text
test/fixtures/security/xml/
  controls/
  xxe_entity_abuse/
  size_and_inflate_bounds/
  signature_wrapping/
  parser_differential_and_c14n/
  duplicate_ids/
  keyinfo_misuse/
  unsigned_or_partial_signature/
  manifest.json
```

`manifest.json` should include for each fixture:

- `id`
- `class`
- `requirement_ids` (must include `SEC-01` and/or `GATE-02`)
- `expected_error_type`
- `notes` (optional)

This keeps traceability machine-checkable.

---

## Validation Architecture

Phase 01 planning should define validation as layered gates, not one test bucket.

### Layer 1: Static trust-boundary enforcement

- No direct parser usage outside XML seam module.
- Single-parser-path rule enforced via static checks.
- Boundary checks prevent protocol code bypassing seam.

### Layer 2: Deterministic fixture rejection

- Every malicious fixture must reject with stable typed atom.
- Same fixture must produce same `Relyra.Error.type` across repeated runs.
- Typed errors are part of acceptance, not implementation detail.

### Layer 3: CI matrix gate

- Security and integration lanes must pass on OTP 27 and OTP 28.
- Phase cannot close on single-runtime success.

### Layer 4: Conditional NIF supply-chain gate (only if NIF/hybrid chosen)

- Target matrix build success.
- Checksum manifest committed and verified.
- Publish path blocked if parity/checksum validation fails.

---

## CI Acceptance Bar and Exact Commands (Phase Close Gate)

Phase 01 should be considered complete only when these pass (or are introduced and passing as part of the phase):

```bash
mix qa
mix ci.fast
mix ci.security
mix ci.integration
```

And explicit expanded checks (for non-alias environments):

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix compile --no-optional-deps --warnings-as-errors
mix credo --strict
mix test --warnings-as-errors
mix test --only security_corpus --warnings-as-errors
mix deps.audit
mix hex.audit
mix sobelow --config
```

Matrix requirement:

- Run the full gate set on **OTP 27** and **OTP 28**.

Conditional commands/checks if NIF/hybrid chosen:

- Verify checksum manifest in CI before publish.
- Verify target-matrix build success before publish.
- Verify release parity between source tag and published artifacts.

---

## Planning Structure for This Phase

Use three plans (already aligned with roadmap intent):

1. **ADR Decision Plan**  
   Lock strategy decision, fallback trigger, and conditional NIF policy.
2. **Seam Freeze Plan**  
   Freeze behaviour contract, error types, and trust invariants.
3. **Guardrail Plan**  
   Seed corpus, lock validation architecture, and enforce CI gate criteria.

This sequence keeps decision-first discipline and prevents protocol work from pre-committing architecture by accident.

---

## Requirement Traceability

| Requirement | Phase 01 output | Acceptance proof |
|---|---|---|
| `SEC-01` | Hardened single XML trust path + no DTD/entities/external fetch + size guards | Fixture classes `xxe_entity_abuse` and `size_and_inflate_bounds` pass rejection expectations; static seam-only parser enforcement |
| `GATE-01` | ADR selecting XML strategy (pure BEAM vs NIF vs hybrid) with rationale/tradeoffs | ADR document merged with explicit decision rule and fallback trigger |
| `GATE-02` | Canonicalization/security acceptance threshold and adversarial corpus definition | `manifest.json` + minimum 36-fixture corpus + deterministic typed rejection checks in CI |
| `GATE-03` | Conditional NIF target/checksum policy frozen (if NIF path selected, mandatory; if not, documented contingency policy) | ADR appendix section locking matrix and checksum verification policy; CI conditional gate definition |

---

## Key Risks to Address During Planning (Not Execution)

- Parser choice inside pure-BEAM path (`saxy` vs `sweet_xml`) must be explicit in ADR; do not defer.
- Canonicalization acceptance threshold must be numeric and binary (pass/fail), not subjective.
- Typed error atoms must be finalized now to avoid downstream churn.
- NIF policy must be documented now even if not selected, to avoid future gate ambiguity.
- Phase close criteria must require OTP 27+28 matrix success, not local-only green.

---

## Final Planning Recommendation

Plan Phase 01 as a **decision-and-guardrails gate**, not a coding phase:

- Default to **pure-BEAM single-parser strategy** now.
- Freeze `Relyra.Security.XML` seam and typed error contract.
- Seed and enforce **minimum 36-fixture adversarial corpus** with deterministic error behavior.
- Lock CI gate contract (`qa`, `ci.fast`, `ci.security`, `ci.integration`, OTP 27/28).
- Keep a pre-approved hybrid/xmlsec fallback path if acceptance thresholds are not met.

This gives downstream phases a stable trust boundary and prevents protocol work from encoding unreviewed XML security assumptions.
