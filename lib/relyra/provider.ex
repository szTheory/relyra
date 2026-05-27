defmodule Relyra.Provider do
  @moduledoc """
  Provider preset registry for known SAML IdPs.

  Presets carry safe defaults, label translations from our internal field
  names to the IdP's admin UI vocabulary, and known-footgun checks. They
  exist so that:

    * adopters get fail-closed defaults that match each IdP's quirks
      (e.g. Microsoft Entra's NameID `:persistent` requirement);
    * admin-channel error hints can speak the IdP's language
      (e.g. "Audience URI" for Okta, "Identifier (Entity ID)" for Entra);
    * footgun checks surface known cross-IdP gotchas before they become
      production incidents.

  ## Shape

  Each preset is a module implementing `Relyra.Provider` callbacks. They
  are pure data — no GenServers, no compile-time magic. The module-per-
  provider shape (Assent's `default_config/1` idiom) plays naturally with
  runtime config:

      config :my_app, :saml_connection,
        provider_preset: :okta,
        sp_entity_id: "https://my.app/sso/metadata",
        ...

  ## Public API

      Relyra.Provider.apply_defaults(:okta, user_keyword)
      Relyra.Provider.translate_label(:okta, :sp_entity_id)
      Relyra.Provider.check_footguns(:okta, %Relyra.Connection{...})
      Relyra.Provider.guide_url(:okta)

  ## Adding a preset

  Create a module that `@behaviour Relyra.Provider` and register its id
  in `@presets` below. Keep `default_config/0` strictly safer-than-spec —
  presets exist to *narrow* the trust surface, never to widen it.
  """

  alias Relyra.Connection

  @typedoc "Internal field name we expose to adopters."
  @type label_key ::
          :sp_entity_id
          | :acs_url
          | :idp_entity_id
          | :idp_sso_url
          | :idp_certificate
          | :name_id_format
          | :signing_algorithm
          | :digest_algorithm

  @typedoc "Per-field translation entry."
  @type label_entry :: %{
          required(:idp_label) => String.t(),
          optional(:idp_section) => String.t() | nil,
          optional(:hint) => String.t() | nil
        }

  @type label_map :: %{label_key() => label_entry()}

  @typedoc """
  Footgun definition. `check.(conn)` returns `:ok` or `{:warn, reason}`.
  Severity guides whether the warning is logged or raised in
  strict-config validation.
  """
  @type footgun :: %{
          required(:id) => atom(),
          required(:severity) => :error | :warning,
          required(:message) => String.t(),
          required(:check) => (Connection.t() -> :ok | {:warn, String.t()})
        }

  @callback id() :: atom()
  @callback display_name() :: String.t()
  @callback default_config() :: keyword()
  @callback labels() :: label_map()
  @callback footguns() :: [footgun()]
  @callback guide_url() :: String.t()

  # Registry is compile-time. New presets must register here explicitly —
  # no auto-discovery. Principle of least surprise: adopters and reviewers
  # can grep one place to see every supported IdP.
  @presets %{
    okta: Relyra.Provider.Okta,
    entra: Relyra.Provider.Entra,
    google_workspace: Relyra.Provider.GoogleWorkspace,
    adfs: Relyra.Provider.ADFS
  }

  @doc "List supported preset ids."
  @spec list() :: [atom()]
  def list, do: Map.keys(@presets) |> Enum.sort()

  @doc """
  Resolve a preset id to its implementing module. Raises if unknown so
  typos fail loudly at config time, not at runtime during a login flow.
  """
  @spec fetch!(atom()) :: module()
  def fetch!(id) when is_atom(id) do
    case Map.fetch(@presets, id) do
      {:ok, module} ->
        module

      :error ->
        raise ArgumentError,
              "unknown Relyra.Provider preset #{inspect(id)}; supported: #{inspect(list())}"
    end
  end

  @doc """
  Merge preset defaults under a user-supplied keyword list. User-supplied
  keys win — presets only fill in what the adopter omitted.

  Returns a keyword list suitable for building a `Relyra.Connection.t()`.
  """
  @spec apply_defaults(atom(), keyword()) :: keyword()
  def apply_defaults(preset_id, user_config) when is_atom(preset_id) and is_list(user_config) do
    module = fetch!(preset_id)
    defaults = module.default_config()

    Keyword.merge(defaults, user_config, fn _key, default_value, user_value ->
      merge_value(default_value, user_value)
    end)
  end

  # Maps merge deeply (so user can override one algorithm key without
  # blowing away the whole policy); everything else is a pure replace.
  defp merge_value(%{} = default, %{} = user), do: Map.merge(default, user)
  defp merge_value(_default, user), do: user

  @doc """
  Bootstrap a preset from an IdP metadata URL.

  The URL is stored as `:idp_metadata_url` and the preset defaults are
  still applied underneath user overrides.
  """
  @spec from_metadata_url(atom(), String.t()) :: keyword()
  def from_metadata_url(preset_id, metadata_url)
      when is_atom(preset_id) and is_binary(metadata_url) do
    apply_defaults(preset_id, idp_metadata_url: metadata_url)
  end

  @doc """
  Translate one of our internal field names to the IdP's admin UI label.
  Falls back to the underscored key as a string when the preset has no
  entry, so missing translations degrade gracefully.
  """
  @spec translate_label(atom(), label_key()) :: String.t()
  def translate_label(preset_id, field) when is_atom(preset_id) and is_atom(field) do
    module = fetch!(preset_id)

    case Map.get(module.labels(), field) do
      %{idp_label: label} when is_binary(label) -> label
      _ -> Atom.to_string(field)
    end
  end

  @doc """
  Return the full label entry (label + section + hint) for a field.
  Use this when building admin error hints so the operator gets the
  IdP's section name and a one-liner hint, not just the label.
  """
  @spec label_entry(atom(), label_key()) :: label_entry() | nil
  def label_entry(preset_id, field) when is_atom(preset_id) and is_atom(field) do
    module = fetch!(preset_id)
    Map.get(module.labels(), field)
  end

  @doc """
  Build an admin-facing hint string suitable for `Relyra.Error` details.
  Returns `nil` when no preset is bound to the connection (adopters
  without a preset get clean errors with no hints injected).
  """
  @spec hint_for(Connection.t() | nil, label_key()) :: String.t() | nil
  def hint_for(%Connection{provider_preset: nil}, _field), do: nil
  def hint_for(%{provider_preset: nil}, _field), do: nil
  def hint_for(nil, _field), do: nil

  def hint_for(%Connection{provider_preset: preset_id}, field) do
    case label_entry(preset_id, field) do
      %{idp_label: label, idp_section: section, hint: hint} ->
        format_hint(label, section, hint)

      %{idp_label: label, idp_section: section} ->
        format_hint(label, section, nil)

      %{idp_label: label} ->
        format_hint(label, nil, nil)

      _ ->
        nil
    end
  end

  def hint_for(%{provider_preset: preset_id}, field) when is_atom(preset_id) do
    case label_entry(preset_id, field) do
      %{idp_label: label, idp_section: section, hint: hint} ->
        format_hint(label, section, hint)

      %{idp_label: label, idp_section: section} ->
        format_hint(label, section, nil)

      %{idp_label: label} ->
        format_hint(label, nil, nil)

      _ ->
        nil
    end
  end

  def hint_for(%{} = _connection, _field), do: nil

  defp format_hint(label, nil, nil), do: "Check '#{label}' in your IdP configuration."

  defp format_hint(label, section, nil) do
    "Check '#{label}' under '#{section}' in your IdP configuration."
  end

  defp format_hint(label, nil, hint) do
    "Check '#{label}' in your IdP configuration. (#{hint})"
  end

  defp format_hint(label, section, hint) do
    "Check '#{label}' under '#{section}' in your IdP configuration. (#{hint})"
  end

  @doc """
  Run every footgun check defined by the preset against a resolved
  connection. Returns a list of results in declaration order; the caller
  decides whether to log warnings, raise errors, or aggregate.

  Footguns whose `check` raises are caught and reported as
  `{:check_failed, id, reason}` so a buggy preset never breaks the
  consume pipeline.
  """
  @spec check_footguns(atom(), Connection.t()) ::
          [:ok | {:warn, atom(), String.t()} | {:check_failed, atom(), term()}]
  def check_footguns(preset_id, %Connection{} = conn) when is_atom(preset_id) do
    module = fetch!(preset_id)

    Enum.map(module.footguns(), fn fg ->
      try do
        case fg.check.(conn) do
          :ok -> :ok
          {:warn, msg} when is_binary(msg) -> {:warn, fg.id, msg}
          other -> {:check_failed, fg.id, {:bad_return, other}}
        end
      rescue
        reason -> {:check_failed, fg.id, reason}
      end
    end)
  end

  @doc "Public guide URL for the preset."
  @spec guide_url(atom()) :: String.t()
  def guide_url(preset_id) when is_atom(preset_id) do
    fetch!(preset_id).guide_url()
  end

  @doc "Display name suitable for log lines and admin UIs."
  @spec display_name(atom()) :: String.t()
  def display_name(preset_id) when is_atom(preset_id) do
    fetch!(preset_id).display_name()
  end
end
