defmodule Relyra.TestSupport.AdoptionFixtures do
  @moduledoc false

  alias Relyra.Connection
  alias Relyra.Ecto.Certificate
  alias Relyra.Ecto.Connection, as: ConnectionRecord
  alias Relyra.TestSupport.EctoTestRepo, as: Repo
  alias Relyra.TestSupport.MigrationCase
  alias Relyra.TestSupport.XmldsigSigner

  @preset_defaults %{
    okta: [
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_sso_url: "https://idp.example.com/sso",
      idp_entity_id: "https://idp.example.com/metadata"
    ],
    entra: [
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_sso_url: "https://login.microsoftonline.com/tenant/saml2",
      idp_entity_id: "https://sts.windows.net/tenant/"
    ],
    google_workspace: [
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_sso_url: "https://accounts.google.com/o/saml2/idp?idpid=abc",
      idp_entity_id: "https://accounts.google.com/o/saml2?idpid=abc"
    ],
    adfs: [
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_sso_url: "https://adfs.example.com/adfs/ls/",
      idp_entity_id: "https://adfs.example.com/adfs/services/trust"
    ]
  }

  def reset_demo_host! do
    DemoHost.Relyra.Connections.reset!()
  end

  def setup_ets_runtime! do
    reset_demo_host!()
    DemoHost.Relyra.Connections.disable_ecto!()

    Application.put_env(:relyra, :connection_resolver, DemoHost.Relyra.Connections)
    Application.put_env(:relyra, :user_mapper, DemoHost.Relyra.UserMapper)
    Application.put_env(:relyra, :session_adapter, DemoHost.Relyra.SessionAdapter)
    Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)
    Application.put_env(:relyra, :replay_store, Relyra.ReplayStore.ETS)

    Relyra.RequestStore.ETS.ensure_table!()
    Relyra.ReplayStore.ETS.ensure_table!()
    reset_ets_stores!()
  end

  def configure_ecto_runtime! do
    reset_demo_host!()
    DemoHost.Relyra.Connections.enable_ecto!(Repo)

    Application.put_env(:relyra, :connection_resolver, DemoHost.Relyra.Connections)
    Application.put_env(:relyra, :user_mapper, DemoHost.Relyra.UserMapper)
    Application.put_env(:relyra, :session_adapter, DemoHost.Relyra.SessionAdapter)
    Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)
    Application.put_env(:relyra, :replay_store, Relyra.ReplayStore.ETS)
    Application.put_env(:relyra, :repo, Repo)

    Relyra.RequestStore.ETS.ensure_table!()
    Relyra.ReplayStore.ETS.ensure_table!()
    reset_ets_stores!()
  end

  defp reset_ets_stores! do
    for table <- [:relyra_request_intents, :relyra_replay_keys] do
      case :ets.whereis(table) do
        :undefined -> :ok
        tid -> :ets.delete_all_objects(tid)
      end
    end
  end

  def setup_ecto_runtime! do
    MigrationCase.bootstrap!()
    configure_ecto_runtime!()
  end

  def seed_preset_connection!(preset, connection_id \\ "demo")
      when preset in [:okta, :entra, :google_workspace, :adfs] do
    connection = connection_from_preset(preset, connection_id)
    :ok = DemoHost.Relyra.Connections.put_connection(connection_id, connection)
    connection
  end

  def connection_from_preset(preset, connection_id, overrides \\ [])
      when preset in [:okta, :entra, :google_workspace, :adfs] do
    cert = XmldsigSigner.self_signed_cert_pem()

    config =
      preset
      |> Relyra.Provider.apply_defaults(
        @preset_defaults[preset]
        |> Keyword.put(:idp_certificates, [cert])
        |> Keyword.merge(overrides)
      )

    keyword_to_connection(connection_id, config)
  end

  def seed_ecto_connection!(preset \\ :okta, connection_id \\ "demo") do
    cert_pem = XmldsigSigner.self_signed_cert_pem()
    now = DateTime.utc_now()

    record =
      Repo.insert!(%ConnectionRecord{
        id: Ecto.UUID.generate(),
        connection_id: connection_id,
        organization_id: "org_adoption",
        display_name: "Adoption Journey Connection",
        status: :enabled,
        provider_preset: preset,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso",
        runtime_policy: %{
          allow_idp_initiated?: false,
          require_signed_assertions?: true,
          require_signed_response?: true,
          name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
          algorithm_policy: %{signing: :rsa_sha256, digest: :sha256}
        },
        inserted_at: now,
        updated_at: now
      })

    Repo.insert!(%Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: record.id,
      fingerprint_sha256: "adoption-fixture-cert",
      pem: cert_pem,
      source: "manual",
      role: :signing,
      lifecycle_state: :active,
      activated_at: now,
      inserted_at: now,
      updated_at: now,
      metadata: %{}
    })

    {:ok, connection} =
      Relyra.ConnectionResolver.Ecto.resolve_connection(%{connection_id: connection_id},
        repo: Repo
      )

    connection
  end

  def put_request_intent!(relay_state, attrs \\ []) do
    attrs = Map.new(attrs)
    request_id = Map.get(attrs, :request_id, "id_request_123")

    intent =
      Map.merge(
        %{
          request_id: request_id,
          in_response_to: request_id,
          relay_state: relay_state,
          connection_id: Map.get(attrs, :connection_id, "demo"),
          sp_entity_id: "https://sp.example.com/metadata",
          acs_url: "https://sp.example.com/saml/acs",
          return_to: Map.get(attrs, :return_to, "/welcome"),
          expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
        },
        attrs
      )

    :ok = Relyra.RequestStore.ETS.put_intent(relay_state, intent)
    intent
  end

  def build_signed_acs_post!(connection_id, opts \\ []) do
    relay_state = Keyword.get(opts, :relay_state, "rs_adoption_123")
    request_id = Keyword.get(opts, :request_id, "id_request_123")
    subject = Keyword.get(opts, :subject, "alice@example.com")

    builder =
      Relyra.TestSupport.FakeIdP.build_response(
        subject: subject,
        audience: "https://sp.example.com/metadata",
        destination: "https://sp.example.com/saml/acs",
        recipient: "https://sp.example.com/saml/acs",
        in_response_to: request_id,
        relay_state: relay_state,
        name_id: subject
      )

    signed_b64 = Relyra.TestSupport.FakeIdP.sign(builder)

    put_request_intent!(relay_state,
      request_id: request_id,
      connection_id: connection_id,
      return_to: Keyword.get(opts, :return_to, "/welcome")
    )

    %{
      relay_state: relay_state,
      saml_response: signed_b64,
      signed_xml: Base.decode64!(signed_b64, padding: false)
    }
  end

  def read_golden!(parts) do
    Path.join(["test", "fixtures", "demo_host", "golden" | parts])
    |> Path.expand()
    |> File.read!()
  end

  def normalize_install_output(content) do
    content
    |> String.replace("\r\n", "\n")
    |> String.trim()
  end

  def format_for_parity!(content) when is_binary(content) do
    content
    |> String.replace("\r\n", "\n")
    |> then(fn normalized ->
      try do
        normalized
        |> collapse_error_tuple()
        |> then(&(&1 <> "\n"))
        |> Code.format_string!()
        |> collapse_error_tuple()
        |> String.trim()
      rescue
        _ -> normalized |> collapse_error_tuple() |> String.trim()
      end
    end)
  end

  defp collapse_error_tuple(content) do
    Regex.replace(~r/\{:error,\s*\n\s*Relyra\.Error\.new/, "{:error, Relyra.Error.new", content)
  end

  defp keyword_to_connection(connection_id, config) do
    certs = Keyword.fetch!(config, :idp_certificates)

    %Connection{
      id: connection_id,
      connection_id: connection_id,
      sp_entity_id: Keyword.fetch!(config, :sp_entity_id),
      acs_url: Keyword.fetch!(config, :acs_url),
      idp_sso_url: Keyword.fetch!(config, :idp_sso_url),
      idp_entity_id: Keyword.get(config, :idp_entity_id, Keyword.fetch!(config, :sp_entity_id)),
      idp_certificates: certs,
      cert_chain: certs,
      name_id_format: Keyword.get(config, :name_id_format),
      algorithm_policy: Keyword.get(config, :algorithm_policy),
      allow_idp_initiated?: Keyword.get(config, :allow_idp_initiated?, false),
      require_signed_assertions?: Keyword.get(config, :require_signed_assertions?, true),
      require_signed_response?: Keyword.get(config, :require_signed_response?, true),
      provider_preset: Keyword.get(config, :provider_preset),
      sign_authn_requests: Keyword.get(config, :sign_authn_requests, false),
      signed_request_encoding: Keyword.get(config, :signed_request_encoding)
    }
  end
end
