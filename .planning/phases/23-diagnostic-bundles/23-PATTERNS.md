# Phase 23: Diagnostic Bundles - Pattern Map

**Mapped:** 2024-05-07
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/diagnostic.ex` | service | file-I/O | `lib/relyra/metadata.ex` | role-match |
| `lib/relyra/diagnostic/allow_list.ex` | utility | transform | `lib/relyra/user_mapper/default_attribute.ex` | role-match |
| `lib/mix/tasks/relyra.diagnostic.ex` | mix task | command | `lib/mix/tasks/relyra.metadata.pin.ex` | exact |
| `lib/relyra/phoenix/controllers/diagnostic_controller.ex` | controller | request-response | `lib/relyra/phoenix/controllers/metadata_controller.ex` | exact |
| `lib/relyra/live_admin/connections_live.ex` | component | request-response | `lib/relyra/live_admin/connections_live.ex` | exact |

## Pattern Assignments

### `lib/relyra/diagnostic.ex` (service, file-I/O)

**Analog:** `lib/relyra/metadata.ex`

**Imports pattern** (lines 1-5):
```elixir
defmodule Relyra.Metadata do
  @moduledoc false

  alias Relyra.Error
```

**Core Service Pattern & Validation** (lines 17-25):
```elixir
  def import_xml(connection_id, xml, opts)
      when is_binary(connection_id) and is_binary(xml) and is_list(opts) do
    with {:ok, _repo} <- fetch_repo(opts, :import_xml) do
      Import.import_xml(connection_id, xml, opts)
    end
  end
```

**Error Handling Pattern** (lines 26-32):
```elixir
  def import_xml(_connection_id, _xml, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and XML bytes are required for metadata import",
       %{operation: :import_xml, repo: inspect(Keyword.get(opts, :repo))}
     )}
  end
```

---

### `lib/relyra/diagnostic/allow_list.ex` (utility, transform)

**Analog:** `lib/relyra/user_mapper/default_attribute.ex`

**Core mapping pattern** (lines 26-34):
```elixir
  defp fallback_user_map(assertion, attributes) do
    %{
      name_id: Map.get(assertion, :name_id),
      email: get_attribute(attributes, ["email", "mail", "EmailAddress"]),
      first_name: get_attribute(attributes, ["given_name", "givenname", "FirstName"]),
      last_name: get_attribute(attributes, ["family_name", "sn", "LastName"]),
      roles: get_attribute(attributes, ["groups", "roles", "memberOf"]) || []
    }
  end
```

**Reduction/Transformation pattern** (lines 47-56):
```elixir
  defp apply_attribute_rules(user_map, attributes, rules) when is_list(rules) do
    Enum.reduce(rules, user_map, fn rule, acc ->
      source_attribute = Map.get(rule, :source_attribute)
      target_field = Map.get(rule, :target_field)
      strategy = Map.get(rule, :multivalue_strategy)

      case resolve_attribute(attributes, source_attribute, strategy) do
        nil -> acc
        value -> Map.put(acc, target_field, value)
      end
    end)
  end
```

---

### `lib/mix/tasks/relyra.diagnostic.ex` (mix task, command)

**Analog:** `lib/mix/tasks/relyra.metadata.pin.ex`

**Imports and Setup** (lines 23-28):
```elixir
  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
```

**Option Parsing** (lines 30-34):
```elixir
    {opts, argv, _invalid} =
      OptionParser.parse(args,
        strict: [fingerprint: :keep, repo: :string],
        aliases: [f: :fingerprint, r: :repo]
      )
```

**Task Execution & Output** (lines 58-69):
```elixir
    case Relyra.Metadata.pin_trust_fingerprint(
           connection_id,
           %{metadata_trust_fingerprints: Enum.map(fingerprints, &String.downcase/1)},
           repo: repo
         ) do
      {:ok, _updated} ->
        Mix.shell().info(
          "relyra.metadata.pin: pinned #{length(fingerprints)} fingerprint(s) on #{connection_id}."
        )

        :ok

      {:error, error} ->
        Mix.raise("relyra.metadata.pin failed: #{error.message}")
    end
```

---

### `lib/relyra/phoenix/controllers/diagnostic_controller.ex` (controller, request-response)

**Analog:** `lib/relyra/phoenix/controllers/metadata_controller.ex`

**Imports pattern** (lines 1-4):
```elixir
defmodule Relyra.Phoenix.Controllers.MetadataController do
  @moduledoc false
  use Phoenix.Controller, formats: [:xml]

  alias Relyra.Error
```

**Core Response Pattern (Binary/Download)** (lines 14-22):
```elixir
    case Relyra.ConnectionResolver.resolve_connection(request_context, opts) do
      {:ok, connection} ->
        xml = Relyra.Protocol.Metadata.build_sp_metadata(connection, opts)

        conn
        |> put_resp_content_type("application/xml")
        |> send_resp(200, xml)

      {:error, %Error{} = error} ->
        handle_error(conn, error, opts)
    end
```
*(Note for planner: Replace `put_resp_content_type`/`send_resp` with `put_resp_content_type("application/zip")` and `send_download(conn, {:binary, zip_binary}, filename: "bundle.zip")` per Phoenix idioms for file downloads)*

**Error Handling** (lines 43-48):
```elixir
  defp default_error_response(conn, error) do
    conn
    |> put_status(400)
    |> text("SAML Metadata Error: #{error.message} (#{error.type})")
    |> halt()
  end
```

---

### `lib/relyra/live_admin/connections_live.ex` (component, request-response)

**Analog:** `lib/relyra/live_admin/connections_live.ex`

**UI Bulk Action Pattern** (lines 420-424):
```elixir
            <div :if={MapSet.size(@selected_ids) > 0} style="margin-bottom: 20px; padding: 12px; background: #f0f4f8; border: 1px solid #d1d9e1; border-radius: 4px; display: flex; align-items: center; gap: 16px;">
              <span style="font-weight: bold;">Bulk Actions ({MapSet.size(@selected_ids)} selected):</span>
              <button phx-click="bulk_action" phx-value-action="enable" style="padding: 4px 8px; cursor: pointer;">Enable</button>
              <button phx-click="bulk_action" phx-value-action="disable" style="padding: 4px 8px; cursor: pointer;">Disable</button>
              <button phx-click="bulk_action" phx-value-action="refresh_metadata" style="padding: 4px 8px; cursor: pointer;">Refresh Metadata</button>
            </div>
```
*(Note for planner: Insert an HTML link or button styled to point to the `diagnostic_controller` GET route under an appropriate section in the detail view or bulk actions.)*

## Shared Patterns

### Error Handling
**Source:** `lib/relyra/error.ex`
**Apply to:** All services
```elixir
Error.new(
  :diagnostic_bundle_failed,
  "Failed to generate diagnostic bundle",
  %{operation: :create_bundle, reason: reason}
)
```

## Metadata

**Analog search scope:** `lib/relyra/**/*.ex`, `lib/mix/tasks/**/*.ex`
**Files scanned:** 20+
**Pattern extraction date:** 2024-05-07