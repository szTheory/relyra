# Phase 07: Schema + connection aggregate - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 8 implied new/modified targets
**Analogs found:** 6 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/relyra/ecto/connection.ex` | schema/model | CRUD | `lib/relyra/connection.ex` | data-flow-match |
| `lib/relyra/ecto/certificate.ex` | schema/model | CRUD | `lib/relyra/connection.ex` | partial |
| `lib/relyra/ecto/connection_state.ex` or embedded policy modules | schema/model | transform | `lib/relyra/provider.ex` | role-match |
| `priv/repo/migrations/*_create_relyra_connections.exs` | migration | CRUD | none in repo; use `.planning/research/STACK.md` + `ARCHITECTURE.md` | none |
| `priv/repo/migrations/*_create_relyra_connection_certificates.exs` | migration | CRUD | none in repo; use `.planning/research/STACK.md` + `ARCHITECTURE.md` | none |
| `lib/relyra/connection_resolver.ex` | public boundary update | request-response | `lib/relyra/connection_resolver.ex` | exact |
| `test/relyra/ecto/*_test.exs` | test | CRUD | `test/security/stores/request_store_ecto_test.exs` | role-match |
| `test/relyra/*validation*_test.exs` | test | request-response | `test/protocol/consume_response_pipeline_test.exs` | exact |

## Pattern Assignments

### `lib/relyra/ecto/connection.ex`

**Use as primary analogs**
- Runtime snapshot shape: `lib/relyra/connection.ex` lines 5-21, 24-41
- Resolver contract that this schema must feed: `lib/relyra/connection_resolver.ex` lines 3-19
- Runtime fallback behavior to preserve during transition: `lib/relyra.ex` lines 268-280, 319-329

**Snapshot field contract to preserve** (`lib/relyra/connection.ex:5-21`)
```elixir
defstruct [
  :id,
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

**Boundary rule** (`lib/relyra/connection_resolver.ex:3-19`)
```elixir
The returned connection map is consumed by protocol core and must include:

- `:connection_id`
- `:idp_entity_id`
- `:sp_entity_id`
- `:acs_url`
- `:idp_sso_url`
- `:cert_chain`
```

**Resolver handoff pattern** (`lib/relyra.ex:268-280`)
```elixir
request_context = %{
  connection_id: Map.get(request_intent, :connection_id),
  organization_id: Map.get(request_intent, :organization_id)
}

ConnectionResolver.resolve_connection(request_context, opts)
```

**What to copy**
- Keep the persisted schema internal under `Relyra.Ecto.*`; hydrate to plain `%Relyra.Connection{}` later.
- Keep both identifiers explicit: internal DB PK and public `connection_id`.
- Keep compact runtime-ready fields on the connection aggregate; keep lifecycle-heavy trust rows separate.

**Anti-pattern to avoid**
- Do not make runtime consume schema structs directly. `ARCHITECTURE.md:142-146` explicitly rejects passing Ecto structs into protocol code.

### `lib/relyra/ecto/certificate.ex`

**Use as primary analogs**
- Trust consumer expectations: `lib/relyra/security/signature.ex` lines 47-77, 137-145
- Metadata/runtime fallback chain: `lib/relyra/protocol/validation_pipeline.ex` lines 174-181
- Architecture warning against single-cert storage: `.planning/research/ARCHITECTURE.md` lines 154-158

**Fail-closed trust check** (`lib/relyra/security/signature.ex:51-61`)
```elixir
cond do
  cert_chain == [] ->
    {:error,
     Error.new(:untrusted_certificate, "Configured certificate chain is required", details)}

  Map.get(parsed_doc, :key_info_trust) == true ->
    {:error,
     Error.new(
       :untrusted_certificate,
       "Document-provided KeyInfo cannot be used as a trust source",
       Map.put(details, :reason, :document_keyinfo_forbidden)
     )}
```

**Resolver/runtime cert lookup order** (`lib/relyra/protocol/validation_pipeline.ex:174-177`)
```elixir
Keyword.get(opts, :cert_chain) || Map.get(connection, :cert_chain) ||
  Map.get(connection, :idp_certificates) || []
```

**What to copy**
- Certificate rows should be additive inventory, not a replace-in-place blob.
- Model provenance/basic metadata now so later rollover/import phases extend rows instead of rewriting the aggregate.
- The hydration layer should produce plain PEM lists for runtime, matching `:cert_chain` / `:idp_certificates`.

### `lib/relyra/connection_resolver.ex` and future internal Ecto adapter seam

**Use as primary analogs**
- Public-vs-internal seam: `lib/relyra/connection_resolver.ex` lines 21-47
- Default internal adapter: `lib/relyra/connection_resolver/default.ex` lines 1-22
- Installer skeleton naming/layout: `lib/mix/tasks/relyra.install.ex` lines 96-107

**Public wrapper dispatch pattern** (`lib/relyra/connection_resolver.ex:21-47`)
```elixir
def resolve_connection(request_context, opts)
    when is_map(request_context) and is_list(opts) do
  adapter = connection_resolver(opts)

  if is_atom(adapter) and Code.ensure_loaded?(adapter) and
       function_exported?(adapter, :resolve_connection, 2) do
    try do
      case adapter.resolve_connection(request_context, opts) do
        {:ok, connection} when is_map(connection) -> {:ok, connection}
        {:error, %Error{} = error} -> {:error, error}
        other -> {:error, invalid_adapter_result(adapter, :resolve_connection, other)}
      end
```

**Default fail-closed adapter** (`lib/relyra/connection_resolver/default.ex:10-21`)
```elixir
{:error,
 Error.new(
   :adapter_not_configured,
   "Connection resolver adapter is not configured",
   %{
     adapter: __MODULE__,
     operation: :resolve_connection,
     hint:
       "Set :connection_resolver in Relyra options to a module implementing Relyra.ConnectionResolver."
   }
 )}
```

**What to copy**
- Public module owns callback/spec/dispatch/error-shaping.
- Internal adapter modules keep `@moduledoc false`, implement the behaviour, and never leak Ecto types across the boundary.
- Any new aggregate validation API should return `{:ok, map_or_struct}` or `{:error, %Relyra.Error{}}`, not `raise` / bare `{:error, atom}`.

### Optional Ecto-backed adapter modules

**Use as primary analogs**
- `lib/relyra/request_store.ex` lines 20-40, 47-99
- `lib/relyra/request_store/ecto.ex` lines 16-20, 79-107, 255-351
- `lib/relyra/replay_store/ecto.ex` lines 16-20, 33-61, 64-145
- `mix.exs` lines 44-55

**Optional dependency posture** (`mix.exs:44-55`)
```elixir
{:ecto, "~> 3.13", optional: true},
{:ecto_sql, "~> 3.13", optional: true},
{:postgrex, ">= 0.0.0", optional: true}
```

**Host-app Repo boundary** (`lib/relyra/request_store/ecto.ex:255-266`)
```elixir
case Keyword.fetch(opts, :repo) do
  {:ok, repo} when is_atom(repo) ->
    {:ok, repo}

  _ ->
    {:error,
     Error.new(
       :request_intent_not_found,
       "opts[:repo] is required for Ecto request-store operations",
       error_details(opts, operation, :missing_repo)
     )}
end
```

**Fail-closed optional dependency check** (`lib/relyra/request_store/ecto.ex:288-297`)
```elixir
if Code.ensure_loaded?(@ecto_repo) do
  :ok
else
  {:error,
   Error.new(
     :optional_dependency_missing,
     "Ecto.Repo is unavailable; add optional Ecto dependencies before using this adapter",
     repo_details(repo, table, operation, :ecto_repo_unavailable)
   )}
end
```

**What to copy**
- Never define a library-owned Repo.
- Require `opts[:repo]`; accept host-app table or schema ownership as configuration.
- Convert every adapter misconfiguration or SQL-path failure into typed `Relyra.Error`.
- Prefer capability checks and result normalization at the boundary.

**Anti-pattern to avoid**
- Do not let Ecto become a hard dependency for non-Ecto users. The existing repo treats Ecto/Postgrex as optional integrations.

### Validation and lifecycle tests

**Use as primary analogs**
- Typed-result contract tests: `test/protocol/consume_response_pipeline_test.exs` lines 117-132, 177-180
- Extension boundary tests: `test/relyra_test.exs` lines 165-206, 208-239
- Ecto concurrency tests: `test/security/stores/request_store_ecto_test.exs` lines 16-48 and `test/security/stores/replay_store_ecto_test.exs` lines 16-56

**Typed error contract pattern** (`test/relyra_test.exs:179-205`)
```elixir
assert {:error, %Relyra.Error{type: :adapter_not_configured}} =
         Relyra.ConnectionResolver.Default.resolve_connection(%{}, [])

assert {:error, %Relyra.Error{} = request_put_error} =
         Relyra.RequestStore.Default.put_intent("rs_123", %{request_id: "id_123"}, [])
```

**Concurrency/uniqueness pattern** (`test/security/stores/request_store_ecto_test.exs:23-44`)
```elixir
results =
  1..12
  |> Task.async_stream(
    fn _ ->
      Ecto.consume_intent(relay_state, request_id, repo: @repo, table: @table)
    end,
    max_concurrency: 12,
    ordered: false,
    timeout: 5_000
  )
  |> Enum.map(fn {:ok, result} -> result end)
```

**What to copy**
- Write validation tests around state transitions and runtime eligibility as tuple-contract tests.
- Write at least one concurrency/uniqueness test for public `connection_id` and certificate duplication invariants.
- Use fake in-memory Repo modules for adapter-contract tests when full DB infrastructure is not present yet.

## Shared Patterns

### Typed Errors
**Source:** `lib/relyra/error.ex`
**Apply to:** all schemas/validators/adapters exposed outside the Ecto namespace

`lib/relyra/error.ex:15-18`
```elixir
@spec new(atom(), String.t(), map()) :: t()
def new(type, message, details \\ %{}) do
  %__MODULE__{type: type, message: message, details: details}
end
```

`lib/relyra/error.ex:38-46`
```elixir
details
|> Map.drop([:xml, :response_xml, :assertion_xml, :signed_xml, :relay_state])
|> Map.delete(:sensitive)
```

Planner note: include enough error details for operators and tests, but keep details redactable and non-secret.

### Public vs Internal Module Boundary
**Source:** `lib/relyra/request_store.ex`, `lib/relyra/request_store/ecto.ex`, `lib/relyra/connection_resolver/default.ex`
**Apply to:** any new `Relyra.Ecto.*` modules plus future `Relyra.ConnectionResolver.Ecto`

Pattern:
- Public behaviour/dispatcher in top-level `Relyra.*`.
- Concrete implementation in submodule.
- Concrete implementation uses `@moduledoc false`.
- Public layer normalizes adapter return values and rescues/catches misbehavior.

### Runtime Snapshot Contract
**Source:** `lib/relyra.ex`, `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra/security/signature.ex`
**Apply to:** aggregate hydration and runtime-readiness validation

Pattern:
- Request-time resolver input is a plain map with `connection_id` and optional `organization_id`.
- Runtime consumers read plain map fields and often fallback between `:connection_id` and `:id`.
- Hydration should normalize once so later phases stop relying on fallback ambiguity.

### Test Layout
**Source:** `test/security/stores/*`, `test/protocol/consume_response_pipeline_test.exs`
**Apply to:** schema changeset tests, aggregate validation tests, adapter tests

Pattern:
- Store/adapter tests live under focused subdirectories.
- Fake repo/test seam modules can live in the same test file when tightly coupled.
- Assertions focus on typed error atoms and exact invariant behavior, not generic truthiness.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `priv/repo/migrations/*_create_relyra_connections.exs` | migration | CRUD | Repo has no existing `priv/repo` or migration files. Follow `.planning/research/STACK.md:13-16,58` and `ARCHITECTURE.md:42-46,52-60`. |
| `priv/repo/migrations/*_create_relyra_connection_certificates.exs` | migration | CRUD | Same gap: no host-app migration precedent exists inside the library repo yet. |

## Anti-Patterns To Avoid In This Phase

- Do not add `Relyra.Repo` or any library-owned Repo abstraction. Existing Ecto integrations require a host-app `opts[:repo]`.
- Do not make `connection_id` an org-scoped lookup key yet. Current public routes and resolver inputs are global `/:connection_id` (`lib/relyra/phoenix/router.ex:12-19`, controllers at `login_controller.ex:13-23` and `metadata_controller.ex:7-15`).
- Do not store one mutable certificate blob on the connection row. The architecture docs explicitly reject the single-cert pattern.
- Do not let runtime validation silently treat drafts as usable. Existing code is consistently fail-closed and typed-error based.
- Do not pass Ecto structs into `Relyra.Protocol.*`, `Relyra.Security.*`, or Phoenix controllers.

## Metadata

**Analog search scope:** `lib/relyra`, `lib/mix/tasks`, `test`, `.planning/research`
**Primary files scanned:** 18
**Pattern extraction date:** 2026-05-05
