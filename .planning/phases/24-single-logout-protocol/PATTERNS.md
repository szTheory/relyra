# Phase 24: Single Logout Protocol - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/session_adapter.ex` | behaviour | request-response | *Self* / `lib/relyra/session_adapter.ex` | exact |
| `lib/relyra/session_adapter/default.ex` | implementation | request-response | `lib/relyra/request_store/default.ex` | role-match |
| `lib/relyra/request_store.ex` | behaviour | CRUD | *Self* / `lib/relyra/request_store.ex` | exact |
| `lib/relyra/request_store/default.ex` | implementation | CRUD | *Self* / `lib/relyra/request_store/default.ex` | exact |
| `lib/relyra/protocol/logout_request.ex` | protocol | request-response | `lib/relyra/protocol/authn_request.ex` | role-match |
| `lib/relyra/protocol/binding.ex` | protocol | request-response | *Self* / `lib/relyra/protocol/binding.ex` | exact |

## Pattern Assignments

### `lib/relyra/session_adapter.ex` (behaviour, request-response)

**Analog:** `lib/relyra/session_adapter.ex`

**Core Callback Pattern** (lines 8-9):
```elixir
  @callback establish_session(subject :: map(), context :: map(), opts :: keyword()) ::
              {:ok, map() | Plug.Conn.t()} | {:error, Error.t()}
```

**Dispatch Pattern with Telemetry and Error Handling** (lines 14-41):
```elixir
    metadata = %{
      connection_id: read_field(context, :connection_id),
      flow: :sp_initiated
    }

    Relyra.Telemetry.span([:session, :establish], metadata, fn ->
      adapter = Keyword.get(opts, :session_adapter)

      result =
        cond do
          is_nil(adapter) ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is not configured")}

          Code.ensure_loaded?(adapter) and function_exported?(adapter, :establish_session, 3) ->
            adapter.establish_session(subject, context, opts)

          true ->
            {:error, Error.new(:adapter_not_configured, "Session adapter is unavailable")}
        end

      case result do
        {:ok, _} = ok ->
          {ok, Map.put(metadata, :outcome, :ok)}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
```

### `lib/relyra/session_adapter/default.ex` (implementation, request-response)

**Analog:** `lib/relyra/request_store/default.ex`

**Imports and Behaviour Pattern** (lines 1-6):
```elixir
defmodule Relyra.RequestStore.Default do
  @moduledoc false

  @behaviour Relyra.RequestStore

  alias Relyra.Error
```

**Error Implementation Pattern** (lines 8-22):
```elixir
  @impl true
  def put_intent(relay_state, intent, _opts)
      when is_binary(relay_state) and is_map(intent) do
    {:error,
     Error.new(
       :unsupported_default_adapter,
       "Default request store does not persist request intent",
       %{
         adapter: __MODULE__,
         operation: :put_intent,
         hint: "Configure :request_store with an ETS or Ecto adapter before enabling login initiation."
       }
     )}
  end
```

### `lib/relyra/request_store.ex` (behaviour, CRUD)

**Analog:** `lib/relyra/request_store.ex`

**Core Pattern (Dispatch with dynamic defaults)** (lines 28-33):
```elixir
  @spec put_intent(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def put_intent(relay_state, intent, opts \\ [])

  def put_intent(relay_state, intent, opts)
      when is_binary(relay_state) and is_map(intent) and is_list(opts) do
    dispatch_request_store(request_store(opts), :put_intent, [relay_state, intent, opts])
  end
```

### `lib/relyra/protocol/logout_request.ex` (protocol, request-response)

**Analog:** `lib/relyra/protocol/authn_request.ex`

**Imports and Constants** (lines 1-8):
```elixir
defmodule Relyra.Protocol.AuthnRequest do
  @moduledoc false

  alias Relyra.Error

  @default_protocol_binding "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
  @default_name_id_format "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  @request_id_prefix "id_"
```

**Build with Validation Pattern** (lines 10-25):
```elixir
  @spec build(map(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def build(connection, relay_context, opts \\ [])

  def build(connection, relay_context, opts) when is_map(connection) and is_map(relay_context) do
    _ = relay_context

    with {:ok, destination} <-
           required_field(connection, [:destination, :idp_sso_url], "destination"),
         {:ok, issuer} <- required_field(connection, [:issuer, :sp_entity_id], "issuer") do
      {:ok,
       %{
         id: ensure_request_id_prefix(Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)),
         issue_instant: current_issue_instant(opts)
       }}
    end
  end
```

**XML Generation Pattern** (lines 35-46):
```elixir
  @spec to_xml(map()) :: binary()
  def to_xml(%{
        id: id,
        issue_instant: issue_instant,
        destination: destination,
        issuer: issuer
      }) do
    ~s(<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="#{issue_instant}" Destination="#{destination}"><saml:Issuer>#{issuer}</saml:Issuer></samlp:AuthnRequest>)
  end
```

### `lib/relyra/protocol/binding.ex` (protocol, request-response)

**Analog:** `lib/relyra/protocol/binding.ex`

**Redirect Encode Pattern** (lines 8-16):
```elixir
  @spec encode_redirect(binary(), binary()) :: {:ok, map()} | {:error, Error.t()}
  def encode_redirect(authn_request_xml, relay_state)
      when is_binary(authn_request_xml) and authn_request_xml != "" and is_binary(relay_state) and
             relay_state != "" do
    {:ok,
     %{
       "SAMLRequest" => Base.encode64(authn_request_xml, padding: false),
       "RelayState" => relay_state
     }}
  end
```

**POST Decode with Telemetry Pattern** (lines 23-44):
```elixir
  def decode_post(params, opts) when is_map(params) do
    metadata = %{binding: :post, flow: :sp_initiated}

    Relyra.Telemetry.span([:response, :decode], metadata, fn ->
      result = do_decode_post(params, opts)

      case result do
        {:ok, %{response_xml: xml} = decoded} ->
          saml_response_key = Keyword.get(opts, :saml_response_key, "SAMLResponse")
          encoded_response =
            Map.get(params, saml_response_key) || Map.get(params, to_string(saml_response_key))
          {{:ok, decoded},
           Map.merge(metadata, %{
             outcome: :ok,
             xml_bytes: byte_size(xml),
             base64_bytes: byte_size(encoded_response || "")
           })}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end
```

## Shared Patterns

### Error Handling
**Source:** `lib/relyra/error.ex`
**Apply to:** All modules
```elixir
{:error, Error.new(:error_type, "Descriptive message", %{context: details})}
```

### Telemetry Tracing
**Source:** `lib/relyra/telemetry.ex`
**Apply to:** Binding parsing and SessionAdapter callbacks
```elixir
Relyra.Telemetry.span([:namespace, :action], metadata, fn -> 
  # logic
  {{:ok, result}, updated_metadata}
end)
```
