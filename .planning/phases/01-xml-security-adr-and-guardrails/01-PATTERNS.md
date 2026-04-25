### Repository Reality (Phase 01)

This repository is currently **planning-first and code-greenfield**:

- Existing artifacts are concentrated in `.planning/` and `prompts/`.
- No `lib/`, `test/`, `.github/workflows/`, or `mix.exs` implementation baseline exists yet.
- For Phase 01, most analogs are **document-level conventions** rather than code-level reuse.

---

### 1) Anticipated Artifacts With Role Classification

| Anticipated path | Role classification | Closest analog reference(s) | Pattern confidence |
|---|---|---|---|
| `.planning/phases/01-xml-security-adr-and-guardrails/01-PATTERNS.md` | Phase planning support doc (pattern map) | `.planning/phases/01-xml-security-adr-and-guardrails/01-CONTEXT.md`, `01-RESEARCH.md`, `01-VALIDATION.md` | High |
| `.planning/phases/01-xml-security-adr-and-guardrails/01-01-PLAN.md` | Plan document (ADR decision plan) | `ROADMAP.md` plan indexing style (`01-01`, `01-02`, `01-03`) and `*-PLAN.md` convention from GSD workflow | Medium |
| `.planning/phases/01-xml-security-adr-and-guardrails/01-02-PLAN.md` | Plan document (seam freeze plan) | Same as above | Medium |
| `.planning/phases/01-xml-security-adr-and-guardrails/01-03-PLAN.md` | Plan document (guardrail plan) | Same as above | Medium |
| `.planning/phases/01-xml-security-adr-and-guardrails/01-ADR.md` (or equivalent ADR file in phase dir) | Architecture decision record (GATE-01/GATE-03) | ADR expectations in `01-RESEARCH.md`, `01-VALIDATION.md`, `ROADMAP.md` | Medium |
| `lib/relyra/security/xml.ex` | Core security seam behaviour (`parse_safely/2`, `select_signed_node/2`, `canonicalize/2`) | Contract prototype in `01-RESEARCH.md`; module tree in `.planning/research/ARCHITECTURE.md` | Medium (doc analog only) |
| `lib/relyra/error.ex` | Typed error contract module `%Relyra.Error{}` | Error shape in `01-RESEARCH.md`; requirement wording in `REQUIREMENTS.md` | Medium (doc analog only) |
| `lib/relyra/security/xml/*.ex` (adapter implementation(s)) | XML adapter implementation behind seam | Adapter naming in `.planning/research/ARCHITECTURE.md` (`Relyra.Security.XML.Sweet`, optional xmlsec path) | Low-Medium (doc analog only) |
| `test/security/xml/seam_contract_test.exs` | Contract/invariant tests for seam API | Explicit Wave 0 file target in `01-VALIDATION.md` | Medium (path analog only) |
| `test/security/xml/error_atoms_test.exs` | Deterministic typed error behavior tests | Explicit Wave 0 file target in `01-VALIDATION.md` | Medium (path analog only) |
| `test/security/xml/corpus_security_test.exs` | Security corpus gate tests | Explicit Wave 0 file target in `01-VALIDATION.md`; fixture policy in `.planning/research/PITFALLS.md` | Medium (path analog only) |
| `test/fixtures/security/xml/manifest.json` | Fixture metadata index and expected rejection mapping | Explicit Wave 0 file target in `01-VALIDATION.md`; schema fields in `01-RESEARCH.md` | Medium (path + schema analog) |
| `test/fixtures/security/xml/<taxonomy-classes>/...` | Adversarial fixture corpus directory | Taxonomy and directory shape in `01-RESEARCH.md` and `.planning/research/PITFALLS.md` | Medium (doc analog only) |
| `mix.exs` | Build, aliases, dependency/guardrail contract (`qa`, `ci.fast`, `ci.security`, `ci.integration`) | Suggested aliases in `01-RESEARCH.md` and `.planning/research/STACK.md` | Low-Medium (doc analog only) |
| `.github/workflows/*.yml` | CI gate enforcement, OTP matrix, conditional NIF checks | CI gate contract in `01-RESEARCH.md`, `01-CONTEXT.md`, `.planning/research/PITFALLS.md` | Low (no repo-local workflow analog) |

---

### 2) Recommended Analog References (Planner Read-First)

Use these as the primary pattern anchors when authoring executable plan tasks:

1. `.planning/phases/01-xml-security-adr-and-guardrails/01-VALIDATION.md`  
   Best source for concrete Phase 01 file targets, test lane names, and verification command shape.
2. `.planning/phases/01-xml-security-adr-and-guardrails/01-RESEARCH.md`  
   Best source for seam signatures, error taxonomy draft, fixture taxonomy/counts, and acceptance gate language.
3. `.planning/research/ARCHITECTURE.md`  
   Best source for module naming, namespace layout, and expected placement of `Relyra.Security.XML`.
4. `.planning/research/PITFALLS.md`  
   Best source for static-guardrail patterns and permanent security fixture discipline.
5. `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md`  
   Best source for plan numbering, requirement-to-phase mapping, and success-criteria framing.

---

### 3) Concrete Snippet-Level Conventions Already Present

These are the strongest reusable conventions currently available in-repo.

#### A) Phase artifact naming and placement

```text
.planning/phases/<NN>-<slug>/<NN>-CONTEXT.md
.planning/phases/<NN>-<slug>/<NN>-RESEARCH.md
.planning/phases/<NN>-<slug>/<NN>-VALIDATION.md
.planning/phases/<NN>-<slug>/<NN>-PATTERNS.md
```

#### B) XML seam callback shape (planning-level contract)

```elixir
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

#### C) Fixture corpus directory convention

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

#### D) Manifest field convention

```json
{
  "id": "fixture-id",
  "class": "xxe_entity_abuse",
  "requirement_ids": ["SEC-01", "GATE-02"],
  "expected_error_type": "doctype_forbidden",
  "notes": "optional"
}
```

#### E) Validation command convention

```bash
mix qa
mix ci.fast
mix ci.security
mix ci.integration
```

#### F) Wave-0 test file naming convention

```text
test/security/xml/seam_contract_test.exs
test/security/xml/error_atoms_test.exs
test/security/xml/corpus_security_test.exs
test/fixtures/security/xml/manifest.json
```

---

### 4) No-Analog-Found (Greenfield) Entries

These should be treated as **new contracts to establish in Phase 01**, not refactors.

| Target area | No analog found status | Planning implication |
|---|---|---|
| `lib/` module implementation style in this repo | No repo-local code analog found | Tasks must include full module skeletons, specs, and naming in `<action>`; do not assume inherited style from existing code |
| `test/` execution structure and helper conventions | No repo-local test analog found | Tasks must include test directory bootstrap and any required `test_helper.exs` assumptions |
| `.github/workflows/` CI layout | No repo-local workflow analog found | Tasks must define workflow filenames, triggers, matrix keys, and commands explicitly |
| `mix.exs` alias baseline | No repo-local `mix.exs` found | Tasks must include exact alias definitions required by Phase 01 gates |
| Existing ADR template file | No repo-local ADR template found | Planner should embed required ADR sections directly in task acceptance criteria |

---

### 5) Planner Recommendations for Executable Tasks (Mostly Greenfield Repo)

1. **Lead with bootstrap tasks before logic tasks.**  
   Sequence should begin with file/directory creation (`lib/`, `test/`, fixture tree, `mix.exs`) before seam or corpus logic.

2. **Use path-explicit actions, not intent-only actions.**  
   Good: "Create `lib/relyra/security/xml.ex` with behaviour callbacks `parse_safely/2`, `select_signed_node/2`, `canonicalize/2`."  
   Avoid: "Implement XML seam."

3. **Make every task acceptance grep/test-checkable.**  
   Include exact atoms, callback names, file paths, and commands in acceptance criteria so verification can run mechanically.

4. **Treat docs as source-of-truth until code exists.**  
   For Phase 01, `01-RESEARCH.md`, `01-VALIDATION.md`, and `.planning/research/ARCHITECTURE.md` are the primary "pattern library."

5. **Split plan waves by dependency, not by document type.**  
   Suggested dependency order: ADR decision lock -> seam/error contract skeleton -> fixture corpus + test gates -> CI/alias enforcement.

6. **Explicitly mark conditional branches.**  
   NIF/hybrid policy work should be tagged conditional in tasks with separate acceptance criteria from pure-BEAM default path.

---

### 6) Practical Mapping Summary for Phase 01 Planners

- Reuse **naming and structure conventions** from existing phase docs in `.planning/phases/01-xml-security-adr-and-guardrails/`.
- Reuse **module and seam contracts** from `.planning/research/ARCHITECTURE.md` and `01-RESEARCH.md`.
- Reuse **security fixture and CI gate discipline** from `01-VALIDATION.md` and `.planning/research/PITFALLS.md`.
- Assume **implementation code and CI files are greenfield**; tasks must be fully specified with concrete file-level outputs.
## PATTERN MAPPING COMPLETE

### Repository Reality (Phase 01)

This repository is currently **planning-first and code-greenfield**:

- Existing artifacts are concentrated in `.planning/` and `prompts/`.
- No `lib/`, `test/`, `.github/workflows/`, or `mix.exs` implementation baseline exists yet.
- For Phase 01, most analogs are **document-level conventions** rather than code-level reuse.

---

### 1) Anticipated Artifacts With Role Classification

| Anticipated path | Role classification | Closest analog reference(s) | Pattern confidence |
|---|---|---|---|
| `.planning/phases/01-xml-security-adr-and-guardrails/01-PATTERNS.md` | Phase planning support doc (pattern map) | `.planning/phases/01-xml-security-adr-and-guardrails/01-CONTEXT.md`, `01-RESEARCH.md`, `01-VALIDATION.md` | High |
| `.planning/phases/01-xml-security-adr-and-guardrails/01-01-PLAN.md` | Plan document (ADR decision plan) | `ROADMAP.md` plan indexing style (`01-01`, `01-02`, `01-03`) and `*-PLAN.md` convention from GSD workflow | Medium |
| `.planning/phases/01-xml-security-adr-and-guardrails/01-02-PLAN.md` | Plan document (seam freeze plan) | Same as above | Medium |
| `.planning/phases/01-xml-security-adr-and-guardrails/01-03-PLAN.md` | Plan document (guardrail plan) | Same as above | Medium |
| `.planning/phases/01-xml-security-adr-and-guardrails/01-ADR.md` (or equivalent ADR file in phase dir) | Architecture decision record (GATE-01/GATE-03) | ADR expectations in `01-RESEARCH.md`, `01-VALIDATION.md`, `ROADMAP.md` | Medium |
| `lib/relyra/security/xml.ex` | Core security seam behaviour (`parse_safely/2`, `select_signed_node/2`, `canonicalize/2`) | Contract prototype in `01-RESEARCH.md`; module tree in `.planning/research/ARCHITECTURE.md` | Medium (doc analog only) |
| `lib/relyra/error.ex` | Typed error contract module `%Relyra.Error{}` | Error shape in `01-RESEARCH.md`; requirement wording in `REQUIREMENTS.md` | Medium (doc analog only) |
| `lib/relyra/security/xml/*.ex` (adapter implementation(s)) | XML adapter implementation behind seam | Adapter naming in `.planning/research/ARCHITECTURE.md` (`Relyra.Security.XML.Sweet`, optional xmlsec path) | Low-Medium (doc analog only) |
| `test/security/xml/seam_contract_test.exs` | Contract/invariant tests for seam API | Explicit Wave 0 file target in `01-VALIDATION.md` | Medium (path analog only) |
| `test/security/xml/error_atoms_test.exs` | Deterministic typed error behavior tests | Explicit Wave 0 file target in `01-VALIDATION.md` | Medium (path analog only) |
| `test/security/xml/corpus_security_test.exs` | Security corpus gate tests | Explicit Wave 0 file target in `01-VALIDATION.md`; fixture policy in `.planning/research/PITFALLS.md` | Medium (path analog only) |
| `test/fixtures/security/xml/manifest.json` | Fixture metadata index and expected rejection mapping | Explicit Wave 0 file target in `01-VALIDATION.md`; schema fields in `01-RESEARCH.md` | Medium (path + schema analog) |
| `test/fixtures/security/xml/<taxonomy-classes>/...` | Adversarial fixture corpus directory | Taxonomy and directory shape in `01-RESEARCH.md` and `.planning/research/PITFALLS.md` | Medium (doc analog only) |
| `mix.exs` | Build, aliases, dependency/guardrail contract (`qa`, `ci.fast`, `ci.security`, `ci.integration`) | Suggested aliases in `01-RESEARCH.md` and `.planning/research/STACK.md` | Low-Medium (doc analog only) |
| `.github/workflows/*.yml` | CI gate enforcement, OTP matrix, conditional NIF checks | CI gate contract in `01-RESEARCH.md`, `01-CONTEXT.md`, `.planning/research/PITFALLS.md` | Low (no repo-local workflow analog) |

---

### 2) Recommended Analog References (Planner Read-First)

Use these as the primary pattern anchors when authoring executable plan tasks:

1. `.planning/phases/01-xml-security-adr-and-guardrails/01-VALIDATION.md`  
   Best source for concrete Phase 01 file targets, test lane names, and verification command shape.
2. `.planning/phases/01-xml-security-adr-and-guardrails/01-RESEARCH.md`  
   Best source for seam signatures, error taxonomy draft, fixture taxonomy/counts, and acceptance gate language.
3. `.planning/research/ARCHITECTURE.md`  
   Best source for module naming, namespace layout, and expected placement of `Relyra.Security.XML`.
4. `.planning/research/PITFALLS.md`  
   Best source for static-guardrail patterns and permanent security fixture discipline.
5. `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md`  
   Best source for plan numbering, requirement-to-phase mapping, and success-criteria framing.

---

### 3) Concrete Snippet-Level Conventions Already Present

These are the strongest reusable conventions currently available in-repo.

#### A) Phase artifact naming and placement

```text
.planning/phases/<NN>-<slug>/<NN>-CONTEXT.md
.planning/phases/<NN>-<slug>/<NN>-RESEARCH.md
.planning/phases/<NN>-<slug>/<NN>-VALIDATION.md
.planning/phases/<NN>-<slug>/<NN>-PATTERNS.md
```

#### B) XML seam callback shape (planning-level contract)

```elixir
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

#### C) Fixture corpus directory convention

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

#### D) Manifest field convention

```json
{
  "id": "fixture-id",
  "class": "xxe_entity_abuse",
  "requirement_ids": ["SEC-01", "GATE-02"],
  "expected_error_type": "doctype_forbidden",
  "notes": "optional"
}
```

#### E) Validation command convention

```bash
mix qa
mix ci.fast
mix ci.security
mix ci.integration
```

#### F) Wave-0 test file naming convention

```text
test/security/xml/seam_contract_test.exs
test/security/xml/error_atoms_test.exs
test/security/xml/corpus_security_test.exs
test/fixtures/security/xml/manifest.json
```

---

### 4) No-Analog-Found (Greenfield) Entries

These should be treated as **new contracts to establish in Phase 01**, not refactors.

| Target area | No analog found status | Planning implication |
|---|---|---|
| `lib/` module implementation style in this repo | No repo-local code analog found | Tasks must include full module skeletons, specs, and naming in `<action>`; do not assume inherited style from existing code |
| `test/` execution structure and helper conventions | No repo-local test analog found | Tasks must include test directory bootstrap and any required `test_helper.exs` assumptions |
| `.github/workflows/` CI layout | No repo-local workflow analog found | Tasks must define workflow filenames, triggers, matrix keys, and commands explicitly |
| `mix.exs` alias baseline | No repo-local `mix.exs` found | Tasks must include exact alias definitions required by Phase 01 gates |
| Existing ADR template file | No repo-local ADR template found | Planner should embed required ADR sections directly in task acceptance criteria |

---

### 5) Planner Recommendations for Executable Tasks (Mostly Greenfield Repo)

1. **Lead with bootstrap tasks before logic tasks.**  
   Sequence should begin with file/directory creation (`lib/`, `test/`, fixture tree, `mix.exs`) before seam or corpus logic.

2. **Use path-explicit actions, not intent-only actions.**  
   Good: "Create `lib/relyra/security/xml.ex` with behaviour callbacks `parse_safely/2`, `select_signed_node/2`, `canonicalize/2`."  
   Avoid: "Implement XML seam."

3. **Make every task acceptance grep/test-checkable.**  
   Include exact atoms, callback names, file paths, and commands in acceptance criteria so verification can run mechanically.

4. **Treat docs as source-of-truth until code exists.**  
   For Phase 01, `01-RESEARCH.md`, `01-VALIDATION.md`, and `.planning/research/ARCHITECTURE.md` are the primary "pattern library."

5. **Split plan waves by dependency, not by document type.**  
   Suggested dependency order: ADR decision lock -> seam/error contract skeleton -> fixture corpus + test gates -> CI/alias enforcement.

6. **Explicitly mark conditional branches.**  
   NIF/hybrid policy work should be tagged conditional in tasks with separate acceptance criteria from pure-BEAM default path.

---

### 6) Practical Mapping Summary for Phase 01 Planners

- Reuse **naming and structure conventions** from existing phase docs in `.planning/phases/01-xml-security-adr-and-guardrails/`.
- Reuse **module and seam contracts** from `.planning/research/ARCHITECTURE.md` and `01-RESEARCH.md`.
- Reuse **security fixture and CI gate discipline** from `01-VALIDATION.md` and `.planning/research/PITFALLS.md`.
- Assume **implementation code and CI files are greenfield**; tasks must be fully specified with concrete file-level outputs.
