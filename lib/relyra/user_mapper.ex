defmodule Relyra.UserMapper do
  @moduledoc """
  Public extension contract for mapping validated assertion data into user attributes.
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
