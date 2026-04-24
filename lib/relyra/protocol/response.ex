defmodule Relyra.Protocol.Response do
  @moduledoc false

  alias Relyra.Error

  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"

  @spec validate_issuer(term(), term()) :: :ok | {:error, Error.t()}
  def validate_issuer(actual_issuer, expected_issuer) do
    if normalize(actual_issuer) == normalize(expected_issuer) do
      :ok
    else
      {:error,
       Error.new(
         :issuer_mismatch,
         "Response issuer does not match configured issuer",
         expected_actual_details(expected_issuer, actual_issuer)
       )}
    end
  end

  @spec validate_status(term()) :: :ok | {:error, Error.t()}
  def validate_status(status) do
    if normalize(status) == @success_status do
      :ok
    else
      {:error,
       Error.new(
         :unsupported_status,
         "Only SAML success responses are supported",
         expected_actual_details(@success_status, status)
       )}
    end
  end

  @spec validate_destination(term(), term()) :: :ok | {:error, Error.t()}
  def validate_destination(actual_destination, expected_destination) do
    if normalize(actual_destination) == normalize(expected_destination) do
      :ok
    else
      {:error,
       Error.new(
         :destination_mismatch,
         "Response destination does not match expected ACS destination",
         expected_actual_details(expected_destination, actual_destination)
       )}
    end
  end

  @spec validate_connection_binding(term(), term()) :: :ok | {:error, Error.t()}
  def validate_connection_binding(actual_connection_id, expected_connection_id) do
    if normalize(actual_connection_id) == normalize(expected_connection_id) do
      :ok
    else
      {:error,
       Error.new(
         :connection_binding_mismatch,
         "Response connection binding does not match request intent",
         expected_actual_details(expected_connection_id, actual_connection_id)
       )}
    end
  end

  defp normalize(value) when is_binary(value), do: value
  defp normalize(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize(value) when is_integer(value), do: Integer.to_string(value)
  defp normalize(value), do: value

  defp expected_actual_details(expected, actual) do
    %{
      expected: normalize(expected),
      actual: normalize(actual)
    }
  end
end
