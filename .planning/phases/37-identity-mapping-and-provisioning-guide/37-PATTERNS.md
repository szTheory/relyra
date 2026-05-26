# Phase 37: Identity Mapping and Provisioning Guide - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 5 likely modified files + supporting references
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `guides/identity_mapping_and_provisioning.md` | guide | transform | `guides/recipes/generic_saml.md` | exact |
| `README.md` | guide | transform | `README.md` custom-SAML and Day-2 routing sections | exact |
| `guides/getting_started.md` | guide | transform | `guides/getting_started.md` provider-routing and production-follow-ons sections | exact |
| `lib/relyra/user_mapper.ex` | code-doc | transform | `lib/relyra/user_mapper.ex` public behaviour docs plus `lib/mix/tasks/relyra.install.ex` scaffold contract | exact |
| `mix.exs` | config | batch | `mix.exs` `ci.docs` alias entries for `guides/recipes/adfs.md` and `guides/recipes/generic_saml.md` | exact |

## Pattern Assignments

### `guides/identity_mapping_and_provisioning.md` (guide, transform)

**Primary analog:** `guides/recipes/generic_saml.md`

**Plan structure to copy from Phase 36** (`.planning/phases/36-generic-saml-runbook/36-01-PLAN.md:21-49`, `125-130`; `36-02-PLAN.md:21-46`, `122-127`)

```md
must_haves:
  truths:
    - "guide contains the full requirement payload"
  artifacts:
    - path: "guides/..."
      provides: "Authoritative operator guide"
      contains: "## Exact required section"
  key_links:
    - from: "guide"
      to: "supporting file"
      via: "why the link exists"
      pattern: "grep-able anchor"
```

Use the same two-plan docs split as Phase 36:
- Plan 01 for routing + core guide skeleton.
- Plan 02 for advanced decision content + `ci.docs` gate.

**Guide opening and support-posture pattern** (`guides/recipes/generic_saml.md:1-11`)

```md
# Generic SAML + Relyra

This is the canonical fallback runbook...
Use it only after the local `FakeIdP` proof...

Relyra's batteries-included support still stops at ...
```

Phase 37 should open the same way: name the guide as authoritative, state when to use it, and state what it does **not** expand.

**Ownership-boundary pattern** (`guides/recipes/generic_saml.md:32-55`; `guides/case_studies/phoenix_saas_tenant_onboarding.md:21-32`)

```md
## Relyra owns / IdP owns / Host owns

## Relyra owns
- ...

## Host owns
- ...
```

For Phase 37, replace `IdP owns` with the seam that matters for mapping/provisioning:
- `Relyra owns`
- `Host owns`
- optionally `Identity source owns` only if it adds clarity

**Decision-guide and example pattern** (`guides/recipes/generic_saml.md:57-108`, `168-203`)

```md
| Relyra seam | What it means | Where it shows up |
| --- | --- | --- |

Operator notes:
- ...

Observable triggers:
- ...
```

Use tables for the three canonical mapping patterns and the JIT decision tree. Follow with short operator notes, not long prose.

**Warning style** (`guides/recipes/generic_saml.md:205-243`; `guides/recipes/adfs.md:83-99`; `README.md:66-72`)

```md
- Do not ...
- Keep ... enabled ...
- Treat ... as separate concerns ...
```

Warnings are expressed as direct bullets, not admonition blocks. The repo uses plain-language fail-closed wording like "Do not..." and "Keep ...".

**Behaviour example pattern** (`lib/relyra/user_mapper.ex:1-40`; `lib/relyra/user_mapper/default_attribute.ex:5-18`, `27-50`; `lib/mix/tasks/relyra.install.ex:175-186`)

```elixir
@callback map_attributes(assertion :: map(), connection :: map(), opts :: keyword()) ::
            {:ok, map()} | {:error, Error.t()}

def map_attributes(_assertion, _connection, _opts) do
  {:error, Relyra.Error.new(:adapter_not_configured, "Configure MyApp.Relyra.UserMapper", %{})}
end
```

Document `UserMapper` from the public callback first, then show:
- installer-generated stub as the "start here" example
- `DefaultAttribute` as the concrete default mapping example

**Concrete mapping-pattern excerpts** (`lib/relyra/user_mapper/default_attribute.ex:27-35`, `37-50`, `52-105`)

```elixir
%{
  name_id: Map.get(assertion, :name_id),
  email: get_attribute(attributes, ["email", "mail", "EmailAddress"]),
  first_name: get_attribute(attributes, ["given_name", "givenname", "FirstName"]),
  last_name: get_attribute(attributes, ["family_name", "sn", "LastName"]),
  roles: get_attribute(attributes, ["groups", "roles", "memberOf"]) || []
}
```

This is the exact pattern to cite when explaining:
- NameID-as-local-id
- attribute-as-local-id
- persisted mapping rules and `:first` / `:all`

### `README.md` (guide, transform)

**Analog:** `README.md`

**Routing pattern** (`README.md:41-53`, `74-85`)

```md
## Custom SAML And Not-Yet-Shipped Providers

- **Custom SAML:** ... [guide link]
- **Specialized fallback:** ...
- **Not yet shipped:** ...

## Day-2 And Operator Guides
- [Getting Started](...)
- [Jobs To Be Done And User Flows](...)
```

If Phase 37 updates `README.md`, follow this exact pattern: add the new guide under Day-2/operator surfaces, not under batteries-included provider routing.

**Non-goal wording pattern** (`README.md:66-72`)

```md
## What Does Not Ship

- SCIM lifecycle ownership.
```

Use this wording as the base for the guide's SCIM non-goal statement.

### `guides/getting_started.md` (guide, transform)

**Analog:** `guides/getting_started.md`

**Production-follow-ons routing pattern** (`guides/getting_started.md:127-155`)

```md
## 5. Production follow-ons

Recommended order:
1. ...

Useful follow-on references:
- [Jobs To Be Done And User Flows](...)
```

If Phase 37 modifies this file, add the identity-mapping guide only as a follow-on reference after the first provider path works.

**Taxonomy pattern** (`guides/getting_started.md:109-122`)

```md
- **Batteries included:** ...
- **Custom SAML:** ...
- **ADFS special case:** ...
- **Not yet shipped:** ...
```

Do not turn the mapping/provisioning guide into a Day-1 provider branch. Keep it in the post-login operator path.

### `lib/relyra/user_mapper.ex` (code-doc, transform)

**Analog:** `lib/relyra/user_mapper.ex` plus the installer-generated adapter stub in `lib/mix/tasks/relyra.install.ex`

**Behaviour-doc pattern**

```elixir
@moduledoc """
Public extension contract for ...
"""

@callback map_attributes(...) :: {:ok, map()} | {:error, Error.t()}
```

Phase 37 should keep runtime unchanged but make the code docs explicit about the real seam the ACS path uses: verified login result in, host-shaped user map out, session establishment later.

**Scaffold-contract pattern**

```elixir
defmodule MyApp.Relyra.UserMapper do
  @behaviour Relyra.UserMapper

  def map_attributes(_assertion, _connection, _opts) do
    {:error, Relyra.Error.new(:adapter_not_configured, ...)}
  end
end
```

Use this as the model for what “complete example” means in the guide: a host-owned adapter module, not abstract pseudocode.

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**Docs gate pattern** (`mix.exs:143-150`)

```elixir
"ci.docs": [
  "cmd test -f guides/batteries_included.md",
  "cmd test -f BATTERIES_INCLUDED.md",
  "cmd test -f guides/recipes/adfs.md",
  "cmd test -f guides/recipes/generic_saml.md",
  ...
]
```

Phase 37 should add:

```elixir
"cmd test -f guides/identity_mapping_and_provisioning.md"
```

No stronger content gate is established for docs. Presence check + existing docs tests is the current repo pattern.

## Shared Patterns

### Plan Anatomy
**Sources:** `.planning/phases/36-generic-saml-runbook/36-01-PLAN.md:1-167`, `.planning/phases/36-generic-saml-runbook/36-02-PLAN.md:1-166`

Use the full Phase 36 plan skeleton:
- YAML front matter with `files_modified`, `requirements`, `tags`
- `must_haves` split into `truths`, `artifacts`, `key_links`
- `<objective>`, `<context>`, `<tasks>`, `<threat_model>`, `<verification>`, `<success_criteria>`
- task-level `<verify><automated>...</automated></verify>` commands

### Operator Guide Markdown
**Sources:** `guides/recipes/generic_saml.md:13-243`, `guides/recipes/adfs.md:3-102`

Cross-cutting markdown idioms:
- top-level authoritative opening with explicit usage boundary
- optional provenance/testing blockquote at top for dated claims
- H2 sections with plain-English titles
- compact comparison/decision tables
- direct warning bullets using "Do not..." / "Keep ..."
- `Receipt:` or `Proof receipt:` lines at the end of major branches

### Behaviour Documentation
**Sources:** `lib/relyra/user_mapper.ex:1-40`, `lib/relyra/user_mapper/default_attribute.ex:27-105`, `lib/mix/tasks/relyra.install.ex:175-186`

For `UserMapper` docs:
- show the callback signature first
- show the generated stub second
- show one complete working example third
- keep examples tied to real assertion fields: `:name_id`, `:attributes`, `mapping_config`

### Routing and Scope Honesty
**Sources:** `README.md:41-53`, `66-72`, `74-85`; `guides/getting_started.md:109-122`, `127-155`

Keep the same docs posture as Phase 36:
- narrow support claims
- route readers into the right guide rather than broadening batteries-included claims
- place advanced/operator docs after Day-1 success, not before it

## Recommended Non-Guide Modifications For Phase 37

Likely modify these besides `guides/identity_mapping_and_provisioning.md`:

| File | Why |
|------|-----|
| `mix.exs` | Match Phase 36 and add a `ci.docs` presence gate for the new guide |
| `README.md` | Add the new guide under `## Day-2 And Operator Guides`; SCIM non-goal wording already lives here |
| `guides/getting_started.md` | Add the guide to `## 5. Production follow-ons` rather than Day-1 routing |
| `guides/jtbd_user_flows.md` | Best existing narrative surface for host-owned mapping/provisioning responsibility |

Secondary/optional only if the planner wants stronger cross-linking:

| File | Why |
|------|-----|
| `guides/case_studies/phoenix_saas_tenant_onboarding.md` | Already names tenant provisioning as host-owned; could link the guide, but not required |

Files that look relevant but are better treated as read-only references:

| File | Reason to leave untouched |
|------|---------------------------|
| `lib/relyra/user_mapper.ex` | Public seam to document, not change, in a docs-only phase |
| `lib/relyra/user_mapper/default_attribute.ex` | Best example source for mapping patterns |
| `lib/mix/tasks/relyra.install.ex` | Best source for the generated `UserMapper` stub example |

## Verification Patterns

Use the same docs-only verification shape as Phase 36:

- `rg -n "^## Overview$|^## Relyra owns$|^## Host owns$|^## Mapping patterns$|^## JIT decision tree$|^## UserMapper behaviour$|^## SCIM boundary$" guides/identity_mapping_and_provisioning.md`
- `rg -n "NameID|attribute-as-local|JIT|UserMapper|SCIM|provision" guides/identity_mapping_and_provisioning.md`
- `rg -n "guides/identity_mapping_and_provisioning.md" README.md guides/getting_started.md guides/jtbd_user_flows.md mix.exs`
- `mix ci.docs`
- `mix test --warnings-as-errors`

If `mix.exs` is untouched, `mix test --warnings-as-errors` is optional but still consistent with Phase 36.

## No Analog Found

None. Phase 37 has strong local analogs for planning, guide structure, routing, CI gating, and `UserMapper` examples.

## Metadata

**Analog search scope:** `.planning/phases/36-generic-saml-runbook/`, `README.md`, `guides/`, `lib/relyra/user_mapper*.ex`, `lib/mix/tasks/relyra.install.ex`, `mix.exs`
**Files scanned:** 16
**Pattern extraction date:** 2026-05-26
