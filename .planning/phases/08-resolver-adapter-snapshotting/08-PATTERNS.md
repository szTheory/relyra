# Phase 08: Resolver adapter + snapshotting - Patterns

**Mapped:** 2026-05-05
**Scope:** resolver behaviours/adapters, optional Ecto adapter posture, tuple-typed diagnostics, runtime snapshot construction, and adjacent plan granularity.

## Primary analogs

| Target concern | Closest analog | Why it matters |
|---|---|---|
| Public resolver seam | `lib/relyra/connection_resolver.ex:1-82` | Existing behaviour, adapter dispatch, tuple hardening, and fail-closed wrapper logic. |
| Default internal adapter | `lib/relyra/connection_resolver/default.ex:1-23` | Pattern for thin internal defaults with `@moduledoc false` and typed `:adapter_not_configured` failures. |
| Optional Ecto boundary | `lib/relyra/ecto/connections.ex:9-179` | Current host-Repo, optional-dependency, and typed persistence-error style to reuse for a resolver adapter. |
| Runtime readiness gate | `lib/relyra/ecto/connection.ex:103-149` | Existing bounded failure reasons for non-runnable persisted rows. |
| Runtime value object | `lib/relyra/connection.ex:5-43` | Canonical snapshot shape Phase 08 should construct. |
| Error envelope and redaction | `lib/relyra/error.ex:6-58` | Stable tuple payload and operator-safe diagnostics shape. |
| Runtime defaults merge | `lib/relyra/provider.ex:112-131` | Existing “defaults under user config” merge style for snapshot normalization. |
| Compatibility resolver fixtures | `test/support/fake_connection_resolver.ex:5-20` | Current resolver consumers still accept plain maps and currently rely on `cert_chain`. |

## Concrete reusable patterns

### 1. Keep the public resolver wrapper thin and defensive

Copy the shape from `lib/relyra/connection_resolver.ex:18-47`:

```elixir
@callback resolve_connection(request_context :: map(), opts :: keyword()) ::
            {:ok, map()} | {:error, Error.t()}

case adapter.resolve_connection(request_context, opts) do
  {:ok, connection} when is_map(connection) -> {:ok, connection}
  {:error, %Error{} = error} -> {:error, error}
  other -> {:error, invalid_adapter_result(adapter, :resolve_connection, other)}
end
```

Planner guidance:
- Keep `Relyra.ConnectionResolver.Ecto` as an internal adapter behind this seam, not a new public entrypoint.
- Adapter output should remain `{:ok, %Relyra.Connection{}} | {:error, %Relyra.Error{}}`; avoid leaking Ecto structs or raw `{:error, atom}`.
- If Phase 08 updates the moduledoc contract from `:cert_chain` toward `:idp_certificates`, do it in the public seam docs and fixture expectations together.

### 2. Follow the repo’s optional Ecto adapter posture

Copy the sequence from `lib/relyra/ecto/connections.ex:12-17`, `:93-119`, `:121-158`:

```elixir
with {:ok, repo} <- fetch_repo(opts, :create),
     :ok <- ensure_optional_dependency!(:create, repo) do
  ...
end
```

```elixir
Error.new(:adapter_not_configured, ..., error_details(opts, operation, :missing_repo))
Error.new(:optional_dependency_missing, ..., repo_details(repo, operation, :ecto_unavailable))
```

Planner guidance:
- The Ecto-backed resolver should require `opts[:repo]` exactly like existing Ecto integrations.
- Keep Ecto capability checks at the adapter edge.
- Put preload/query logic in a persistence-side module under `Relyra.Ecto.*`; keep request-context orchestration in the resolver adapter.
- The most natural split is:
  - `lib/relyra/connection_resolver/ecto.ex`: resolver adapter, request-context in, typed result out.
  - `lib/relyra/ecto/connection_hydrator.ex` or `lib/relyra/ecto/connection_snapshot.ex`: aggregate preload + runtime mapping.

### 3. Reuse the existing readiness taxonomy instead of inventing a second gate

`lib/relyra/ecto/connection.ex:111-147` already encodes the persisted aggregate gate:

```elixir
connection.status != :enabled -> reason: :not_enabled
missing_fields != [] -> %{missing: missing_fields}
Enum.empty?(connection.certificates || []) -> %{reason: :missing_certificates}
Enum.any?(connection.certificates, &invalid_certificate?/1) -> %{reason: :invalid_certificates}
```

Planner guidance:
- Phase 08 should map these readiness failures into resolver-facing errors, not duplicate the checks in controllers or protocol code.
- Keep the public resolver taxonomy small, with the detailed cause in `details.reason` and `details.missing`.
- Likely mapping:
  - aggregate missing row -> `type: :connection_unavailable`, `details.reason: :not_found`
  - draft/disabled/unready row -> `type: :connection_unavailable` or `:connection_invalid`, with `details.reason` from readiness
  - hydration/mapping bug -> `type: :resolver_failed`, `details.reason: :hydration_failed`
  - repo misconfiguration -> `type: :resolver_misconfigured`, `details.reason: :missing_repo` or `:repo_misconfigured`

### 4. Construct one canonical runtime snapshot object

`lib/relyra/connection.ex:5-43` is the Phase 08 target shape:

```elixir
defstruct [
  :id,
  :connection_id,
  :idp_entity_id,
  :sp_entity_id,
  :acs_url,
  :idp_sso_url,
  :idp_certificates,
  :cert_chain,
  :name_id_format,
  :algorithm_policy,
  :allow_idp_initiated?,
  :require_signed_assertions?,
  :require_signed_response?,
  :clock_skew_seconds,
  :provider_preset,
  :display_name,
  :organization_id
]
```

Planner guidance:
- The hydrator should return `%Relyra.Connection{}` directly, not a partially normalized map.
- Make `idp_certificates` the canonical populated runtime field.
- Keep `cert_chain` as compatibility fill-in only if current consumers still require it.
- Centralize all derived/defaulted runtime fields in one constructor function.

### 5. Apply provider defaults during snapshot construction, not later

`lib/relyra/provider.ex:118-131` shows the established defaulting pattern:

```elixir
defaults = module.default_config()

Keyword.merge(defaults, user_config, fn _key, default_value, user_value ->
  merge_value(default_value, user_value)
end)
```

Planner guidance:
- Snapshot normalization should be the only place that expands `provider_preset` defaults into runtime fields.
- Preserve the current semantics: defaults fill gaps, explicit persisted values win, nested maps merge deeply.
- Likely touchpoint: build a map/keyword from the Ecto aggregate, run preset default expansion, then instantiate `%Relyra.Connection{}`.

### 6. Keep diagnostics typed, structured, and redactable

`lib/relyra/error.ex:15-18` and `:38-58` define the contract:

```elixir
%__MODULE__{type: type, message: message, details: details}
```

```elixir
details
|> Map.drop([:xml, :response_xml, :assertion_xml, :signed_xml, :relay_state])
|> Map.delete(:sensitive)
```

Planner guidance:
- Resolver errors should always include structured fields such as `connection_id`, `operation`, `reason`, and `missing` when applicable.
- Keep `details` machine-readable and redaction-safe; do not stash PEM blobs, XML, or raw metadata payloads there.
- Prefer stable top-level types with granular `details.reason`.

## Likely Phase 08 touchpoints

| File | Expected role in Phase 08 |
|---|---|
| `lib/relyra/connection_resolver.ex` | Update docs/types if the canonical runtime contract shifts from `cert_chain` to `idp_certificates`. |
| `lib/relyra/connection_resolver/ecto.ex` | New thin public-facing adapter implementation. |
| `lib/relyra/ecto/connections.ex` | Possible reuse point for aggregate fetch helpers, but avoid overloading this CRUD module with snapshot normalization. |
| `lib/relyra/ecto/connection.ex` | Source of readiness checks and persisted field shape. |
| `lib/relyra/connection.ex` | Runtime snapshot target; may need compatibility doc cleanup, not structural churn. |
| `lib/relyra/provider.ex` | Source of preset default expansion semantics. |
| `test/support/fake_connection_resolver.ex` | Update fixture shape alongside any runtime field contract change. |

## Naming guidance

- Prefer `Relyra.ConnectionResolver.Ecto` for the adapter. That matches the existing public behaviour naming and the Phase 08 decision.
- Prefer an internal helper name that describes the one-way transform, such as `Relyra.Ecto.ConnectionHydrator` or `Relyra.Ecto.ConnectionSnapshot`.
- Avoid names like `Repository`, `Manager`, or `Service` here; the codebase currently names seams by domain and role.

## Task-shaping guidance for the planner

Adjacent phases already use 3-task slices with narrow file groups and explicit verification:
- Public seam first: see `03-01-PLAN.md:25-48` and `:51-127`.
- Adapter implementation second: see `03-02-PLAN.md:27-61` and `:64-143`.
- Orchestration/integration plus tests last: see `03-03-PLAN.md:24-56` and `:59-131`.
- Aggregate/runtime split before resolver hydration: see `07-03-PLAN.md:21-49` and `:52-145`.

Recommended Phase 08 breakdown:

1. **Resolver contract + diagnostics update**
   - Files: `lib/relyra/connection_resolver.ex`, `lib/relyra/connection_resolver/default.ex`, contract tests.
   - Goal: lock the canonical runtime field docs and bounded resolver error taxonomy before adapter code lands.

2. **Ecto adapter + hydrator implementation**
   - Files: `lib/relyra/connection_resolver/ecto.ex`, one new `lib/relyra/ecto/*hydrator*.ex` module, targeted tests.
   - Goal: load aggregate, enforce readiness, normalize defaults, return `%Relyra.Connection{}`.

3. **Runtime integration + compatibility tests**
   - Files: resolver fixture/tests and any login/metadata-path tests touched by the new snapshot contract.
   - Goal: prove login and metadata consumers both read the same normalized snapshot and that compatibility glue for `cert_chain` remains intentional.

## Guardrails

- Do not let protocol/runtime modules consume Ecto structs directly.
- Do not spread defaulting logic across login, metadata, and protocol code.
- Do not create a second independent runtime-readiness implementation.
- Do not expand the public error taxonomy into many top-level atoms; keep precision in `details.reason`.
- Do not make Ecto mandatory for non-Ecto adopters.
