defmodule Relyra.Testing do
  @moduledoc """
  Public framework-neutral testing fixtures for Relyra adopters.

  The helpers in this namespace produce explicit testing fixture data for the
  real verifier path. They do not mutate application environment, persistent
  terms, ETS tables, or production resolver state.
  """

  alias Relyra.Connection
  alias Relyra.Testing.Fixture
  alias Relyra.Testing.Signer

  @default_connection_id "conn-123"
  @default_sp_entity_id "https://sp.example.com/metadata"
  @default_acs_url "https://sp.example.com/saml/acs"
  @default_idp_entity_id "https://idp.example.com/metadata"
  @default_name_id "user@example.com"
  @default_relay_state "rs_1234567890abcdef"
  @default_request_id "id_request_123"
  @default_assertion_id "assertion-1"
  @default_not_before "2000-01-01T00:00:00Z"
  @default_not_on_or_after "2099-01-01T00:00:00Z"

  @type consume_opt :: {atom(), term()}

  @doc """
  Builds a signed success testing fixture.

  The fixture contains a signed test response, Base64 POST payload, matching
  test certificate, connection, request intent, relay state, and expected
  outcome. It is test-only data for the real verifier path; it is not an IdP,
  broker, or production trust source.
  """
  @spec signed_success(keyword()) :: Fixture.t()
  def signed_success(opts \\ []) when is_list(opts) do
    fields = signed_success_fields(opts)

    signed =
      Signer.signed_response(
        connection_id: fields.connection_id,
        issuer: fields.issuer,
        destination: fields.acs_url,
        recipient: fields.acs_url,
        audience: fields.sp_entity_id,
        name_id: fields.name_id,
        in_response_to: fields.request_id,
        assertion_id: fields.assertion_id,
        not_before: fields.not_before,
        not_on_or_after: fields.not_on_or_after,
        subject_confirmation_not_on_or_after: fields.subject_confirmation_not_on_or_after
      )

    fixture(fields, signed.response_xml, signed.cert_chain, {:ok, :verified})
  end

  @doc """
  Builds a signed fixture whose assertion audience differs from the configured SP audience.
  """
  @spec wrong_audience(keyword()) :: Fixture.t()
  def wrong_audience(opts \\ []) when is_list(opts) do
    expected_audience = Keyword.get(opts, :expected_audience, @default_sp_entity_id)
    actual_audience = Keyword.get(opts, :actual_audience, "https://wrong-audience.example.com")

    if actual_audience == expected_audience do
      raise ArgumentError,
            "Relyra.Testing.wrong_audience/1 requires :actual_audience to differ from :expected_audience"
    end

    fields = signed_success_fields(Keyword.put(opts, :sp_entity_id, expected_audience))

    signed =
      signed_response(fields,
        audience: actual_audience,
        assertion_id: fields.assertion_id
      )

    fixture(fields, signed.response_xml, signed.cert_chain, {:error, :invalid_audience})
  end

  @doc """
  Builds a signed fixture whose signed assertion content is mutated after signing.
  """
  @spec tampered_digest(keyword()) :: Fixture.t()
  def tampered_digest(opts \\ []) when is_list(opts) do
    fields = signed_success_fields(opts)
    tampered_name_id = Keyword.get(opts, :tampered_name_id, "tampered@example.com")
    signed = signed_response(fields)

    response_xml =
      Signer.tamper_name_id!(
        signed.response_xml,
        fields.name_id,
        tampered_name_id
      )

    fixture(fields, response_xml, signed.cert_chain, {:error, :digest_mismatch})
  end

  @doc """
  Builds a signed fixture whose returned trust material does not match the signing key.
  """
  @spec invalid_signature(keyword()) :: Fixture.t()
  def invalid_signature(opts \\ []) when is_list(opts) do
    fields = signed_success_fields(opts)
    signed = signed_response(fields)

    wrong_key_signed =
      signed_response(%{fields | assertion_id: "#{fields.assertion_id}-wrong-key"})

    fixture(
      fields,
      signed.response_xml,
      wrong_key_signed.cert_chain,
      {:error, :invalid_signature}
    )
  end

  @doc """
  Builds POST parameters for a testing fixture.

  By default this returns `%{"SAMLResponse" => fixture.encoded_response}` and
  includes `"RelayState"` only when the fixture has a non-empty relay state.
  """
  @spec post_params(Fixture.t(), keyword()) :: map()
  def post_params(%Fixture{} = fixture, opts \\ []) when is_list(opts) do
    saml_response_key = Keyword.get(opts, :saml_response_key, "SAMLResponse")
    relay_state_key = Keyword.get(opts, :relay_state_key, "RelayState")

    %{saml_response_key => fixture.encoded_response}
    |> maybe_put_relay_state(relay_state_key, fixture.relay_state)
  end

  @doc """
  Builds `Relyra.consume_response/3` options for a testing fixture.

  The returned options use public `Relyra.Testing.Adapters.*` modules and thread
  all trust/correlation inputs through explicit fixture data.
  """
  @spec consume_opts(Fixture.t(), keyword()) :: [consume_opt()]
  def consume_opts(%Fixture{} = fixture, opts \\ []) when is_list(opts) do
    [
      connection: fixture.connection,
      resolved_connection: fixture.connection,
      relay_state: fixture.relay_state,
      request_store: Relyra.Testing.Adapters.RequestStore,
      replay_store: Relyra.Testing.Adapters.ReplayStore,
      connection_resolver: Relyra.Testing.Adapters.ConnectionResolver,
      request_intent: fixture.request_intent
    ]
    |> Keyword.merge(opts)
  end

  defp maybe_put_relay_state(params, _key, nil), do: params
  defp maybe_put_relay_state(params, _key, ""), do: params
  defp maybe_put_relay_state(params, key, relay_state), do: Map.put(params, key, relay_state)

  defp signed_success_fields(opts) do
    idp_entity_id = Keyword.get(opts, :idp_entity_id, @default_idp_entity_id)
    issuer = Keyword.get(opts, :issuer, idp_entity_id)
    not_on_or_after = Keyword.get(opts, :not_on_or_after, @default_not_on_or_after)

    %{
      connection_id: Keyword.get(opts, :connection_id, @default_connection_id),
      sp_entity_id: Keyword.get(opts, :sp_entity_id, @default_sp_entity_id),
      acs_url: Keyword.get(opts, :acs_url, @default_acs_url),
      idp_entity_id: idp_entity_id,
      issuer: issuer,
      name_id: Keyword.get(opts, :name_id, @default_name_id),
      relay_state: Keyword.get(opts, :relay_state, @default_relay_state),
      request_id: Keyword.get(opts, :request_id, @default_request_id),
      assertion_id: Keyword.get(opts, :assertion_id, @default_assertion_id),
      not_before: Keyword.get(opts, :not_before, @default_not_before),
      not_on_or_after: not_on_or_after,
      subject_confirmation_not_on_or_after:
        Keyword.get(opts, :subject_confirmation_not_on_or_after, not_on_or_after)
    }
  end

  defp signed_response(fields, overrides \\ []) do
    Signer.signed_response(
      connection_id: fields.connection_id,
      issuer: fields.issuer,
      destination: fields.acs_url,
      recipient: fields.acs_url,
      audience: Keyword.get(overrides, :audience, fields.sp_entity_id),
      name_id: fields.name_id,
      in_response_to: fields.request_id,
      assertion_id: Keyword.get(overrides, :assertion_id, fields.assertion_id),
      not_before: fields.not_before,
      not_on_or_after: fields.not_on_or_after,
      subject_confirmation_not_on_or_after: fields.subject_confirmation_not_on_or_after
    )
  end

  defp fixture(fields, response_xml, cert_chain, expected) do
    %Fixture{
      response_xml: response_xml,
      encoded_response: Base.encode64(response_xml),
      cert_chain: cert_chain,
      idp_certificates: cert_chain,
      connection: connection(fields, cert_chain),
      request_intent: request_intent(fields),
      relay_state: fields.relay_state,
      expected: expected
    }
  end

  defp connection(fields, cert_chain) do
    %Connection{
      id: fields.connection_id,
      connection_id: fields.connection_id,
      idp_entity_id: fields.issuer,
      sp_entity_id: fields.sp_entity_id,
      acs_url: fields.acs_url,
      idp_certificates: cert_chain,
      cert_chain: cert_chain
    }
  end

  defp request_intent(fields) do
    %{
      request_id: fields.request_id,
      connection_id: fields.connection_id,
      relay_state: fields.relay_state,
      in_response_to: fields.request_id,
      destination: fields.acs_url,
      recipient: fields.acs_url,
      issuer: fields.issuer,
      sp_entity_id: fields.sp_entity_id,
      acs_url: fields.acs_url
    }
  end
end
