defmodule Relyra do
  @moduledoc """
  Public entry points for strict-by-default SAML protocol flows.
  """

  alias Relyra.Protocol.AuthnRequest
  alias Relyra.Protocol.Binding
  alias Relyra.Security.RelayState

  @spec start_login(map(), map(), keyword()) :: {:ok, map()} | {:error, Relyra.Error.t()}
  def start_login(connection, relay_context, opts \\ []) do
    with {:ok, request_fields} <- AuthnRequest.build(connection, relay_context, opts),
         request_id <- Map.fetch!(request_fields, :id),
         authn_request_xml <- AuthnRequest.to_xml(request_fields),
         {:ok, relay_state} <- RelayState.issue(Map.put(relay_context, :request_id, request_id), opts),
         {:ok, redirect_params} <- Binding.encode_redirect(authn_request_xml, relay_state) do
      {:ok,
       %{
         request_id: request_id,
         authn_request: authn_request_xml,
         relay_state: relay_state,
         redirect_params: redirect_params
       }}
    end
  end
end
