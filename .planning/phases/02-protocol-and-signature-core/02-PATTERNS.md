# Phase 02 Pattern Map — Protocol and Signature Core

This map is derived from:
- `.planning/phases/02-protocol-and-signature-core/02-CONTEXT.md`
- `.planning/phases/02-protocol-and-signature-core/02-RESEARCH.md`

It captures concrete repo-local patterns to reuse while implementing the Phase 2 protocol/signature core.

---

## 1) Candidate Files List (Likely Create/Modify)

| Candidate path | Action | Why it is needed in Phase 2 | Closest analog(s) in current repo |
|---|---|---|---|
| `lib/relyra.ex` | Modify | Add public orchestration API `start_login/3` and `consume_response/3` with typed tuple outputs. | `lib/relyra.ex`, `lib/relyra/error.ex`, `lib/relyra/security/xml.ex` |
| `lib/relyra/protocol/authn_request.ex` | Create | Build deterministic SP-initiated AuthnRequest fields and IDs (PROT-01). | `lib/relyra/security/xml/pure_beam.ex` (input validation + tuple returns) |
| `lib/relyra/protocol/binding.ex` | Create | Centralize redirect/post binding encode/decode transforms. | `lib/relyra/security/xml/pure_beam.ex` |
| `lib/relyra/protocol/validation_pipeline.ex` | Create | Enforce locked validation order with short-circuit typed failures. | `test/security/xml/corpus_security_test.exs` (`with`-style staged flow) |
| `lib/relyra/protocol/response.ex` | Create | Response-level checks: issuer, status, destination, connection binding. | `lib/relyra/security/xml.ex` (behaviour contract boundaries) |
| `lib/relyra/protocol/assertion.ex` | Create | Assertion-level checks: audience, recipient, temporal windows. | `lib/relyra/security/xml/pure_beam.ex`, `lib/relyra/error.ex` |
| `lib/relyra/security/signature.ex` | Create | Verify signatures using configured certs only; no `KeyInfo` trust root. | `lib/relyra/security/xml.ex`, `lib/relyra/security/xml/pure_beam.ex` |
| `lib/relyra/security/signed_node.ex` | Create | Opaque verified signed-node handle to prevent wrapping consumption drift. | `lib/relyra/security/xml.ex` callback handle concept |
| `lib/relyra/security/algorithm_policy.ex` | Create | SHA-256+ defaults, SHA-1 rejection/override expiry logic (SEC-05). | `lib/relyra/security/xml/pure_beam.ex` (policy checks before parsing) |
| `lib/relyra/security/relay_state.ex` | Create | Opaque `rs_` RelayState format validation and rejection of raw URLs. | `lib/relyra/security/xml/pure_beam.ex` (strict precondition checks) |
| `test/protocol/authn_request_test.exs` | Create | Validate request shape and ID behavior for PROT-01. | `test/security/xml/seam_contract_test.exs`, `test/security/xml/error_atoms_test.exs` |
| `test/protocol/relay_state_test.exs` | Create | Validate opaque RelayState acceptance and raw URL rejection (SEC-07). | `test/security/xml/error_atoms_test.exs` |
| `test/security/signature_policy_test.exs` | Create | Validate trust-source and algorithm policy enforcement (SEC-02, SEC-05). | `test/security/xml/corpus_security_test.exs` |
| `test/security/signed_node_binding_test.exs` | Create | Validate signed-node binding, ambiguity rejection, duplicate-ID handling. | `test/security/xml/corpus_security_test.exs`, `test/security/xml/error_atoms_test.exs` |
| `test/protocol/consume_response_pipeline_test.exs` | Create | Validate strict stage ordering and typed output contracts (PROT-02/03/05). | `test/security/xml/corpus_security_test.exs` |
| `test/fixtures/security/signature/manifest.json` | Create | Manifest-driven signature adversarial corpus for SEC-02/03/04/05. | `test/fixtures/security/xml/manifest.json` |
| `test/fixtures/security/protocol/manifest.json` | Create | Protocol mismatch corpus for PROT-03/05 and deterministic error mapping. | `test/fixtures/security/xml/manifest.json` |
| `test/fixtures/security/relay_state/manifest.json` | Create | RelayState malformed/raw-url fixtures for SEC-07. | `test/fixtures/security/xml/manifest.json` |
| `test/fixtures/security/signature/*.xml` | Create | Wrapping, KeyInfo misuse, duplicate IDs, SHA-1 coverage fixtures. | `test/fixtures/security/xml/manifest.json` inline fixture pattern |
| `test/fixtures/security/protocol/*.xml` | Create | Issuer/audience/recipient/destination/status/time mismatch fixtures. | `test/fixtures/security/xml/manifest.json` inline fixture pattern |
| `test/fixtures/security/relay_state/*.json` | Create | RelayState token format/tamper cases. | `test/fixtures/security/xml/manifest.json` metadata pattern |

---

## 2) Analog Files List (Primary Reuse Sources)

1. `lib/relyra/error.ex`  
   Canonical typed error struct and constructor (`%Relyra.Error{type, message, details}`).

2. `lib/relyra/security/xml.ex`  
   Behaviour-level typed tuple contracts and stable XML/security error atom namespace.

3. `lib/relyra/security/xml/pure_beam.ex`  
   Strict precondition guard style, `Error.new/3` usage with details map, and short-circuiting.

4. `test/security/xml/corpus_security_test.exs`  
   Manifest-driven corpus tests, deterministic 3x rerun pattern, gate tags, staged evaluation.

5. `test/security/xml/error_atoms_test.exs`  
   Stable atom determinism pattern and compact repeatable assertions.

6. `test/security/xml/seam_contract_test.exs`  
   Contract-level tests for callback presence and tuple-shape assertions.

7. `test/fixtures/security/xml/manifest.json`  
   Fixture schema pattern (`id`, `class`, `requirement_ids`, `expected_error_type`, payload).

8. `mix.exs`  
   Existing CI/test lane tag conventions (`ci.fast`, `ci.security`, gate tags).

9. `lib/mix/tasks/compile/parser_path_guard.ex`  
   Security boundary enforcement pattern (reject dangerous usage outside seam).

---

## 3) Concrete Coding and Style Patterns to Reuse

### A) Typed tuple + `Relyra.Error` contract (core pattern)

```elixir
@callback parse_safely(binary(), keyword()) ::
            {:ok, term()} | {:error, %Error{}}
```

```elixir
@spec new(atom(), String.t(), map()) :: t()
def new(type, message, details \\ %{}) do
  %__MODULE__{type: type, message: message, details: details}
end
```

**Reuse rule:** Every Phase 2 public/internal protocol boundary should return only `{:ok, value}` or `{:error, %Relyra.Error{}}`; avoid alternate failure shapes.

### B) Strict fail-fast guards before deeper logic

```elixir
cond do
  byte_size(xml) > max_bytes ->
    {:error, Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{max_bytes: max_bytes})}

  String.contains?(xml, "<!DOCTYPE") ->
    {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

  true ->
    parse_xml(xml)
end
```

**Reuse rule:** Put irreversible rejections first (trust source, malformed structure, policy violations), then proceed to expensive checks.

### C) Pipeline staging via `with` for order and short-circuiting

```elixir
with {:ok, parsed_doc} <- PureBeam.parse_safely(xml, opts) do
  PureBeam.select_signed_node(parsed_doc, [])
end
```

**Reuse rule:** Use staged `with` in `ValidationPipeline.run/4` to encode fixed ordering and prevent bypassing prior trust artifacts.

### D) Test module style conventions

```elixir
defmodule Relyra.Security.XML.ErrorAtomsTest do
  use ExUnit.Case, async: true

  @tag :xml_errors
  test "malformed XML consistently maps to :malformed_xml" do
    # ...
  end
end
```

**Reuse rule:** Keep tests async where safe, use descriptive atom-focused test names, and tag suites for lane-selective execution.

### E) Determinism checks as explicit regression guard

```elixir
types =
  1..3
  |> Enum.map(fn _ ->
    assert {:error, %Error{type: type}} = evaluate_fixture(fixture)
    type
  end)

assert Enum.uniq(types) == [String.to_atom(fixture["expected_error_type"])]
```

**Reuse rule:** For each threat class, rerun the same fixture multiple times and assert stable atom output.

---

## 4) Error Tuple and Error Atom Patterns

### Tuple pattern

- **Success:** `{:ok, value}`
- **Failure:** `{:error, %Relyra.Error{type: atom(), message: String.t(), details: map()}}`
- **No alternatives:** no booleans, no `nil` success, no bare atoms, no leaked exceptions.

### Error struct pattern

- Always construct errors via `Relyra.Error.new/3`.
- `type` is stable and machine-branchable.
- `message` is human-readable and can evolve.
- `details` is a map containing actionable non-sensitive keys (expected/actual, stage, policy metadata).

### Atom naming conventions

- Snake_case atoms scoped to security/protocol domain.
- Existing baseline atoms in repo:
  - Parse/seam: `:doctype_forbidden`, `:entity_expansion_forbidden`, `:payload_too_large`, `:malformed_xml`, `:duplicate_xml_id`
  - Signature/seam placeholders: `:missing_signature`, `:invalid_signature`, `:signature_wrapping_suspected`, `:canonicalization_failed`, `:untrusted_certificate`
- Phase 2 additions should follow same style, e.g.:
  - Trust/signature: `:ambiguous_signed_node`, `:deprecated_algorithm`
  - Protocol: `:issuer_mismatch`, `:destination_mismatch`, `:invalid_audience`, `:recipient_mismatch`, `:unsupported_status`, `:connection_binding_mismatch`
  - Time: `:assertion_not_yet_valid`, `:assertion_expired`, `:subject_confirmation_expired`, `:clock_skew_exceeded`
  - RelayState: `:relay_state_rejected`

---

## 5) Test and Fixture Layout Patterns

### Existing layout to mirror

```text
test/security/xml/
  seam_contract_test.exs
  error_atoms_test.exs
  corpus_security_test.exs

test/fixtures/security/xml/manifest.json
```

### Manifest-driven fixture schema

```json
{
  "id": "sigwrap-001",
  "class": "signature_wrapping",
  "requirement_ids": ["GATE-02"],
  "expected_error_type": "missing_signature",
  "xml": "<response><assertion>unsigned</assertion></response>"
}
```

### Reusable testing conventions

- Use one manifest per fixture family and iterate all rows.
- Parse `expected_error_type` from string to atom in tests.
- Tag security corpora with lane-friendly tags (existing pattern: `:security_corpus`, `:gate02_c14n`).
- Keep deterministic test variants (3-run consistency) for each high-risk class.
- Separate unit-like validator tests from end-to-end pipeline ordering tests.

---

## 6) Anti-Patterns to Avoid (Phase 2 Critical)

1. **Parser or trust logic outside approved seam boundaries.**  
   The guard in `lib/mix/tasks/compile/parser_path_guard.ex` exists to prevent this drift.

2. **Trusting document `KeyInfo` as a root of trust.**  
   Only configured IdP certs from resolved connection context are valid trust sources.

3. **Re-selecting assertions from whole document after signature verification.**  
   Consume only the verified signed-node handle to avoid wrapping vulnerabilities.

4. **Bypassing the locked validation order.**  
   Do not scatter ad-hoc checks across modules; centralize order in a single pipeline entrypoint.

5. **Returning non-typed failures or raising through API boundaries.**  
   Wrap all failures into `%Relyra.Error{}` with stable `type` atoms.

6. **Using RelayState as raw redirect URL text.**  
   Enforce opaque `rs_` handle discipline and reject URL-like inputs by default.

7. **Branching caller logic on error message strings.**  
   Branch on `error.type`; treat messages as human-facing only.

8. **Embedding raw XML/assertion payloads in error details.**  
   Keep details actionable but non-sensitive.

---

## 7) Practical Reuse Guidance for Implementers

- Start by adapting `lib/relyra/security/xml/pure_beam.ex` fail-fast style into protocol/signature modules.
- Keep all new internal modules `@moduledoc false` unless the type/config is intentionally public.
- Use `test/security/xml/corpus_security_test.exs` as the blueprint for manifest-driven adversarial suites.
- Keep CI tag compatibility with existing lanes in `mix.exs`; add tags intentionally, not ad hoc.
- Preserve strict-by-default behavior and explicit override semantics only where research/context explicitly allows.
