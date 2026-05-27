defmodule Relyra.ProviderTest do
  use ExUnit.Case, async: true

  alias Relyra.Connection
  alias Relyra.Provider

  test "supported preset ids are registered" do
    assert Provider.list() == [:adfs, :entra, :google_workspace, :okta]
    assert Provider.fetch!(:adfs) == Relyra.Provider.ADFS
    assert Provider.fetch!(:okta) == Relyra.Provider.Okta
    assert Provider.fetch!(:entra) == Relyra.Provider.Entra
    assert Provider.fetch!(:google_workspace) == Relyra.Provider.GoogleWorkspace
  end

  test "apply_defaults/2 keeps user values" do
    config =
      Provider.apply_defaults(:okta,
        sp_entity_id: "https://sp.example.com/metadata",
        allow_idp_initiated?: true
      )

    assert Keyword.fetch!(config, :provider_preset) == :okta
    assert Keyword.fetch!(config, :sp_entity_id) == "https://sp.example.com/metadata"
    assert Keyword.fetch!(config, :allow_idp_initiated?) == true
    assert Keyword.fetch!(config, :require_signed_response?) == true
  end

  test "translate_label/2 uses IdP labels" do
    assert Provider.translate_label(:adfs, :sp_entity_id) == "Relying Party Trust Identifier"
    assert Provider.translate_label(:adfs, :idp_certificate) == "Token-signing certificate"
    assert Provider.translate_label(:okta, :sp_entity_id) == "Audience URI (SP Entity ID)"
    assert Provider.translate_label(:entra, :sp_entity_id) == "Identifier (Entity ID)"
  end

  test "apply_defaults/2 returns ADFS-specific defaults" do
    config = Provider.apply_defaults(:adfs, sp_entity_id: "https://sp.example.com/metadata")

    assert Keyword.fetch!(config, :provider_preset) == :adfs
    assert Keyword.fetch!(config, :sign_authn_requests) == true
    assert Keyword.fetch!(config, :signed_request_encoding) == :adfs_lower
    assert Keyword.fetch!(config, :require_signed_assertions?) == true
    assert Provider.guide_url(:adfs) =~ "learn.microsoft.com"
  end

  test "from_metadata_url/2 preserves preset defaults and records metadata URL" do
    config = Provider.from_metadata_url(:okta, "https://idp.example.com/metadata")

    assert Keyword.fetch!(config, :provider_preset) == :okta
    assert Keyword.fetch!(config, :idp_metadata_url) == "https://idp.example.com/metadata"
    assert Keyword.fetch!(config, :allow_idp_initiated?) == false
  end

  test "hint_for/2 returns admin-facing guidance" do
    connection = %Connection{provider_preset: :okta}

    assert Provider.hint_for(connection, :sp_entity_id) =~ "Audience URI (SP Entity ID)"
  end

  test "check_footguns/2 reports warnings for risky settings" do
    connection = %Connection{
      provider_preset: :okta,
      algorithm_policy: %{signing: :rsa_sha1},
      allow_idp_initiated?: true
    }

    results = Provider.check_footguns(:okta, connection)

    assert Enum.any?(results, &match?({:warn, :okta_sha1, _}, &1))
    assert Enum.any?(results, &match?({:warn, :okta_idp_initiated, _}, &1))
  end

  test "validate_audience/3 includes provider hint in the error details" do
    connection = %Connection{provider_preset: :okta}

    assert {:error, %Relyra.Error{details: details}} =
             Relyra.Protocol.Assertion.validate_audience(
               ["https://wrong.example.com/metadata"],
               "https://sp.example.com/metadata",
               connection
             )

    assert details.provider_hint =~ "Audience URI (SP Entity ID)"
  end
end
