<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### 1. Connection Resolution: Path-Based Routing
**Decision:** Require the host application to provide an explicit endpoint (e.g., `POST /sso/acs/:connection_id`) and pass the resolved connection context to Relyra. Relyra will **not** parse unverified XML to extract the `<Issuer>` for connection lookup.

### 2. Strictness: Connection-Level Opt-In (`allow_idp_initiated`)
**Decision:** Add a new boolean field `allow_idp_initiated` (default: `false`) to the `Relyra.Connection` schema. IdP-initiated flows (responses without `InResponseTo`) will be rejected by default.

### 3. RelayState Handling: Safe Exfiltration, No Automatic Redirects
**Decision:** Relyra will extract the opaque `RelayState` and pass it back to the host application on the `Relyra.LoginResult` struct. Relyra will **not** perform HTTP redirects itself, but will ship a utility function (`Relyra.Security.safe_local_redirect/2`) to help developers safely validate RelayState paths.

### the agent's Discretion
None explicitly specified, but implementation details of how to bypass `InResponseTo` checking, how to structure the `safe_local_redirect`, and migration defaults are up to discretion.

### Deferred Ideas (OUT OF SCOPE)
None specified.
</user_constraints>

# Phase 19: IdP-Initiated SSO - Research

**Researched:** 2024-05-19
**Domain:** Security & SAML Protocol
**Confidence:** HIGH

## Summary

This research addresses the implementation details for Phase 19: IdP-Initiated SSO, focusing on how to securely allow responses lacking an `InResponseTo` element, only when explicitly permitted by the connection configuration. It covers the required Ecto migrations, updates to the validation pipeline, changes to the `consume_response` entry point, and the introduction of a safe redirect utility for opaque RelayState values.

**Primary recommendation:** Introduce `allow_idp_initiated` to the connection schema, update `Relyra.consume_response` and `ValidationPipeline` to handle a `nil` request intent gracefully, and bypass `InResponseTo` correlation if and only if `allow_idp_initiated: true` and `InResponseTo` is absent in the payload.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| IdP-Initiated Opt-In | Database / Storage | API / Backend | Saved in `relyra_connections` schema and validated by the backend pipeline. |
| Connection Resolution | API / Backend | — | Must be resolved deterministically from the HTTP path, NOT from unverified XML. |
| RelayState Exfiltration | API / Backend | — | Extracted from `opts` and attached to `LoginResult`. Relyra does not redirect. |
| Open Redirect Prevention | API / Backend | — | Provided as a utility `Relyra.Security.safe_local_redirect/2` for host apps to use. |

## 1. Ecto Migration for `allow_idp_initiated`

### Migration File
A new migration file needs to be created, e.g., `priv/repo/migrations/20240519000000_add_allow_idp_initiated_to_relyra_connections.exs`.

```elixir
defmodule Relyra.Repo.Migrations.AddAllowIdpInitiatedToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :allow_idp_initiated, :boolean, default: false, null: false
    end
  end
end
```

### Schema Updates (`lib/relyra/ecto/connection.ex`)
- Add `field :allow_idp_initiated, :boolean, default: false` to the `relyra_connections` schema.
- Add `:allow_idp_initiated` to the list of permitted cast fields in `draft_changeset/2` and `update_changeset/2`.
- Default is `false` to maintain a fail-closed security posture against Login CSRF.

## 2. Updates to `Relyra.consume_response` and Validation

### Handling `request_intent_or_opts`
In `Relyra.consume_response/3`, the caller must pass `nil` as the second argument (`request_intent_or_opts`) during an IdP-initiated flow.

**Updates to `lib/relyra.ex`:**
Add a clause for `resolve_request_intent` to gracefully handle `nil`:
```elixir
defp resolve_request_intent(nil, opts) do
  {:ok, nil, opts}
end
```
Additionally, handle `nil` in validations that currently expect a map:
- `validate_request_intent(nil, _opts) do :ok end`
- `validate_relay_state_opt(_opts, nil) do :ok end`
- `consume_request_intent(nil, _opts) do :ok end`
- Fix `Map.get(nil, ...)` calls in `resolve_connection_context/2` to avoid `FunctionClauseError`. For `nil` intents, the connection must be provided explicitly in `opts[:connection]` or `opts[:resolved_connection]`.

### Bypassing `InResponseTo` Validation (`lib/relyra/protocol/validation_pipeline.ex`)
Modify `validate_request_correlation/4` (signature updated to accept `connection`):

```elixir
defp validate_request_correlation(parsed_doc, nil, connection, _opts) do
  if Map.get(connection, :allow_idp_initiated) do
    if is_nil(Map.get(parsed_doc, :in_response_to)) do
      :ok
    else
      {:error, Error.new(:in_response_to_not_allowed, "IdP-initiated response contains InResponseTo")}
    end
  else
    {:error, Error.new(:idp_initiated_not_allowed, "IdP-initiated flow not allowed for this connection")}
  end
end
```
Additionally, `expected_connection_id`, `expected_destination`, and `expected_recipient` must safely handle a `nil` `request_intent` by safely using `&&` or falling back immediately to connection values.

### RelayState Exfiltration
Update `login_result/4` in `ValidationPipeline` to extract RelayState from the `opts` or payload and place it on the final map. It should be added to `Relyra.LoginResult` schema as `relay_state: String.t() | nil`.

## 3. Structure of `Relyra.Security.safe_local_redirect/2`

Create a new module `Relyra.Security.Redirect` (or add to an existing security utility module) to prevent open redirects.

```elixir
defmodule Relyra.Security.Redirect do
  @spec safe_local_redirect(binary() | nil, keyword()) :: {:ok, binary()} | {:error, Relyra.Error.t()}
  def safe_local_redirect(nil, _opts), do: {:error, Relyra.Error.new(:invalid_redirect, "No path provided")}
  def safe_local_redirect(path, _opts) when is_binary(path) do
    cond do
      String.starts_with?(path, "//") ->
        {:error, Relyra.Error.new(:invalid_redirect, "Path cannot start with //")}
      String.starts_with?(path, "http://") or String.starts_with?(path, "https://") ->
        {:error, Relyra.Error.new(:invalid_redirect, "Path must be relative, not absolute URL")}
      String.starts_with?(path, "/") ->
        {:ok, path}
      true ->
        {:error, Relyra.Error.new(:invalid_redirect, "Path must start with /")}
    end
  end
  def safe_local_redirect(_path, _opts) do
    {:error, Relyra.Error.new(:invalid_redirect, "Path must be a string")}
  end
end
```

## 4. `request_intent` in an IdP-Initiated Flow

During an IdP-initiated flow, there is no corresponding `AuthnRequest` originating from the SP. The caller explicitly passes `nil` for the `request_intent_or_opts` parameter to `Relyra.consume_response/3`.

Example:
```elixir
Relyra.consume_response(
  saml_response_xml,
  nil, # No request intent
  connection: resolved_connection,
  relay_state: params["RelayState"]
)
```
The internal pipeline processes this as `nil` and routes it to the specialized `allow_idp_initiated` validation logic, ensuring security constraints are applied without breaking standard SP-initiated flows.

### Open Questions (RESOLVED)
None. The implementation details map cleanly to the existing strict-by-default architecture of Relyra.
