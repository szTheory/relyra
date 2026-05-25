defmodule Relyra.KeyResolver.Default do
  @moduledoc false

  @behaviour Relyra.KeyResolver

  alias Relyra.Error

  @impl true
  @spec resolve(map()) :: {:ok, binary()} | {:error, Error.t()}
  def resolve(connection) when is_map(connection) do
    case Application.get_env(:relyra, :sp_private_key_pem) do
      nil ->
        {:error,
         Error.new(:key_not_configured, "SP decryption private key is not configured", %{
           hint:
             "Set config :relyra, :sp_private_key_pem to the PEM binary of the SP RSA private key"
         })}

      pem when is_binary(pem) ->
        {:ok, pem}

      _other ->
        {:error,
         Error.new(:key_not_configured, "SP decryption private key is not configured", %{
           hint:
             "Set config :relyra, :sp_private_key_pem to the PEM binary of the SP RSA private key"
         })}
    end
  end

  def resolve(_connection) do
    {:error,
     Error.new(:key_not_configured, "SP decryption private key is not configured", %{
       hint: "Set config :relyra, :sp_private_key_pem to the PEM binary of the SP RSA private key"
     })}
  end
end
