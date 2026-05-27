# Phase 40: Operational Polish & Error Taxonomy — Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 4 (3 created + 1 modified)
**Analogs found:** 4 / 4 (all exact-or-strong matches; no green-field-without-precedent)

## File-to-Analog Map

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------------|------|-----------|----------------|---------------|
| `guides/troubleshooting.md` | markdown_guide | author → ExDoc → hexdocs.pm; operator reads on incident | `guides/recipes/logout.md` + `guides/recipes/generic_saml.md` + `guides/identity_mapping_and_provisioning.md` | exact (idiom-inheritance; Phase 36/37/39 lineage) |
| `guides/operations/incident_playbook.md` | markdown_guide | author → ExDoc → hexdocs.pm; operator reads during incident | `guides/recipes/generic_saml.md` (richest reference-table + closing-receipts idiom) + `guides/recipes/logout.md` (Relyra owns / Host owns preamble form) | exact (same idiom; new subdirectory `guides/operations/`) |
| `test/docs/troubleshooting_drift_test.exs` | exunit_drift_test | scans `lib/**/*.ex` + `guides/troubleshooting.md` → MapSet diff → ExUnit assertion | `test/security/ci_gate_integrity_test.exs` (hollow-gate meta-test failure-message vocabulary, mix.exs scan pattern) + `test/security/strict_default_proof_test.exs` (ExUnit header + assertion-by-test style) | exact (mirror target D-10 explicitly cites) |
| `mix.exs` (lines 111-134 + 149-159) | mix_alias_edit | append 2 lines to `extras:`; append 3 lines to `ci.docs` alias | `mix.exs` itself — existing `extras:` block and existing `ci.docs` alias provide the pattern | exact (self-analog; same file, append-only edits at known anchors) |

---

## Per-File Analog Blocks

### 1. `guides/troubleshooting.md`

- **role:** `markdown_guide`
- **data_flow:** Author writes hand-curated prose → `mix.exs` `extras:` registers the file → ExDoc renders to `hexdocs.pm/relyra/troubleshooting.html` at release time → operator reads during incident, scanning by `### :atom_name` anchor. The drift test (#3) gates this file against `lib/**/*.ex` atom emission sites.
- **closest_analog:** `guides/recipes/logout.md` (lines 1-41 establish the spine; lines 43-154 demonstrate the section-with-callout + bullet-list body style). Secondary references: `guides/identity_mapping_and_provisioning.md` (lines 1-58 for the "Relyra verifies / Host owns" preamble form against a non-recipe topic) and `guides/recipes/generic_saml.md` (lines 32-56 for the three-party `Relyra owns / IdP owns / Host owns` form when needed).
- **analog_excerpt** — opening spine from `guides/recipes/logout.md:1-41`:

  ```markdown
  # Logout Strategy And Operational Guidance

  This guide is the operator-facing reference for SAML Single Logout (SLO). Use it
  to understand the architectural realities of front-channel logout, configure
  stateful sessions correctly, and establish reliable security boundaries when
  cross-origin cookie deletion inevitably fails.

  ## Overview

  SAML Single Logout (SLO) is structurally unreliable in modern browsers. ...

  This guide provides the exact vocabulary to push back on rigid compliance
  checklists and establishes the mandatory fallbacks required to actually secure
  your application's sessions.

  ## Relyra owns / Host owns

  ## Relyra owns

  - Processing incoming `LogoutRequest` and `LogoutResponse` payloads.
  - Validating signatures on logout messages to prevent denial-of-service via
    unauthenticated session termination.
  - ...

  ## Host owns

  - Choosing the session storage mechanism (must be stateful/durable).
  - Mapping the SAML `SessionIndex` to the local durable session.
  - ...
  ```

  Note the **doubled** `## Relyra owns / Host owns` heading at line 24 followed by `## Relyra owns` at line 26 and `## Host owns` at line 35 — this is the project's idiomatic preamble shape (the H2 frame heading followed by two H2 sub-frames; not a typo). Phase 40's `guides/troubleshooting.md` MUST replicate this structure verbatim.

- **divergence_notes:**
  1. **No "## 1. ... ## 2. ... ## 3. ..." numbered top-level sections.** `logout.md` numbers four top-level operator-story sections; `troubleshooting.md` instead uses **8 trust-pipeline-seam-grouped H2 sections** (XML Hardening / Signature & Crypto / Replay & Request Intent / Metadata Lifecycle / Network / Fetch / Binding & Protocol Shape / Configuration & Adapter Wiring / Session & Logout) per D-02. Under each H2, atoms are documented with `### :atom_name` H3 headings per D-03.
  2. **Four-field micro-block per atom.** Each `### :atom_name` H3 is followed by exactly four labeled lines (D-04): **Means:** / **Likely root cause:** / **Operator action:** / **Source:** `lib/path/file.ex`. This shape does NOT appear in `logout.md` — it is novel to this guide and load-bearing for the drift test's H3-anchor regex.
  3. **No "## 1. The Compliance Trap" style narrative.** The body is reference/decoder, not narrative essay. Per-section preambles open with a one-sentence trust-boundary frame ("These atoms fire BEFORE saxy parse runs — the request never reached the trust core.") per the specifics in CONTEXT.md.
  4. **Closing receipt cross-links the playbook**, not a code snippet. Where `logout.md` ends at "Document this dual-layer approach for your auditors" (line 154), `troubleshooting.md` closes with a brief pointer into `guides/operations/incident_playbook.md` so the operator path is: see atom in logs → look it up in decoder → follow scenario runbook in playbook.
  5. **H3 form is rigid.** D-03 forbids any decoration on `### :atom_name` (no backticks, no em-dash trailing text, no emoji). The drift test's `~r/^### :([a-z_][a-z0-9_]*)\b/m` is the load-bearing parser; styling drift in a heading silently produces a "stale doc entry" failure for every atom in the doc.

---

### 2. `guides/operations/incident_playbook.md`

- **role:** `markdown_guide`
- **data_flow:** Author writes hand-curated prose → `mix.exs` `extras:` registers the file → ExDoc renders → operator hits this doc when they have a symptom (cert expiry imminent, replay storm, signature regression after IdP key rotation, etc.) and need a step-by-step Triage → Diagnose → Recover narrative. Body is anchored on a **five-surface reference table** (telemetry / audit / LiveView admin / Mix tasks / troubleshooting decoder) and **six scenario runbooks** per D-14/D-15.
- **closest_analog:** `guides/recipes/generic_saml.md` (richest example of the Overview → Receipt → three-party preamble → reference table → debugging-flow ordered-list → closing receipt spine). Secondary reference: `guides/recipes/logout.md` (for the lighter two-party `Relyra owns / Host owns` preamble form and the brand-voice closing receipt). Tertiary: `guides/identity_mapping_and_provisioning.md` (for the prose voice on a non-recipe operational topic).
- **analog_excerpt** — reference-table + closing-receipt anchor from `guides/recipes/generic_saml.md:13-31`:

  ```markdown
  ## Overview

  Use this guide when you already know which IdP you are integrating, but the repo
  does not ship a first-class preset for it. The goal is not to make you fluent in
  SAML theory. The goal is to help you translate your IdP's admin labels into the
  exact Relyra seams that matter for a safe first login.

  The safe Day-1 order stays the same:

  1. Prove the local trust path with `Relyra.TestSupport.FakeIdP`.
  2. Publish your SP metadata from Relyra's real runtime fields.
  3. Import or transcribe the IdP metadata Relyra actually consumes.
  4. Verify NameID and claim choices before treating the provider as complete.
  5. Enable signed requests or encrypted assertions only when the IdP requires them.

  Receipt:

  - One successful SP-initiated login after the local `FakeIdP` proof already passed.

  ## Relyra owns / IdP owns / Host owns

  ## Relyra owns

  - Strict ACS validation, XML parsing, signature verification, and replay checks.
  ...
  ```

  And the reference-table shape from `guides/recipes/generic_saml.md:62-71`:

  ```markdown
  | Relyra seam | What it means | Where it shows up |
  | --- | --- | --- |
  | `sp_entity_id` | The service provider identifier your IdP will treat as the audience / relying-party identifier | `entityID` on the SP metadata root and the IdP field often labeled `Entity ID`, `Audience URI`, or `Identifier` |
  | `acs_url` | The browser POST target for SAML responses | `AssertionConsumerService Location` in SP metadata and the IdP field often labeled `ACS URL`, `Reply URL`, or `Single sign-on URL` |
  | `sign_authn_requests` | Whether Relyra signs redirect-binding AuthnRequests | `AuthnRequestsSigned="true"` on the SP metadata and a signing `KeyDescriptor use="signing"` when enabled |
  ```

  And the ordered-list scenario-flow shape from `guides/recipes/generic_saml.md:225-241`:

  ```markdown
  Use a fixed order so you do not debug three moving parts at once:

  1. `FakeIdP` proof: make sure the local trust path already succeeds.
  2. Metadata values: verify `sp_entity_id`, `acs_url`, `idp_entity_id`, and
     `idp_sso_url` exactly.
  3. Signing certificates: confirm the active IdP signing certs in Relyra match the
     IdP's current metadata or export.
  ...
  ```

- **divergence_notes:**
  1. **Two-party preamble, not three.** `generic_saml.md` uses `## Relyra owns / IdP owns / Host owns` (three sub-frames). The playbook uses the simpler two-party `## Relyra owns / Host owns` form from `logout.md:24-41` — the IdP is the source of incidents but is not an "owner" of incident response. Operator and Relyra are the two parties.
  2. **Five-surface reference table replaces the field-reference table.** The analog's table maps "Relyra seam → meaning → IdP label." The playbook's centerpiece table maps **incident-evidence surface → exact code anchor → what it tells you**:
     - Telemetry events (cite verbatim from `lib/relyra/telemetry.ex`)
     - Audit ledger (`relyra_audit_events` table + `@domain_values` + `@action_values` from `lib/relyra/ecto/audit_event.ex:13-26`)
     - LiveView admin routes from `lib/relyra/live_admin/router.ex` — **use `:connection_id`, NOT `:id`** (RESEARCH.md Step 5 correction to CONTEXT.md D-14)
     - 7 Mix tasks (not 8 — RESEARCH.md Step 6 correction)
     - Cross-link to `guides/troubleshooting.md`
  3. **Six scenario-anchored runbooks.** Each scenario is a 3-step ordered list **Triage → Diagnose → Recover**, cross-referencing the reference table rather than restating evidence sources inline. Scenarios per D-15: cert expiry imminent, metadata drift after IdP change, replay storm, signature regression after IdP key rotation, ACS misconfiguration at provisioning, attribute mapping breakage.
  4. **Replay storm runbook MUST explicitly note no audit signal.** Per RESEARCH.md Step 4: `lib/relyra/replay_store/{ecto,ets}.ex` contain ZERO `AuditWriter.append_event` calls (verified). Replays do not mutate trust state, so they intentionally produce no audit row. Operators rely on `[:relyra, :saml, :replay, :check]` telemetry alone. This is a non-obvious gap; the playbook names it.
  5. **Closing receipt is brand-metaphor + diagnostic-bundle pointer.** Per D-16, the doc closes with a "When in doubt, run `mix relyra.diagnostic`" anchor pointing at `lib/mix/tasks/relyra.diagnostic.ex` + `lib/relyra/diagnostic.ex` (DIAG-01, Phase 23). Phrasing mirrors CLAUDE.md's brand metaphor: "every login resolves to a verified trust path or a typed rejection — and when in doubt, the diagnostic bundle is the trace."
  6. **New subdirectory `guides/operations/`** — green-field. No analog directory exists; the only sibling subdirectories under `guides/` today are `guides/recipes/` and `guides/case_studies/`. Subdirectory creation is implicit in writing the file at the path.

---

### 3. `test/docs/troubleshooting_drift_test.exs`

- **role:** `exunit_drift_test`
- **data_flow:** Test boot via `ExUnit.start` in `test/test_helper.exs` (auto-discovered — verified RESEARCH.md Step 11). The test reads `lib/**/*.ex` source bytes via `Path.wildcard/1` + `File.read!/1`, applies three D-08 regex patterns, builds `code_atoms :: MapSet.t(atom)`. Reads `guides/troubleshooting.md` via `File.read!/1`, applies the D-09 regex `~r/^### :([a-z_][a-z0-9_]*)\b/m`, builds `doc_atoms :: MapSet.t(atom)`. Asserts `MapSet.difference(code_atoms, doc_atoms)` is empty AND `MapSet.difference(doc_atoms, code_atoms)` is empty (bidirectional, per D-10).
- **closest_analog:** `test/security/ci_gate_integrity_test.exs` (the mirror target named explicitly in D-10 for failure-message vocabulary). Secondary: `test/security/strict_default_proof_test.exs:1-3` (ExUnit case-header idiom verified at RESEARCH.md Code Examples).
- **analog_excerpt** — ExUnit case header + module attribute pattern + bidirectional file-existence assertion shape from `test/security/ci_gate_integrity_test.exs:1-50, 95-101`:

  ```elixir
  defmodule Relyra.Security.CiGateIntegrityTest do
    @moduledoc """
    Anti-hollow meta-gate for the `ci.security` Mix alias.

    ## Why this test exists

    `mix` deduplicates the `test` task within a single `mix` invocation: ...
    The fix is to run each security suite as its own `cmd mix test ...` step ...
    """
    use ExUnit.Case, async: true

    # The security contract: {relative_path, tag_or_nil}.
    @gated_suites [
      {"test/security/ci_gate_integrity_test.exs", nil},
      {"test/security/strict_default_proof_test.exs", nil},
      ...
    ]

    ...

    test "every gated security suite file exists on disk (T-30-14 presence)" do
      for {path, _tag} <- @gated_suites do
        assert File.exists?(path),
               "gated security suite #{path} is named in ci.security but does not exist on disk — " <>
                 "the alias would error or the gate would be hollow"
      end
    end
  ```

  And the dedup/hollow-gate failure-message vocabulary from `test/security/ci_gate_integrity_test.exs:117-132`:

  ```elixir
        refute Regex.match?(~r/^test\s/, trimmed),
               "ci.security runs #{path} via a BARE `test` step:\n\n  #{trimmed}\n\n" <>
                 "mix dedups the `test` task within one alias run and ci.conformance already " <>
                 "consumed it with `--only conformance`, so this suite would be silently skipped " <>
                 "(hollow gate). Use `cmd mix test ...` (a fresh OS process) instead."
  ```

  And the assertion-by-test single-fact shape from `test/security/strict_default_proof_test.exs:14-22`:

  ```elixir
  test "deprecated_algorithm stays fail-closed for SHA-1 by default" do
    policy = AlgorithmPolicy.default()

    assert %Error{type: :deprecated_algorithm} =
             AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)

    assert %Error{type: :deprecated_algorithm} =
             AlgorithmPolicy.enforce_digest_method(policy, @digest_sha1)
  end
  ```

- **divergence_notes:**
  1. **Module location is `test/docs/`, NOT `test/security/`.** Per D-06 and D-11, this is a docs-lane test. Adding it to `test/security/` would force a `@gated_suites` amendment in `test/security/ci_gate_integrity_test.exs` for zero security benefit AND miscategorize a doc failure as a security-lane failure. The drift test runs under `ci.docs` (D-19), not `ci.security`.
  2. **Module name uses `Docs.` namespace, not `Security.`** — recommended `Relyra.Docs.TroubleshootingDriftTest` (per RESEARCH.md Code Examples section). Module-name namespace mirrors the directory path, project-idiomatic.
  3. **No `@gated_suites` module attribute.** The analog enumerates a fixed list of `{path, tag}` tuples. The drift test instead uses **three module attributes for the D-08 regex patterns** (`@code_pattern_singleline`, `@code_pattern_multiline`, `@code_pattern_structlit`) and **one for the D-09 pattern** (`@doc_pattern`). Per D-07, no `@known_types` enumeration anywhere — the codebase is the single source of truth.
  4. **One test case, not four.** The analog runs four tests (existence / referenced / `cmd mix test`-vs-bare / tag-integrity). The drift test runs ONE test case (`"every emitted :error_type atom has a documented decoder entry, and vice versa"`) with TWO assertions inside (missing-in-doc and stale-in-doc). Both assertions inside the same test is intentional: a single drift-detection unit is conceptually one fact ("doc matches code"), and operators reading the failure should see both directions at once.
  5. **Failure-message vocabulary mirror.** The analog uses the form `"<subject> #{path-or-name} <expected condition not met> — <consequence>"` (line 98-99). The drift test mirrors this verbatim per D-10:
     - `"Missing doc entry for: :#{atom} — add ### :#{atom} section to guides/troubleshooting.md (source: #{path})"`
     - `"Stale doc entry for: :#{atom} — atom no longer emitted by Relyra; remove from troubleshooting.md or re-introduce in lib/"`

     Per RESEARCH.md Open Question #3 recommendation: when an atom has multiple emission sites (e.g. `:adapter_not_configured` has 9 sites), list all sites comma-separated in the `(sources: ...)` clause.
  6. **No `Code.string_to_quoted!/1`.** The analog parses `mix.exs` as AST to find the `ci.security` alias. The drift test does pure byte-regex scanning of `.ex` source files — appropriate because the D-08 contract is literal-emission detection, not scope-resolved atom enumeration. RESEARCH.md "Don't Hand-Roll" table verifies this is the right call.
  7. **`@moduledoc` documents the variadic-helper rule.** Per RESEARCH.md Pitfall 1: three modules (`lib/relyra/protocol/logout_request.ex`, `lib/relyra/protocol/logout_response.ex`, `lib/relyra/security/xml/pure_beam.ex`) emit through `require_present_fields/4` where `error_type` is a function parameter — the D-08 regexes do NOT match those construction sites. Every atom they fan out to IS independently covered by a literal site, but a future contributor adding a NEW atom only via the variadic helper would silently bypass the gate. The test moduledoc MUST state: *"Every atom emitted by Relyra must appear as a literal `Error.new(:atom, ...)` or `%Relyra.Error{type: :atom}` site at least once somewhere in `lib/`. Variadic helpers are fine but require a literal companion site."*
  8. **`async: true` is safe.** No Ecto/repo interaction; the test does pure file reads. The analog also uses `async: true` (line 26).
  9. **78-atom lock at planner time.** Per RESEARCH.md Step 1: the canonical set is 78 atoms across 33 modules (not the "~60" in CONTEXT.md D-05). Planner should re-validate this count at plan-write time (RESEARCH.md Open Question #1) and lock the verified number in the SUMMARY contract.

---

### 4. `mix.exs` (modifications)

- **role:** `mix_alias_edit`
- **data_flow:** Two append-only edits in two distinct keyword entries of the same file: (a) `docs/0` → `extras:` list gets two new lines; (b) `aliases/0` → `"ci.docs":` list gets three new lines. ExDoc consumes `extras:` at `mix docs` time; `mix ci.docs` consumes the alias list step-by-step at CI time. No edits to any other alias (`ci.security` explicitly untouched per D-11).
- **closest_analog:** `mix.exs` itself, lines 111-134 (existing `extras:` list shape) and lines 149-159 (existing `ci.docs` alias shape).
- **analog_excerpt** — existing `extras:` list anchor from `mix.exs:122-134`:

  ```elixir
        extras: [
          "README.md",
          "BATTERIES_INCLUDED.md",
          "CHANGELOG.md",
          ...
          "guides/case_studies/operator_managed_rollout.md",
          "guides/case_studies/phoenix_saas_tenant_onboarding.md",
          "guides/recipes/adfs.md",
          "guides/recipes/generic_saml.md",
          "guides/recipes/okta.md",
          "guides/recipes/entra.md",
          "guides/recipes/google_workspace.md",
          "guides/recipes/logout.md"   # ← anchor: D-17 appends AFTER this line
        ]
  ```

  And the existing `ci.docs` alias anchor from `mix.exs:149-159`:

  ```elixir
        "ci.docs": [
          "cmd test -f guides/batteries_included.md",
          "cmd test -f BATTERIES_INCLUDED.md",
          "cmd test -f guides/identity_mapping_and_provisioning.md",
          "cmd test -f guides/recipes/adfs.md",
          "cmd test -f guides/recipes/generic_saml.md",
          "cmd test -f guides/recipes/logout.md",   # ← anchor: D-18 appends AFTER this line
          "test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors",
          "test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors",
          "relyra.batteries_included --check"
        ],
  ```

  Note the existing alias mixes `cmd test -f <path>` presence guards (lines 150-155) with bare `test ...` lines (lines 156-157) and a final mix-task invocation (line 158). The pattern is: **presence guards FIRST, then test invocations, then task invocations.** D-19's `cmd mix test ...` line for the drift test must land between the presence-guard block and the existing bare `test ...` lines, preserving this ordering.

- **divergence_notes:**
  1. **`extras:` edit — append exactly two lines after `"guides/recipes/logout.md"` (currently line 133) per D-17:**

     ```elixir
           "guides/recipes/logout.md",
           "guides/troubleshooting.md",                    # NEW (D-17, first)
           "guides/operations/incident_playbook.md"        # NEW (D-17, second)
         ]
     ```

     Order matters: `troubleshooting.md` BEFORE `incident_playbook.md`. ExDoc renders extras in literal list order, so this determines the hexdocs.pm sidebar order. D-17 locks this; RESEARCH.md Pitfall 4 warns against alphabetical-instinct reversal.

  2. **`ci.docs` edit — append exactly three lines after `"cmd test -f guides/recipes/logout.md"` (currently line 155) and BEFORE the existing `"test test/mix/tasks/relyra_batteries_included_test.exs ..."` line (currently line 156). Per D-18 + D-19:**

     ```elixir
           "cmd test -f guides/recipes/logout.md",
           "cmd test -f guides/troubleshooting.md",                                      # NEW (D-18, first)
           "cmd test -f guides/operations/incident_playbook.md",                         # NEW (D-18, second)
           "cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors", # NEW (D-19)
           "test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors",
           ...
     ```

     Per D-18 + D-19 ordering:
     - **Presence guard for `troubleshooting.md` BEFORE presence guard for `incident_playbook.md`** (mirrors D-17 extras order — RESEARCH.md Open Question #2 recommendation).
     - **Both presence guards BEFORE the drift test invocation.** Without presence guards, deleting `guides/troubleshooting.md` would pass the drift test vacuously (0 doc atoms ∩ 0 code atoms = trivially equal). The presence guard is the real delete-protector.
     - **Drift test uses `cmd mix test ...` form, NOT bare `test`** (D-19). Even though `ci.docs` does NOT run `ci.conformance` first (so the original Phase 30 dedup hazard doesn't bite here), using `cmd mix test` keeps the alias-step style consistent with `ci.security` and is future-proof if `ci.docs` is ever restructured. Note that the EXISTING bare `test ...` lines at the bottom of `ci.docs` (lines 156-157) are intentionally left as bare `test` — Phase 40 does not refactor them; D-19 only governs the NEW step.

  3. **No edits to `package/0 files:` list.** The new guides under `guides/` are already covered by the existing `"guides"` directory entry at line 90 (verified at `mix.exs:90`). No additional file-list registration is needed for Hex packaging.

  4. **No edits to ANY other alias.** Specifically: `qa`, `ci.fast`, `ci.conformance`, `ci.security`, `ci.verify`, `ci.integration`, `ci.admin_ui`, `ci.oban_smoke`, `ci.release` — all untouched. D-11 explicitly leaves `ci.security` alone; the others have no dependency on the new guides or the new test.

  5. **No new dependency.** `deps/0` (lines 56-76) is untouched. Phase 40 adds zero Hex packages (RESEARCH.md "Package Legitimacy Audit" — explicitly skipped).

---

## Shared Patterns (cross-cutting concerns)

These apply to multiple files; planner should reference each in the relevant plan's action section.

### Shared 1 — Brand voice & trust-boundary metaphor

**Source:** `CLAUDE.md` "What this project is" — "Every login ends in a cryptographically verified assertion or a typed rejection — never a silent compromise."

**Apply to:** Both new guides (#1 and #2). The closing receipt of `guides/operations/incident_playbook.md` MUST mirror this metaphor verbatim per D-16: *"every login resolves to a verified trust path or a typed rejection — and when in doubt, the diagnostic bundle is the trace."* The troubleshooting decoder's per-section preambles should echo the same fail-closed posture.

### Shared 2 — Hollow-gate-style CI invariant (each suite its own `cmd mix test`)

**Source:** `test/security/ci_gate_integrity_test.exs:113-135` and `mix.exs:179-187` (existing `ci.security` step pattern), per CLAUDE.md "Testing Requirements."

**Apply to:** `mix.exs` (#4), specifically the D-19 `cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors` line. Even though `ci.docs` doesn't run `ci.conformance` first, using `cmd mix test` keeps the alias-step style consistent across the project's CI lanes.

```elixir
# From mix.exs:179-187 — the established hollow-gate-immune pattern.
"cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
"cmd mix test test/security/strict_default_proof_test.exs --warnings-as-errors",
"cmd mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors",
...
```

### Shared 3 — `Relyra owns / Host owns` preamble heading shape

**Source:** `guides/recipes/logout.md:24-41` (verbatim shape: H2 frame heading + two H2 sub-frames + bulleted lists).

**Apply to:** Both new guides (#1 and #2). The doubled-`##` form (`## Relyra owns / Host owns` followed by `## Relyra owns` and `## Host owns` as separate H2s on their own lines) is the project idiom. Do not collapse to a single H2 with two H3 sub-sections — that breaks consistency with three predecessor guides (logout, generic_saml, identity_mapping).

### Shared 4 — Failure-message vocabulary (em-dash, names-the-subject, names-the-consequence)

**Source:** `test/security/ci_gate_integrity_test.exs:96-100, 117-132`. Per CLAUDE.md "Decision Posture" and the strict-defaults assertion-by-test posture.

**Apply to:** `test/docs/troubleshooting_drift_test.exs` (#3) failure messages. Exactly per D-10:

```
<subject> #{path-or-name} <expected-not-met> — <consequence-or-action>
```

### Shared 5 — Conventional commits + `Co-Authored-By:` footer

**Source:** `CLAUDE.md` "Commit Style."

**Apply to:** All commits the planner emits for Phase 40 tasks. Types: `docs:` for guide additions (#1, #2), `test:` for the drift test (#3), `chore:` or `ci:` for the `mix.exs` edits (#4). Or one umbrella `feat:` if framed as a new doc surface — planner discretion.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | All four files have strong analogs. None are green-field-without-precedent. |

The closest thing to "no analog" is the **`guides/operations/` subdirectory itself** — green-field directory under `guides/`. But the file inside (`incident_playbook.md`) inherits the recipe-guide idiom 1:1; only the directory is new, and directory creation is implicit in writing the file at the path.

---

## Metadata

**Analog search scope:**
- `guides/recipes/*.md` (all six recipes read end-to-end for #1 and #2)
- `guides/identity_mapping_and_provisioning.md` (read for #1 and #2 idiom)
- `test/security/ci_gate_integrity_test.exs` (read end-to-end for #3)
- `test/security/strict_default_proof_test.exs` (read 80 lines for #3 ExUnit case-header idiom)
- `mix.exs` (read end-to-end for #4)
- `.planning/phases/40-operational-polish-error-taxonomy/40-CONTEXT.md` + `40-RESEARCH.md` (read fully)

**Files scanned:** 8 analog candidates; all 4 new/modified files received a strong-match analog.

**Pattern extraction date:** 2026-05-27

**Source-of-truth corrections carried from RESEARCH.md (planner must use these):**
- Atom count: **78** (not "~60" from CONTEXT.md D-05).
- LiveAdmin route parameter: **`:connection_id`** (not `:id` from CONTEXT.md D-14).
- Mix task inventory: **7 Relyra tasks** (not "eight" from CONTEXT.md `code_context`).
- Variadic-helper edge case: documented in test moduledoc (Pitfall 1 mitigation).
