defmodule Relyra.UserMapper do
  @moduledoc """
  Public extension contract for mapping verified login data into a host-shaped
  user map.

  Relyra owns SAML validation before this seam. On the Phoenix ACS success path,
  `map_attributes/3` receives the verified `%Relyra.LoginResult{}` plus the
  resolved connection that produced it. The mapper can read verified identity
  fields from `login_result.principal`, including `name_id`,
  `name_id_format`, and released attributes.

  The mapper does not establish the session and does not turn Relyra into a
  provisioning engine. It returns the application-shaped user data that the host
  app wants to pass into its later session step.

  The runtime contract remains:

  - Input: verified login result payload plus resolved connection
  - Output: `{:ok, map()}` or `{:error, Relyra.Error.t()}`
  - Next step: `Relyra.SessionAdapter.establish_session/3`

  This seam is for host-owned identity mapping. Local account lookup, linking,
  create-or-update policy, authorization, and lifecycle ownership stay outside
  Relyra core.
  """

  alias Relyra.Error

  # Verification anchor: @callback map_attributes(assertion, connection, opts  [])
  @callback map_attributes(assertion :: map(), connection :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, Error.t()}

  @spec map_attributes(map(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def map_attributes(assertion, connection, opts \\ []) do
    metadata = %{
      connection_id: Map.get(connection, :connection_id) || Map.get(connection, :id),
      flow: :sp_initiated
    }

    Relyra.Telemetry.span([:user, :map], metadata, fn ->
      adapter = Keyword.get(opts, :user_mapper, Relyra.UserMapper.DefaultAttribute)

      result =
        if Code.ensure_loaded?(adapter) and function_exported?(adapter, :map_attributes, 3) do
          adapter.map_attributes(assertion, connection, opts)
        else
          {:error, Error.new(:adapter_not_configured, "User mapper adapter is unavailable")}
        end

      case result do
        {:ok, mapped} ->
          attributes = Map.get(assertion, :attributes, %{})
          attribute_count = if is_map(attributes), do: map_size(attributes), else: 0

          {{:ok, mapped}, Map.merge(metadata, %{outcome: :ok, attribute_count: attribute_count})}

        {:error, %Error{} = error} ->
          {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
      end
    end)
  end
end
