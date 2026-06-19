# Phase 64: Public Testing API & Package Boundary - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/testing.ex` | public facade | request-response | `lib/relyra.ex` | role-match |
| `lib/relyra/testing/fixture.ex` | model | transform | `lib/relyra/test_support/fake_idp.ex` | role-match |
| `lib/relyra/testing/signer.ex` | utility/service | transform | `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex` | exact |
| `lib/relyra/testing/adapters.ex` | adapter utility | request-response | `test/protocol/consume_response_pipeline_test.exs` | exact |
| `lib/relyra/testing/phoenix.ex` | optional integration | request-response | `lib/relyra/test_support.ex` | role-match |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `test/relyra/testing_test.exs` | test | request-response | `test/protocol/consume_response_pipeline_test.exs` | exact |
| `test/security/testing_fixture_crypto_test.exs` | test | request-response | `test/protocol/consume_response_pipeline_test.exs` | exact |
| `test/relyra/testing_phoenix_test.exs` | test | request-response | `test/phoenix/acs_controller_test.exs` | exact |
| `test/relyra/testing_optional_dependency_test.exs` | test | batch | `mix.exs` | role-match |
| `test/mix/tasks/verify_release_parity_test.exs` | test | batch | `test/mix/tasks/verify_release_parity_test.exs` | exact |

## Pattern Assignments

### `lib/relyra/testing.ex` (public facade, request-response)

**Analog:** `lib/relyra.ex`

**Imports/aliases pattern** (`lib/relyra.ex` lines 18-24):
```elixir
alias Relyra.ConnectionResolver
alias Relyra.Error
alias Relyra.Protocol.AuthnRequest
alias Relyra.Protocol.Binding
alias Relyra.Protocol.ValidationPipeline
alias Relyra.RequestStore
alias Relyra.Security.RelayState
```

**Public typed-return pattern** (`lib/relyra.ex` lines 157-180):
```elixir
@spec consume_response(binary(), map() | keyword(), keyword()) ::
        {:ok, map()} | {:error, Relyra.Error.t()}
def consume_response(response_payload, request_intent_or_opts, opts \\ []) do
  metadata = %{flow: :sp_initiated}

  Relyra.Telemetry.span([:response, :consume], metadata, fn ->
    try do
      result = do_consume_response(response_payload, request_intent_or_opts, opts)

      case result do
        {:ok, login_result} ->
          final_metadata =
            Map.merge(metadata, %{
              outcome: :ok,
              connection_id: read_field(login_result, :connection_id)
            })

          {{:ok, login_result}, final_metadata}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
```

**Planner note:** Public `Relyra.Testing` should expose plain functions such as `signed_success/1`, `wrong_audience/1`, `tampered_digest/1`, `invalid_signature/1`, `consume_opts/2`, and `post_params/2`. Do not add a macro-first `use Relyra.Testing` surface.

---

### `lib/relyra/testing/fixture.ex` (model, transform)

**Analog:** `lib/relyra/test_support/fake_idp.ex`

**Struct/data pattern** (`lib/relyra/test_support/fake_idp.ex` lines 13-24):
```elixir
defmodule Builder do
  @moduledoc false
  defstruct [
    :issuer,
    :subject,
    :audience,
    :destination,
    :recipient,
    :in_response_to,
    :name_id,
    :relay_state
  ]
end
```

**Public fixture should carry:** `response_xml`, `encoded_response`, `cert_chain` or `idp_certificates`, `connection`, `request_intent`, `relay_state`, and `expected`. Prefer a public struct with `@type t`.

---

### `lib/relyra/testing/signer.ex` (utility/service, transform)

**Analog:** `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex`

**Imports pattern** (lines 26-31):
```elixir
alias LedgerLoop.FakeIdP.Keypair
alias Relyra.Security.XML.AttributeEscape
alias Relyra.Security.XML.C14N
alias Relyra.Security.XML.PureBeam
alias Relyra.Security.XML.SaxyTree
alias Relyra.Security.XML.SaxyTree.Node
```

**Core signing pattern** (lines 60-85):
```elixir
@spec signed_response(keyword()) :: binary()
def signed_response(opts \\ []) when is_list(opts) do
  fields = build_fields(opts)
  priv_key = Keypair.private_key()

  placeholder_xml = response_xml(fields, "", "")

  placeholder_tree = parse_tree!(placeholder_xml)
  assertion_node = find_by_local_and_id(placeholder_tree, "Assertion", fields.assertion_id)
  digest_value_b64 = digest_for(assertion_node)

  digest_xml = response_xml(fields, digest_value_b64, "")
  digest_tree = parse_tree!(digest_xml)
  signed_info_node = find_first_by_local(digest_tree, "SignedInfo")
  signature_value_b64 = sign_signed_info(signed_info_node, priv_key)

  signed_xml = response_xml(fields, digest_value_b64, signature_value_b64)
  Base.encode64(signed_xml)
end
```

**Tamper pattern** (lines 102-118):
```elixir
@spec tamper(binary()) :: binary()
def tamper(b64) when is_binary(b64) do
  xml = Base.decode64!(b64)
  tampered = String.replace(xml, ~r/(<NameID[^>]*>)[^<]+(<\/NameID>)/, "\\1TAMPERED\\2")

  if tampered == xml do
    raise "tamper/1 failed to locate <NameID>; template drifted"
  end

  Base.encode64(tampered)
end
```

**Escaping/XML template pattern** (lines 159-197):
```elixir
defp response_xml(fields, digest_value_b64, signature_value_b64) do
  in_response_to_attr =
    case fields.in_response_to do
      nil -> ""
      "" -> ""
      v -> ~s( InResponseTo="#{AttributeEscape.escape_attribute(v)}")
    end

  "<Response Destination=\"#{AttributeEscape.escape_attribute(fields.destination)}\"#{in_response_to_attr} ConnectionId=\"valid\">" <>
    "<Issuer>#{xml_text(fields.issuer)}</Issuer>" <>
    "<Status><StatusCode Value=\"#{AttributeEscape.escape_attribute(fields.status)}\"/></Status>" <>
    "<Assertion ID=\"#{AttributeEscape.escape_attribute(fields.assertion_id)}\">" <>
    "<Issuer>#{xml_text(fields.issuer)}</Issuer>" <>
    "<Subject>" <>
    "<NameID>#{xml_text(fields.name_id)}</NameID>" <>
    "<SubjectConfirmation Method=\"urn:oasis:names:tc:SAML:2.0:cm:bearer\">" <>
    "<SubjectConfirmationData Recipient=\"#{AttributeEscape.escape_attribute(fields.recipient)}\" NotOnOrAfter=\"#{AttributeEscape.escape_attribute(fields.subject_confirmation_not_on_or_after)}\"/>" <>
    "</SubjectConfirmation>" <>
    "</Subject>" <>
    "<Conditions NotBefore=\"#{AttributeEscape.escape_attribute(fields.not_before)}\" NotOnOrAfter=\"#{AttributeEscape.escape_attribute(fields.not_on_or_after)}\">" <>
    "<AudienceRestriction><Audience>#{xml_text(fields.audience)}</Audience></AudienceRestriction>" <>
    "</Conditions>" <>
    "</Assertion>" <>
    "<Signature xmlns=\"http://www.w3.org/2000/09/xmldsig#\">" <>
    "<SignedInfo>" <>
    "<CanonicalizationMethod Algorithm=\"#{@exc_c14n}\"/>" <>
    "<SignatureMethod Algorithm=\"#{@rsa_sha256}\"/>" <>
    "<Reference URI=\"##{AttributeEscape.escape_attribute(fields.assertion_id)}\">" <>
    "<DigestMethod Algorithm=\"#{@sha256}\"/>" <>
    "<DigestValue>#{xml_text(digest_value_b64)}</DigestValue>" <>
    "</Reference>" <>
    "</SignedInfo>" <>
    "<SignatureValue>#{xml_text(signature_value_b64)}</SignatureValue>" <>
    "</Signature>" <>
    "</Response>"
end
```

**Crypto helpers pattern** (lines 216-229):
```elixir
defp digest_for(%Node{} = assertion_node) do
  {:ok, %{canonical_xml: ref_bytes}} = PureBeam.canonicalize(%{node: assertion_node})
  :sha256 |> :crypto.hash(ref_bytes) |> Base.encode64()
end

defp sign_signed_info(%Node{} = signed_info_node, priv_key) do
  {:ok, c14n} = C14N.serialize(signed_info_node)
  c14n |> then(&:public_key.sign(&1, :sha256, priv_key)) |> Base.encode64()
end
```

**Tree-walk pattern** (lines 236-273):
```elixir
defp parse_tree!(xml) do
  {:ok, %Node{} = tree} = SaxyTree.parse(xml)
  tree
end

defp find_first_by_local(%Node{local: local} = node, local), do: node
defp find_first_by_local(%Node{children: children}, local) do
  Enum.find_value(children, fn child -> find_first_by_local(child, local) end)
end
defp find_first_by_local(_other, _local), do: nil

defp find_by_local_and_id(%Node{local: local, attrs: attrs} = node, local, id) do
  if attr_value(attrs, "ID") == id do
    node
  else
    search_children(node, local, id)
  end
end
```

**Planner note:** Copy the signing technique, not `Relyra.TestSupport.*` dependencies. The public signer must live under `lib/relyra/testing*` and compile/package in production.

---

### `lib/relyra/testing/adapters.ex` (adapter utility, request-response)

**Analog:** `test/protocol/consume_response_pipeline_test.exs`

**Request store pattern** (lines 1-40):
```elixir
defmodule Relyra.Protocol.TestRequestStore do
  @moduledoc false

  @behaviour Relyra.RequestStore

  alias Relyra.Error

  @impl true
  def put_intent(_relay_state, _intent, _opts), do: :ok

  @impl true
  def fetch_intent(relay_state, opts) when is_binary(relay_state) and is_list(opts) do
    case Keyword.get(opts, :request_store_fetch) do
      fun when is_function(fun, 2) ->
        fun.(relay_state, opts)

      _ ->
        case Keyword.get(opts, :request_intent) do
          intent when is_map(intent) -> {:ok, intent}
          _ -> {:error, Error.new(:request_intent_not_found, "No request intent present in test opts", %{relay_state: relay_state})}
        end
    end
  end

  @impl true
  def consume_intent(relay_state, request_id, opts)
      when is_binary(relay_state) and is_binary(request_id) and is_list(opts) do
    case Keyword.get(opts, :request_store_consume) do
      fun when is_function(fun, 3) -> fun.(relay_state, request_id, opts)
      _ -> :ok
    end
  end
end
```

**Replay/resolver pattern** (lines 43-85):
```elixir
defmodule Relyra.Protocol.TestReplayStore do
  @moduledoc false
  @behaviour Relyra.ReplayStore

  @impl true
  def consume_replay_key(replay_key, metadata, opts)
      when is_binary(replay_key) and is_map(metadata) and is_list(opts) do
    case Keyword.get(opts, :replay_store_consume) do
      fun when is_function(fun, 3) -> fun.(replay_key, metadata, opts)
      _ -> :ok
    end
  end
end

defmodule Relyra.Protocol.TestConnectionResolver do
  @moduledoc false
  @behaviour Relyra.ConnectionResolver
  alias Relyra.Error

  @impl true
  def resolve_connection(request_context, opts) when is_map(request_context) and is_list(opts) do
    case Keyword.get(opts, :connection_resolver_resolve) do
      fun when is_function(fun, 2) -> fun.(request_context, opts)
      _ -> ...
    end
  end
end
```

**consume_opts pattern** (`test/protocol/consume_response_pipeline_test.exs` lines 416-429):
```elixir
defp consume_opts(extra_opts) do
  Keyword.merge(
    [
      connection: connection(),
      resolved_connection: connection(),
      relay_state: request_intent().relay_state,
      request_store: TestRequestStore,
      replay_store: TestReplayStore,
      connection_resolver: TestConnectionResolver,
      request_intent: request_intent()
    ],
    extra_opts
  )
end
```

---

### `lib/relyra/testing/phoenix.ex` (optional integration, request-response)

**Analog:** `lib/relyra/test_support.ex`

**POST params + dispatch pattern** (lines 62-88):
```elixir
@spec post_saml_response(Plug.Conn.t(), String.t(), keyword()) :: Plug.Conn.t()
def post_saml_response(conn, response_xml, opts \\ []) when is_binary(response_xml) do
  ensure_not_prod!()
  endpoint = Keyword.fetch!(opts, :endpoint)

  path =
    Keyword.get(opts, :path) ||
      case conn.assigns[:relyra_connection_id] do
        nil ->
          raise ArgumentError,
                "post_saml_response/3 requires :path or a prior setup_saml_connection/2 with :connection_id"

        connection_id ->
          "/#{connection_id}/acs"
      end

  params =
    %{
      Keyword.get(opts, :saml_response_key, "SAMLResponse") =>
        Base.encode64(response_xml, padding: false),
      Keyword.get(opts, :relay_state_key, "RelayState") => Keyword.get(opts, :relay_state, "")
    }
    |> Enum.reject(fn {_k, v} -> v == "" end)
    |> Map.new()

  Phoenix.ConnTest.dispatch(conn, endpoint, :post, path, params)
end
```

**Planner note:** Core `Relyra.Testing.post_params/2` should be Phoenix-free and return the params map. `Relyra.Testing.Phoenix` may call `Phoenix.ConnTest.dispatch/5`, but should be isolated so core fixture generation does not require Phoenix.

---

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**Production compile/package boundary pattern** (lines 47-63):
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support", "test/fixtures/demo_host/lib"]
defp elixirc_paths(:prod), do: prod_elixirc_paths()
defp elixirc_paths(_), do: ["lib"]

# Production compiles an explicit lib/**/*.ex list omitting test_support (Mix accepts file paths).
defp prod_elixirc_paths do
  Path.wildcard("lib/**/*.ex")
  |> Enum.reject(&String.contains?(&1, "test_support"))
  |> Enum.sort()
end

defp package_lib_files do
  Path.wildcard("lib/**/*")
  |> Enum.reject(&String.contains?(&1, "test_support"))
  |> Enum.filter(&File.regular?/1)
  |> Enum.sort()
end
```

**Security alias invariant** (lines 233-256):
```elixir
"ci.security": [
  "compile --warnings-as-errors",
  "ci.conformance",
  ...
  # each security suite below runs as its own `cmd mix test` (a fresh OS process) on
  # purpose ...
  "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
  "cmd mix test test/security/strict_default_proof_test.exs --warnings-as-errors",
  ...
  "cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors",
```

**Planner note:** `lib/relyra/testing*` is included automatically by the current wildcard. Do not weaken `test_support` rejection or collapse `ci.security` `cmd mix test` lines.

---

### `test/relyra/testing_test.exs` (test, request-response)

**Analog:** `test/protocol/consume_response_pipeline_test.exs`

**Direct verifier success pattern** (lines 220-228):
```elixir
assert {:ok, login_result} =
         Relyra.consume_response(
           response_xml(%{assertion_id: "assertion-compat"}),
           request_intent(),
           consume_opts(now: @fixed_now)
         )

assert login_result.in_response_to == "id_request_123"
```

**Fixture data pattern** (lines 385-413):
```elixir
defp request_intent do
  %{
    request_id: "id_request_123",
    connection_id: "conn-123",
    relay_state: "rs_1234567890abcdef",
    in_response_to: "id_request_123",
    destination: "https://sp.example.com/saml/acs",
    recipient: "https://sp.example.com/saml/acs",
    issuer: "https://idp.example.com/metadata",
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs"
  }
end

defp connection do
  %{
    connection_id: "conn-123",
    idp_entity_id: "https://idp.example.com/metadata",
    issuer: "https://idp.example.com/metadata",
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    cert_chain: [XmldsigSigner.self_signed_cert_pem()]
  }
end
```

---

### `test/security/testing_fixture_crypto_test.exs` (test, request-response)

**Analog:** `test/protocol/consume_response_pipeline_test.exs`

**Typed error assertion pattern** (lines 161-166):
```elixir
assert {:error, %Error{type: :assertion_not_yet_valid}} =
         Relyra.consume_response(
           edge_plus_one_payload,
           request_intent(),
           consume_opts(now: @fixed_now, skew_seconds: 120)
         )
```

**Never-success negative pattern** (lines 231-240):
```elixir
test "unsigned payload never returns {:ok, _}" do
  assert {:error, %Error{type: error_type}} =
           Relyra.consume_response(
             "<Fake>unsigned</Fake>",
             request_intent(),
             consume_opts(now: @fixed_now)
           )

  assert error_type in [:missing_signature, :missing_protocol_field, :malformed_xml]
end
```

**Post-signing signer proof pattern** (lines 434-442):
```elixir
defp response_xml(overrides \\ %{}) do
  %{response_xml: signed_xml} = XmldsigSigner.sign_response(structure_only_xml(overrides))
  signed_xml
end
```

**Planner note:** Pin exact `%Relyra.Error{type: ...}` for public negative fixtures: wrong audience, digest tamper, invalid signature/wrong key.

---

### `test/relyra/testing_phoenix_test.exs` (test, request-response)

**Analog:** `test/phoenix/acs_controller_test.exs`

**Router/ConnTest setup pattern** (lines 1-16):
```elixir
defmodule Relyra.Phoenix.ACSTestRouter do
  use Phoenix.Router
  import Relyra.Phoenix.Router

  scope "/" do
    saml_routes()
  end
end

defmodule Relyra.Phoenix.ACSControllerTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  alias Relyra.TestSupport.XmldsigSigner
  alias Relyra.Phoenix.ACSTestRouter
```

**Real ACS post pattern** (lines 102-125):
```elixir
%{response_xml: signed_xml} = XmldsigSigner.sign_response(@valid_xml)

Application.put_env(:relyra, :connection_resolver, GenuineCertConnectionResolver)
Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)
Application.put_env(:relyra, :replay_store, Relyra.ReplayStore.ETS)
Application.put_env(:relyra, :user_mapper, FakeUserMapper)
Application.put_env(:relyra, :session_adapter, FakeSessionAdapter)

Relyra.RequestStore.ETS.ensure_table!()
Relyra.ReplayStore.ETS.ensure_table!()
Relyra.RequestStore.ETS.put_intent("rs_123", request_intent)

conn =
  post(conn, "/valid/acs", %{
    "SAMLResponse" => Base.encode64(signed_xml),
    "RelayState" => "rs_123"
  })

assert redirected_to(conn) == "/welcome"
```

---

### `test/relyra/testing_optional_dependency_test.exs` (test, batch)

**Analog:** `mix.exs`

**Optional deps declarations** (`mix.exs` lines 74-92):
```elixir
defp deps do
  [
    {:saxy, "~> 1.6"},
    {:telemetry, "~> 1.3"},
    {:plug, "~> 1.16"},
    {:phoenix, "~> 1.8", optional: true},
    {:phoenix_ecto, "~> 4.6", optional: true},
    {:phoenix_live_view, "~> 1.1", optional: true},
    ...
    {:ecto, "~> 3.13", optional: true},
    {:ecto_sql, "~> 3.13", optional: true},
    {:postgrex, ">= 0.0.0", optional: true},
    {:req, "~> 0.5", optional: true},
    {:oban, "~> 2.22", optional: true}
  ]
end
```

**Planner note:** Add a scoped compile/load assertion that core `Relyra.Testing` and `Relyra.Testing.Fixture` do not reference Phoenix. Avoid making full no-optional-deps package compile a Phase 64 blocker unless the plan explicitly owns the broader optional-dependency cleanup.

---

### `test/mix/tasks/verify_release_parity_test.exs` (test, batch)

**Analog:** `test/mix/tasks/verify_release_parity_test.exs`

**Package path filter tests** (lines 105-132):
```elixir
describe "filter_package_paths/1" do
  test "includes package scope paths and excludes out-of-scope paths" do
    paths = [
      "lib/relyra/foo.ex",
      "priv/repo/migrations/x.exs",
      "guides/getting_started.md",
      "docs/overview.md",
      "README.md",
      "CHANGELOG.md",
      ".github/workflows/ci.yml",
      "test/support/helper.ex"
    ]

    assert ReleaseParity.filter_package_paths(paths) == [
             "CHANGELOG.md",
             "README.md",
             "docs/overview.md",
             "guides/getting_started.md",
             "lib/relyra/foo.ex",
             "priv/repo/migrations/x.exs"
           ]
  end

  test "excludes test_support paths" do
    paths = ["lib/relyra/foo.ex", "lib/relyra/test_support/foo.ex"]

    assert ReleaseParity.filter_package_paths(paths) == ["lib/relyra/foo.ex"]
  end
end
```

**Hard-fail detection test pattern** (lines 135-139):
```elixir
describe "paths_contain_test_support?/1" do
  test "detects test_support in path list" do
    assert ReleaseParity.paths_contain_test_support?(["lib/relyra/test_support/foo.ex"])
    refute ReleaseParity.paths_contain_test_support?(["lib/relyra/foo.ex"])
  end
end
```

**Planner note:** Extend these tests with positive assertions that `lib/relyra/testing.ex` and `lib/relyra/testing/*.ex` survive filtering/package scope, while `lib/relyra/test_support*` remains excluded.

## Shared Patterns

### Real Verifier Path

**Source:** `lib/relyra.ex` lines 429-449
**Apply to:** `Relyra.Testing.consume_opts/2`, public fixture tests, Phoenix helper tests
```elixir
defp do_consume_response(response_payload, request_intent_or_opts, opts) do
  now = Keyword.get(opts, :now, DateTime.utc_now())

  with {:ok, request_intent, consume_opts} <-
         resolve_request_intent(request_intent_or_opts, opts),
       :ok <- validate_relay_state_opt(consume_opts, request_intent),
       :ok <- validate_request_intent(request_intent, consume_opts),
       :ok <- validate_request_intent_expiry(request_intent, now),
       {:ok, connection} <- resolve_connection_context(request_intent, consume_opts),
       {:ok, result_map} <-
         ValidationPipeline.run(response_payload, request_intent, connection, consume_opts),
       :ok <- consume_replay_key(result_map, connection, consume_opts),
       :ok <- consume_request_intent(request_intent, consume_opts),
       {:ok, login_result} <- normalize_consume_result(result_map) do
    {:ok, login_result}
  else
    {:error, %Error{} = error} ->
      Process.delete(:relyra_validation_trace)
      {:error, error}
  end
end
```

### ACS Path

**Source:** `lib/relyra/phoenix/controllers/acs_controller.ex` lines 7-24
**Apply to:** `Relyra.Testing.Phoenix` and `test/relyra/testing_phoenix_test.exs`
```elixir
def create(conn, params) do
  opts = controller_opts(conn)

  case Relyra.Protocol.Binding.decode_post(params, opts) do
    {:ok, %{response_xml: response_xml, relay_state: relay_state}} ->
      consume_opts = Keyword.put(opts, :relay_state, relay_state)

      case Relyra.consume_response(response_xml, consume_opts) do
        {:ok, login_result} -> handle_success(conn, login_result, opts)
        {:error, %Error{} = error} -> handle_error(conn, error, opts)
      end

    {:error, %Error{} = error} ->
      handle_error(conn, error, opts)
  end
end
```

### Package Boundary

**Source:** `lib/mix/tasks/verify.release_parity.ex` lines 177-219
**Apply to:** package/parity tests
```elixir
@spec filter_package_paths([String.t()]) :: [String.t()]
def filter_package_paths(paths) when is_list(paths) do
  paths
  |> Enum.reject(&test_support_path?/1)
  |> Enum.filter(&package_path?/1)
  |> Enum.sort()
end

@spec paths_contain_test_support?([String.t()]) :: boolean()
def paths_contain_test_support?(paths) when is_list(paths) do
  Enum.any?(paths, &test_support_path?/1)
end

defp test_support_path?(path) when is_binary(path) do
  String.contains?(path, "test_support")
end

@spec assert_no_test_support!([String.t()]) :: :ok | no_return()
def assert_no_test_support!(paths) when is_list(paths) do
  if paths_contain_test_support?(paths) do
    ...
    System.halt(2)
  else
    :ok
  end
end
```

### Public API Boundary

**Source:** `lib/relyra/test_support/xmldsig_signer.ex` lines 40-47 and `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex` lines 18-23
**Apply to:** all `lib/relyra/testing*`
```elixir
# Private test support imports include Relyra.TestSupport.FakeIdP and must not be copied as dependencies:
alias Relyra.TestSupport.FakeIdP

# Production-compiled demo signer documents the right boundary:
# This module uses only Relyra's public, prod-compiled XML modules
# (`Relyra.Security.XML.*`) and ... does not reference any module under
# the `test_support/` elixirc path.
```

## No Analog Found

All planned Phase 64 files have close analogs in the codebase. The only gap is exact public naming for `Relyra.Testing.Fixture` fields, which is discretionary per `64-CONTEXT.md`.

## Metadata

**Analog search scope:** `lib/`, `test/`, `demo/ledger_loop/`, `mix.exs`
**Files scanned:** 200+
**Pattern extraction date:** 2026-06-15
