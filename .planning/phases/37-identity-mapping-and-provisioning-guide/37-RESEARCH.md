# Phase 37: Identity Mapping and Provisioning Guide - Research

**Researched:** 2026-05-26
**Requirement anchor:** `DOCS-03`
**Goal:** Publish `guides/identity_mapping_and_provisioning.md` with three mapping patterns, a JIT decision tree, complete `UserMapper` behaviour documentation with examples, an explicit SCIM non-goal, a JIT+SCIM conflict warning, and anchor-stability guidance. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.3-ROADMAP.md]
**Confidence:** HIGH for scope, seams, and verification shape; MEDIUM for the public `UserMapper` contract wording because the current callback docs and ACS call site do not describe the same input shape. [VERIFIED: .planning/STATE.md] [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex]

## Summary

Phase 37 should stay documentation-only, but it is still a public contract phase because it explains where Relyra stops and the host application starts on the auth boundary. The new guide should be written as an operator/developer handoff doc, not as SAML theory: Relyra verifies the assertion and hands the host a validated identity payload, `UserMapper` turns that payload into an application user map, and host-owned code still decides whether to create a user, link an account, reject the login, or hand lifecycle ownership to a separate provisioning system. [VERIFIED: README.md] [VERIFIED: guides/getting_started.md] [VERIFIED: lib/relyra.ex] [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex]

The repo already contains most of the factual material the guide needs: `LoginResult` and `Principal` define the verified identity shape, `ACSController` shows the runtime sequence `consume_response -> UserMapper -> SessionAdapter`, `DefaultAttribute` and the Ecto mapping schemas show the existing mapping patterns Relyra supports today, and the install task proves the host app is expected to provide its own `UserMapper` implementation by default. The biggest planning risk is contract drift: `Relyra.UserMapper` advertises an `assertion :: map()` callback, but the Phoenix ACS success path passes a full `%Relyra.LoginResult{}` while `DefaultAttribute` reads top-level `:attributes` and `:name_id`. The phase should document that truth explicitly and likely tighten the behaviour docs instead of implying a cleaner contract than the code currently provides. [VERIFIED: lib/relyra/login_result.ex] [VERIFIED: lib/relyra/principal.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: lib/mix/tasks/relyra.install.ex]

**Primary recommendation:** Plan this as two documentation plans: first create the guide plus `UserMapper` API docs/examples anchored to the real runtime seam, then wire the guide into publication/routing and fail-closed docs gates. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/36-generic-saml-runbook/36-RESEARCH.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-03 | Identity mapping and provisioning guide published with NameID-vs-app-identity patterns, JIT decision tree, `UserMapper` behaviour examples, JIT+SCIM conflict warning, and explicit SCIM-lifecycle non-goal. [VERIFIED: .planning/REQUIREMENTS.md] | The codebase already defines the verified identity payload (`Relyra.LoginResult`, `Relyra.Principal`), mapper seam (`Relyra.UserMapper`), default mapping behavior (`Relyra.UserMapper.DefaultAttribute`), persisted mapping shape (`Relyra.Connection.mapping_config`, Ecto mapping schemas, `ConnectionSnapshot`), and host-owned session step (`Relyra.SessionAdapter` via ACS flow). The missing work is documentation and docs publication/gating, not new runtime capability. [VERIFIED: lib/relyra/login_result.ex] [VERIFIED: lib/relyra/principal.ex] [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: mix.exs] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Do not build outside the active phase scope; this phase is documentation-only and there is no active Phase 37 plan yet. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/STATE.md]
- Escalation is required only for public API shape changes, default-tightening, security posture changes, or SemVer-major bumps; pure docs work should proceed with one coherent recommendation. [VERIFIED: CLAUDE.md]
- Keep the security invariants explicit in docs: trust configured IdP certs only, keep one parse path, keep pre-parse guards before Saxy, require real crypto verification, preserve audit co-commit, and keep replay protection required in production. [VERIFIED: CLAUDE.md]
- Do not document SCIM lifecycle ownership as part of Relyra; the project already states SCIM lifecycle ownership is out of scope for the library. [VERIFIED: CLAUDE.md] [VERIFIED: README.md] [VERIFIED: .planning/REQUIREMENTS.md]
- `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` are the standing verification gates after any code or `mix.exs` doc-gate changes. [VERIFIED: CLAUDE.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Explain verified identity inputs (`LoginResult`, `Principal`, connection) to host implementers | Library docs | Behaviour module docs | The guide should translate the runtime objects Relyra already returns into implementer-facing examples without inventing a new contract. [VERIFIED: lib/relyra/login_result.ex] [VERIFIED: lib/relyra/principal.ex] [VERIFIED: lib/relyra/user_mapper.ex] |
| Explain mapping patterns (NameID anchor, attribute anchor, JIT create-or-update) | Guide content | Existing generic SAML / provider docs | The patterns belong in one focused guide, but they should cross-link the existing onboarding and provider-specific docs instead of duplicating them. [VERIFIED: guides/getting_started.md] [VERIFIED: guides/recipes/generic_saml.md] [VERIFIED: guides/recipes/adfs.md] |
| Publish the new guide in generated docs | `mix.exs` ExDoc extras | README / guide cross-links | `guides/identity_mapping_and_provisioning.md` is currently missing and not published in ExDoc extras. [VERIFIED: mix.exs] [VERIFIED: guides/identity_mapping_and_provisioning.md missing via shell check on 2026-05-26] |
| Prevent accidental deletion or drift of the guide | `mix.exs` `ci.docs` alias | Grep-based content checks in plan verification | Phase 36 already established the docs-presence-gate pattern for `guides/recipes/generic_saml.md`; Phase 37 should reuse it. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/36-generic-saml-runbook/36-RESEARCH.md] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Markdown guide in `guides/` | repo-native | Public operator/developer documentation surface for the new identity-mapping guide. [VERIFIED: guides/getting_started.md] [VERIFIED: guides/recipes/generic_saml.md] | Existing guide work in Phases 27 and 36 already uses markdown under `guides/` as the canonical public runbook format. [VERIFIED: README.md] [VERIFIED: guides/getting_started.md] |
| `Relyra.UserMapper` + host app implementation | repo-native | Public extension seam for translating verified identity data into app-specific user attributes. [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/mix/tasks/relyra.install.ex] | The installer scaffolds a host-owned mapper module, and ACS calls the behaviour before session establishment. [VERIFIED: lib/mix/tasks/relyra.install.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] |
| ExDoc extras in `mix.exs` | ExDoc dependency present; docs list managed in repo config | Ships guide content with published docs output. [VERIFIED: mix.exs] | Phase 36 already added `guides/recipes/generic_saml.md` to this list; Phase 37 should use the same publication path. [VERIFIED: mix.exs] |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `Relyra.UserMapper.DefaultAttribute` | Demonstrates fallback email/name/group extraction and persisted mapping-rule projection. [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] | Use as the factual baseline for guide examples, but do not overstate it as full JIT provisioning. [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: test/relyra/user_mapper/default_attribute_test.exs] |
| Persisted mapping config (`mapping_config`, `AttributeMapping`, `GroupMapping`, `ConnectionSnapshot`) | Shows the durable mapping-rule shape Relyra already supports. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/ecto/attribute_mapping.ex] [VERIFIED: lib/relyra/ecto/group_mapping.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] | Use when documenting attribute-anchor and role/group mapping examples that should mirror current persisted semantics. [VERIFIED: test/relyra/ecto/ecto_connection_resolver_test.exs via `rg` evidence] |
| `ci.docs` alias | Fail-closed presence gate for public guides. [VERIFIED: mix.exs] | Use in the second plan so the new guide cannot disappear silently. [VERIFIED: mix.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One focused guide under `guides/identity_mapping_and_provisioning.md` | Scatter mapping advice across `README.md`, `guides/getting_started.md`, and provider runbooks | Scattering would repeat anchor/JIT/SCIM guidance and make drift more likely. The roadmap explicitly asks for one authoritative guide. [VERIFIED: .planning/milestones/v1.3-ROADMAP.md] |
| Repo-native examples from `UserMapper`, `DefaultAttribute`, and ACS flow | Generic pseudo-SAML prose detached from code | Detached prose would miss the current contract ambiguity and would not tell adopters what objects actually move through the runtime seam. [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] |

**Installation:** No new runtime or docs dependencies are required for this phase; the work should reuse the existing guide, ExDoc, and Mix alias surfaces already present in the repo. [VERIFIED: mix.exs]

## Repo Seams To Reuse

- `lib/relyra.ex` normalizes successful response consumption into `%Relyra.LoginResult{principal, connection, relay_state, issuer, in_response_to, return_to}`. This is the nearest thing to the verified identity payload contract the guide can cite. [VERIFIED: lib/relyra.ex] [VERIFIED: lib/relyra/login_result.ex]
- `lib/relyra/principal.ex` defines the verified subject fields that matter for identity anchoring: `name_id`, `name_id_format`, `session_index`, `attributes`, `authn_instant`, `authn_context_class_ref`, and `connection_id`. [VERIFIED: lib/relyra/principal.ex]
- `lib/relyra/phoenix/controllers/acs_controller.ex` proves the runtime order is `consume_response -> UserMapper.map_attributes(login_result, login_result.connection, opts) -> SessionAdapter.establish_session(mapped_user, login_result, opts)`. The guide should explain this exact ownership split. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex]
- `lib/relyra/user_mapper.ex` is the public behaviour seam and telemetry wrapper. Its current moduledoc is minimal and its callback type says `assertion :: map()`, so this file is the best candidate for code-level documentation improvement during the phase. [VERIFIED: lib/relyra/user_mapper.ex]
- `lib/relyra/user_mapper/default_attribute.ex` and `test/relyra/user_mapper/default_attribute_test.exs` define the current built-in mapping semantics: fallback extraction from email/name/group candidates, persisted `attribute_rules`, persisted `group_rules`, deterministic rule order, exact group-value matching, `:first`/`:all` multivalue strategies, and no transformation DSL. [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: test/relyra/user_mapper/default_attribute_test.exs]
- `lib/relyra/connection.ex`, `lib/relyra/ecto/attribute_mapping.ex`, `lib/relyra/ecto/group_mapping.ex`, `lib/relyra/ecto/connection_snapshot.ex`, and `lib/relyra/ecto/mapping_commands.ex` define the persisted mapping contract the guide should describe truthfully. Persisted mapping supports field projection and role assignment, not regex/script/expression/template transforms. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/ecto/attribute_mapping.ex] [VERIFIED: lib/relyra/ecto/group_mapping.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/ecto/mapping_commands.ex]
- `lib/mix/tasks/relyra.install.ex` and `test/mix/relyra_install_test.exs` prove a host-owned `MyApp.Relyra.UserMapper` scaffold is part of the expected Day-1 integration story. [VERIFIED: lib/mix/tasks/relyra.install.ex] [VERIFIED: test/mix/relyra_install_test.exs]
- `README.md`, `guides/getting_started.md`, `guides/recipes/generic_saml.md`, and `guides/recipes/adfs.md` already carry the support taxonomy, NameID stability warning, and “host owns tenant provisioning workflow” framing that the new guide should extend rather than duplicate. [VERIFIED: README.md] [VERIFIED: guides/getting_started.md] [VERIFIED: guides/recipes/generic_saml.md] [VERIFIED: guides/recipes/adfs.md] [VERIFIED: guides/jtbd_user_flows.md] [VERIFIED: guides/case_studies/phoenix_saas_tenant_onboarding.md]

## Recommended Phase Split

### Plan 37-01: Guide + behaviour docs anchored to the real runtime seam

Scope: create `guides/identity_mapping_and_provisioning.md`; add the ownership boundary section; cover the three mapping patterns; add a JIT decision tree; and expand `lib/relyra/user_mapper.ex` docs so the public contract, expected inputs, and examples are visible in ExDoc. [VERIFIED: .planning/milestones/v1.3-ROADMAP.md] [VERIFIED: lib/relyra/user_mapper.ex]

Why first: the guide content cannot be truthful until it states what object the mapper actually receives, what `DefaultAttribute` really does today, and what the host app still owns after mapping. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: lib/mix/tasks/relyra.install.ex]

Likely files:
- `guides/identity_mapping_and_provisioning.md`
- `lib/relyra/user_mapper.ex`

### Plan 37-02: Publication, routing, and fail-closed docs gate

Scope: add the new guide to `mix.exs` ExDoc extras and `ci.docs`; add or tighten cross-links from the most relevant existing docs surfaces, likely `guides/recipes/generic_saml.md` and possibly `README.md` or `guides/getting_started.md` only if the routing text needs one explicit “identity mapping” follow-on pointer. [VERIFIED: mix.exs] [VERIFIED: README.md] [VERIFIED: guides/getting_started.md] [VERIFIED: guides/recipes/generic_saml.md]

Why second: the docs publication and routing should land only after the content and behaviour docs are stable enough to become part of the public docs set. [VERIFIED: mix.exs]

Likely files:
- `mix.exs`
- `guides/recipes/generic_saml.md`
- `README.md` or `guides/getting_started.md` only if cross-linking is needed after execution review. [ASSUMED]

## Architecture Patterns

### Pattern 1: Separate verified identity from host identity

**What:** Treat `Principal` and `LoginResult` as verified SAML facts, and treat the mapped user record as a host-owned application decision layered on top. [VERIFIED: lib/relyra/principal.ex] [VERIFIED: lib/relyra/login_result.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex]

**When to use:** In every pattern section of the guide, especially the JIT flow, so the guide never implies that a verified assertion automatically creates or links a local user without host logic. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: guides/case_studies/phoenix_saas_tenant_onboarding.md]

**Example:**

```elixir
# Source: lib/relyra/phoenix/controllers/acs_controller.ex
case Relyra.consume_response(response_xml, opts) do
  {:ok, login_result} ->
    with {:ok, mapped_user} <-
           Relyra.UserMapper.map_attributes(login_result, login_result.connection, opts),
         {:ok, _session} <-
           Relyra.SessionAdapter.establish_session(mapped_user, login_result, opts) do
      :ok
    end
end
```

### Pattern 2: Use persisted mapping rules only for projection, not transformation

**What:** The durable mapping model supports ordered attribute projection (`source_attribute -> target_field`, `:first` or `:all`) and exact group-value-to-role mapping. It does not support regex/script/expression/template transforms. [VERIFIED: lib/relyra/ecto/attribute_mapping.ex] [VERIFIED: lib/relyra/ecto/group_mapping.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/ecto/mapping_commands.ex]

**When to use:** When documenting the attribute-anchor pattern or “persisted mappings” examples so the guide mirrors what LiveAdmin and Ecto-backed connections can really store. [VERIFIED: lib/relyra/live_admin/mapping_form.ex] [VERIFIED: lib/relyra/connection.ex]

**Example:**

```elixir
# Source: lib/relyra/user_mapper/default_attribute.ex
%{
  attribute_rules: [
    %{source_attribute: "preferred_email", target_field: :email, multivalue_strategy: :first}
  ],
  group_rules: [
    %{source_attribute: "groups", source_value: "admins", role_target: :role, role_value: "admin"}
  ]
}
```

### Pattern 3: Document JIT as host-owned orchestration after mapping

**What:** JIT create-or-update belongs in host code around the mapper/session seam, not inside Relyra core. The guide should show `UserMapper` returning a stable identity map that the host can feed into account lookup/create/update logic before establishing a session. [VERIFIED: README.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/mix/tasks/relyra.install.ex]

**When to use:** In the JIT decision tree and JIT example so the SCIM non-goal and JIT+SCIM conflict warning are concrete rather than abstract. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: README.md]

### Anti-Patterns to Avoid

- **Pretending `UserMapper` is a full provisioning engine:** The behaviour returns `{:ok, map()} | {:error, Error.t()}` and ACS hands the result to `SessionAdapter`; there is no built-in lifecycle engine, sync scheduler, or SCIM orchestration in this seam. [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: README.md]
- **Documenting a cleaner callback contract than the code exposes:** `ACSController` passes `login_result`, while `DefaultAttribute` expects top-level `:attributes` and `:name_id`. The guide and code docs must acknowledge that mismatch instead of hiding it. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: lib/relyra/login_result.ex]
- **Telling operators to anchor on transient or unstable identifiers:** The existing generic SAML and ADFS docs already warn that changing NameID format/source later can change the local identifier. Phase 37 should turn that warning into a first-class anchor-stability section. [VERIFIED: guides/recipes/generic_saml.md] [VERIFIED: guides/recipes/adfs.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Login-time identity mapping examples | A custom mini language for regex, scripts, or template transforms in docs examples | Plain Elixir examples plus the existing persisted mapping primitives (`attribute_rules`, `group_rules`) | The persistence layer explicitly rejects unsupported transform-style keys, so docs that teach richer DSL behavior would be false. [VERIFIED: lib/relyra/ecto/mapping_commands.ex] |
| Provisioning scope | SCIM lifecycle engine in Relyra core or in this guide | Explicit host-owned JIT example and explicit SCIM non-goal statement | The project requirement and README both say SCIM lifecycle stays in the host app; Phase 37 should reinforce that boundary. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: README.md] |
| Support posture | New provider-specific mapping claims in this guide | Cross-links to `guides/recipes/generic_saml.md`, provider runbooks, and host-owned mapping notes | The guide is about identity mapping patterns, not expanding batteries-included provider support. [VERIFIED: README.md] [VERIFIED: guides/getting_started.md] [VERIFIED: guides/recipes/generic_saml.md] |

**Key insight:** The guide is safest when it shows one narrow truth repeatedly: Relyra verifies identity claims and provides mapping seams, but the host application owns user lifecycle decisions and any provisioning source of truth beyond the login event. [VERIFIED: README.md] [VERIFIED: guides/case_studies/phoenix_saas_tenant_onboarding.md] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex]

## Common Pitfalls

### Pitfall 1: Documenting `UserMapper` as if it always receives a raw assertion map

**What goes wrong:** Guide examples read like `assertion.attributes["mail"]`, but the Phoenix ACS success path currently passes a `%Relyra.LoginResult{}` into `UserMapper.map_attributes/3`. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/relyra/user_mapper.ex]

**Why it happens:** The callback type and `DefaultAttribute` implementation were written around a map-shaped assertion input, while the controller now works with the normalized login result. [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: lib/relyra.ex]

**How to avoid:** Make the guide and behaviour docs explicit about the real call sites and choose examples that show how to read from the actual payload used in the documented integration path. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/relyra/login_result.ex]

**Warning signs:** Examples mention `assertion.name_id` directly while the surrounding flow or the controller example uses `login_result.principal.name_id`. [VERIFIED: lib/relyra/login_result.ex] [VERIFIED: lib/relyra/principal.ex]

### Pitfall 2: Overselling persisted mapping as “JIT provisioning”

**What goes wrong:** Operators read `mapping_config` support as if Relyra already creates, updates, or deprovisions application users. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex]

**Why it happens:** The repo has durable attribute/group mapping state, but the actual ACS pipeline still hands control back to host-defined mapper and session seams. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/mix/tasks/relyra.install.ex]

**How to avoid:** Keep a dedicated “Relyra owns / host owns / SCIM non-goal” section in the guide and show JIT as host orchestration after mapping. [VERIFIED: README.md] [VERIFIED: guides/case_studies/phoenix_saas_tenant_onboarding.md]

**Warning signs:** The guide says “Relyra provisions users” instead of “your app can provision on successful login using the verified identity plus mapper output.” [VERIFIED: README.md] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex]

### Pitfall 3: Teaching unstable identity anchors

**What goes wrong:** A team anchors local users on email-style or `unspecified` NameID, then later changes NameID format/source and starts creating duplicate or disconnected accounts. [VERIFIED: guides/recipes/generic_saml.md] [VERIFIED: guides/recipes/adfs.md]

**Why it happens:** Admin UIs often default to convenient-but-mutable identifiers, and the repo’s current docs only warn about this in scattered places. [VERIFIED: guides/recipes/generic_saml.md] [VERIFIED: guides/recipes/adfs.md]

**How to avoid:** Make anchor stability a first-class guide section with explicit “persistent opaque ID safest / email convenient but brittle / transient bad anchor” guidance. [VERIFIED: guides/recipes/generic_saml.md]

**Warning signs:** The chosen anchor can change on rename, tenant merge, or IdP-side format cleanup. [VERIFIED: guides/recipes/generic_saml.md]

### Pitfall 4: Shipping the guide without docs publication and CI gating

**What goes wrong:** The markdown file exists locally but does not ship with ExDoc or can be deleted without a failing docs lane. [VERIFIED: mix.exs] [VERIFIED: guides/identity_mapping_and_provisioning.md missing via shell check on 2026-05-26]

**Why it happens:** `mix.exs` currently publishes `guides/recipes/generic_saml.md` and `guides/recipes/adfs.md`, but there is no Phase 37 guide entry yet. [VERIFIED: mix.exs]

**How to avoid:** Reuse Phase 36’s pattern: add the new guide to ExDoc extras and `ci.docs`. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/36-generic-saml-runbook/36-RESEARCH.md]

**Warning signs:** `mix ci.docs` would still pass if the new guide were missing. [VERIFIED: mix.exs]

## Code Examples

Verified patterns from the repo:

### Host-owned mapper scaffold

```elixir
# Source: lib/mix/tasks/relyra.install.ex
defmodule MyApp.Relyra.UserMapper do
  @behaviour Relyra.UserMapper

  def map_attributes(_assertion, _connection, _opts) do
    {:error, Relyra.Error.new(:adapter_not_configured, "Configure MyApp.Relyra.UserMapper", %{})}
  end
end
```

### Deterministic persisted mapping rules

```elixir
# Source: test/relyra/user_mapper/default_attribute_test.exs
%{
  mapping_config: %{
    attribute_rules: [
      %{source_attribute: "display_name", target_field: :display_name, multivalue_strategy: :all},
      %{source_attribute: "mail", target_field: :email, multivalue_strategy: :first}
    ],
    group_rules: [
      %{source_attribute: "groups", source_value: "staff", role_target: :role, role_value: "staff"},
      %{source_attribute: "groups", source_value: "admins", role_target: :role, role_value: "admin"}
    ]
  }
}
```

### ACS success-path ownership boundary

```elixir
# Source: lib/relyra/phoenix/controllers/acs_controller.ex
{:ok, login_result} = Relyra.consume_response(response_xml, consume_opts)
{:ok, mapped_user} = Relyra.UserMapper.map_attributes(login_result, login_result.connection, opts)
{:ok, _session_result} = Relyra.SessionAdapter.establish_session(mapped_user, login_result, opts)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Scattered implicit mapping guidance in installer scaffolding, fallback mapper code, and generic/provider docs | One authoritative identity-mapping guide plus ExDoc-visible `UserMapper` docs | Planned for Phase 37 in v1.3 roadmap on 2026-05-25. [VERIFIED: .planning/milestones/v1.3-ROADMAP.md] | Reduces support drift and makes the host/Relyra/SCIM boundary explicit. [VERIFIED: README.md] |
| Relying on generic SAML docs for anchor-stability and NameID warnings | Centralize anchor-choice and JIT guidance in a dedicated mapping/provisioning guide | Planned for Phase 37. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: guides/recipes/generic_saml.md] | Operators no longer have to infer identity policy from unrelated setup docs. [VERIFIED: .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**

- Treating the current one-line `Relyra.UserMapper` moduledoc as sufficient public behaviour documentation is outdated once Phase 37 ships; the roadmap now requires explicit documentation with examples. [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Cross-linking from `README.md` or `guides/getting_started.md` may be desirable once the guide exists, but the exact best routing surface should be chosen during execution after reviewing the finished guide. [ASSUMED] | Recommended Phase Split | Low; if wrong, Plan 37-02 still lands by limiting routing changes to `guides/recipes/generic_saml.md`, `mix.exs`, and ExDoc publication only. |

## Resolved Decisions

1. **Phase 37 will tighten `lib/relyra/user_mapper.ex` code docs, but will not change runtime behavior.**
   - Decision: Plan 37-01 owns doc updates in `lib/relyra/user_mapper.ex` so ExDoc and the public behaviour docs describe the real runtime seam the ACS path uses today. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/relyra/user_mapper.ex]
   - Constraint: this is a documentation clarification only, not a public API or behavior change. [VERIFIED: CLAUDE.md]

2. **Persisted mapping remains an implementation technique, not a fourth top-level pattern.**
   - Decision: the guide will keep the roadmap’s three required patterns and explain persisted `mapping_config` as one concrete implementation path inside the attribute-anchor and JIT sections. [VERIFIED: .planning/milestones/v1.3-ROADMAP.md] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | `ci.docs`, `mix test --warnings-as-errors`, ExDoc publication config verification | ✓ [VERIFIED: shell `mix --version` on 2026-05-26] | Mix 1.19.5 [VERIFIED: shell `mix --version` on 2026-05-26] | — |
| `elixir` | test/docs lane execution | ✓ [VERIFIED: shell `elixir --version` on 2026-05-26] | Elixir 1.19.5 / OTP 28 [VERIFIED: shell `elixir --version` on 2026-05-26] | — |

**Missing dependencies with no fallback:** None found in this research pass. [VERIFIED: shell `mix --version` and `elixir --version` on 2026-05-26]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix aliases. [VERIFIED: mix.exs] |
| Config file | none dedicated; project uses `mix test` / alias-driven verification. [VERIFIED: mix.exs] |
| Quick run command | `mix ci.docs` after the guide is added to ExDoc extras and the docs presence gate. [VERIFIED: mix.exs] |
| Full suite command | `mix test --warnings-as-errors`. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-03 | Guide exists with the required pattern/JIT/SCIM/anchor sections | docs presence + grep | `test -f guides/identity_mapping_and_provisioning.md && rg -n "^## (Overview|Relyra owns / Host owns / IdP owns|Three mapping patterns|JIT decision tree|SCIM is a non-goal|JIT \\+ SCIM conflict warning|Anchor stability guidance)$" guides/identity_mapping_and_provisioning.md` [ASSUMED] | ❌ Wave 0 [VERIFIED: guide missing via shell check on 2026-05-26] |
| DOCS-03 | `UserMapper` behaviour is documented with examples grounded in the real seam | docs grep | `rg -n "UserMapper|map_attributes|LoginResult|Principal|SessionAdapter" guides/identity_mapping_and_provisioning.md lib/relyra/user_mapper.ex` [ASSUMED] | ⚠️ Partial: file exists, docs minimal in `lib/relyra/user_mapper.ex` [VERIFIED: lib/relyra/user_mapper.ex] |
| DOCS-03 | Guide is published and fail-closed in docs lane | alias + config grep | `rg -n "guides/identity_mapping_and_provisioning.md" mix.exs && mix ci.docs` [ASSUMED] | ❌ Wave 0 [VERIFIED: mix.exs] |

### Sampling Rate

- **Per task commit:** `mix ci.docs` once the file and gate exist. [VERIFIED: mix.exs]
- **Per wave merge:** `mix test --warnings-as-errors`. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- **Phase gate:** `mix ci.docs` and `mix test --warnings-as-errors` green before `/gsd-verify-work`. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `guides/identity_mapping_and_provisioning.md` — missing entirely today. [VERIFIED: shell file check on 2026-05-26]
- [ ] `mix.exs` ExDoc extras — no entry for the new guide yet. [VERIFIED: mix.exs]
- [ ] `mix.exs` `ci.docs` — no presence gate for the new guide yet. [VERIFIED: mix.exs]
- [ ] `lib/relyra/user_mapper.ex` public docs — current moduledoc/callback docs are too thin for the roadmap’s “fully documented with examples” requirement. [VERIFIED: lib/relyra/user_mapper.ex]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: phase guide covers login-time identity mapping on the auth boundary] | Keep docs aligned with the verified trust path and make clear that only post-verification identity data should drive mapping/provisioning. [VERIFIED: CLAUDE.md] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] |
| V3 Session Management | yes [VERIFIED: ACS flow hands mapped user into `SessionAdapter`] | Document that session establishment is host-owned and happens after mapping. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] |
| V4 Access Control | yes [VERIFIED: group/role mapping affects downstream authorization posture] | Describe role/group mapping as host-policy input and avoid claiming authorization decisions are owned by Relyra. [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: guides/case_studies/phoenix_saas_tenant_onboarding.md] |
| V5 Input Validation | yes [VERIFIED: persisted mapping rules are normalized and bounded] | Keep examples within the supported mapping schema and note that unsupported transform keys are rejected. [VERIFIED: lib/relyra/ecto/mapping_commands.ex] |
| V6 Cryptography | no direct new crypto in this phase [VERIFIED: roadmap scopes this phase to documentation only] | Preserve existing strict-default messaging; do not tell users to weaken signature or algorithm posture. [VERIFIED: CLAUDE.md] [VERIFIED: guides/recipes/generic_saml.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unstable identity anchor causes account-link confusion or duplicate local users | Spoofing / Tampering | Make persistent opaque IDs the safest anchor, explain email/transient risks, and warn that NameID format/source changes are migrations, not cleanup. [VERIFIED: guides/recipes/generic_saml.md] [VERIFIED: guides/recipes/adfs.md] |
| JIT and SCIM both mutate local identity records from different truth sources | Tampering | Add an explicit JIT+SCIM conflict warning and state that one system must own lifecycle truth. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: README.md] |
| Docs imply Relyra performs provisioning or authorization | Repudiation / Elevation of privilege | Keep “Relyra owns / host owns” tables explicit and tie them to ACS + SessionAdapter flow. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: guides/case_studies/phoenix_saas_tenant_onboarding.md] |
| Public docs drift from the actual mapper seam | Repudiation | Improve `UserMapper` docs and add grep-based verification against the guide and behaviour module. [VERIFIED: lib/relyra/user_mapper.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/STATE.md` - active phase, status, and milestone context. [VERIFIED: .planning/STATE.md]
- `.planning/ROADMAP.md` and `.planning/milestones/v1.3-ROADMAP.md` - Phase 37 goal and success criteria. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/milestones/v1.3-ROADMAP.md]
- `.planning/REQUIREMENTS.md` - `DOCS-03` wording and SCIM non-goal anchor. [VERIFIED: .planning/REQUIREMENTS.md]
- `README.md`, `guides/getting_started.md`, `guides/recipes/generic_saml.md`, `guides/recipes/adfs.md`, `guides/jtbd_user_flows.md`, `guides/case_studies/phoenix_saas_tenant_onboarding.md` - current docs posture, support taxonomy, and anchor/provisioning framing. [VERIFIED: README.md] [VERIFIED: guides/getting_started.md] [VERIFIED: guides/recipes/generic_saml.md] [VERIFIED: guides/recipes/adfs.md] [VERIFIED: guides/jtbd_user_flows.md] [VERIFIED: guides/case_studies/phoenix_saas_tenant_onboarding.md]
- `lib/relyra.ex`, `lib/relyra/login_result.ex`, `lib/relyra/principal.ex`, `lib/relyra/user_mapper.ex`, `lib/relyra/user_mapper/default_attribute.ex`, `lib/relyra/phoenix/controllers/acs_controller.ex`, `lib/mix/tasks/relyra.install.ex` - runtime mapper/session seam and host-scaffold contract. [VERIFIED: lib/relyra.ex] [VERIFIED: lib/relyra/login_result.ex] [VERIFIED: lib/relyra/principal.ex] [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: lib/mix/tasks/relyra.install.ex]
- `lib/relyra/connection.ex`, `lib/relyra/ecto/attribute_mapping.ex`, `lib/relyra/ecto/group_mapping.ex`, `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/live_admin/mapping_form.ex` - persisted mapping semantics and limits. [VERIFIED: lib/relyra/connection.ex] [VERIFIED: lib/relyra/ecto/attribute_mapping.ex] [VERIFIED: lib/relyra/ecto/group_mapping.ex] [VERIFIED: lib/relyra/ecto/connection_snapshot.ex] [VERIFIED: lib/relyra/ecto/mapping_commands.ex] [VERIFIED: lib/relyra/live_admin/mapping_form.ex]
- `mix.exs` - ExDoc extras and `ci.docs` gate shape. [VERIFIED: mix.exs]
- `test/relyra/user_mapper/default_attribute_test.exs`, `test/phoenix/acs_controller_test.exs`, `test/relyra/telemetry_test.exs`, `test/mix/relyra_install_test.exs` - observed behavior and current test coverage around mapping, ACS flow, telemetry, and install scaffolding. [VERIFIED: test/relyra/user_mapper/default_attribute_test.exs] [VERIFIED: test/phoenix/acs_controller_test.exs] [VERIFIED: test/relyra/telemetry_test.exs] [VERIFIED: test/mix/relyra_install_test.exs]

### Secondary (MEDIUM confidence)

- `.planning/phases/36-generic-saml-runbook/36-RESEARCH.md` - prior docs-phase split pattern reused as an execution model, not as an authority for current runtime facts. [VERIFIED: .planning/phases/36-generic-saml-runbook/36-RESEARCH.md]

### Tertiary (LOW confidence)

- None. All substantive claims in this research were verified against the live repo except the explicitly flagged routing assumption in A1 and the proposed grep headings in validation commands. [VERIFIED: current research file content]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 37 reuses existing repo-native docs, ExDoc, Mix aliases, and mapper seams already present in the codebase. [VERIFIED: mix.exs] [VERIFIED: lib/relyra/user_mapper.ex]
- Architecture: HIGH - The ACS and mapping flow is explicit in code and tests. [VERIFIED: lib/relyra/phoenix/controllers/acs_controller.ex] [VERIFIED: test/phoenix/acs_controller_test.exs]
- Pitfalls: HIGH - The guide risks come directly from visible code/docs mismatches and missing docs-gate surfaces. [VERIFIED: lib/relyra/user_mapper.ex] [VERIFIED: lib/relyra/user_mapper/default_attribute.ex] [VERIFIED: mix.exs]

**Research date:** 2026-05-26
**Valid until:** 2026-06-25 for repo-internal facts unless Phase 37 implementation changes the mapper docs contract or docs publication surfaces first. [VERIFIED: current repo state]
