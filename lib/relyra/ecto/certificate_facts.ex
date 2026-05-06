defmodule Relyra.Ecto.CertificateFacts do
  @moduledoc false

  alias Relyra.Error

  @spec extract(binary()) ::
          {:ok, %{not_before: DateTime.t(), not_after: DateTime.t()}} | {:error, Error.t()}
  def extract(pem) when is_binary(pem) do
    with {:ok, entry} <- pem_entry(pem),
         {:ok, validity} <- validity(entry),
         {:ok, not_before} <- decode_time(elem(validity, 1)),
         {:ok, not_after} <- decode_time(elem(validity, 2)) do
      {:ok, %{not_before: not_before, not_after: not_after}}
    end
  end

  def extract(_pem) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Certificate PEM must be a binary",
       %{reason: :invalid_certificate_pem}
     )}
  end

  defp pem_entry(pem) do
    case :public_key.pem_decode(pem) do
      [entry | _rest] ->
        {:ok, :public_key.pem_entry_decode(entry)}

      [] ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "Certificate PEM could not be decoded",
           %{reason: :invalid_certificate_pem}
         )}
    end
  rescue
    _error ->
      {:error,
       Error.new(
         :invalid_connection_record,
         "Certificate PEM could not be decoded",
         %{reason: :invalid_certificate_pem}
       )}
  end

  defp validity({:Certificate, {:TBSCertificate, _, _, _, _, validity, _, _, _, _, _}, _, _}),
    do: {:ok, validity}

  defp validity(_) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Certificate validity could not be decoded",
       %{reason: :invalid_certificate_pem}
     )}
  end

  defp decode_time({:utcTime, value}), do: decode_utc_time(List.to_string(value))
  defp decode_time({:generalTime, value}), do: decode_general_time(List.to_string(value))

  defp decode_time(_value) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Certificate time encoding is unsupported",
       %{reason: :invalid_certificate_pem}
     )}
  end

  defp decode_utc_time(
         <<year::binary-size(2), month::binary-size(2), day::binary-size(2),
           hour::binary-size(2), minute::binary-size(2), second::binary-size(2), "Z">>
       ) do
    year_int = String.to_integer(year)
    full_year = if year_int < 50, do: 2000 + year_int, else: 1900 + year_int
    to_datetime(full_year, month, day, hour, minute, second)
  end

  defp decode_utc_time(_value) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Certificate UTC time could not be parsed",
       %{reason: :invalid_certificate_pem}
     )}
  end

  defp decode_general_time(
         <<year::binary-size(4), month::binary-size(2), day::binary-size(2),
           hour::binary-size(2), minute::binary-size(2), second::binary-size(2), "Z">>
       ) do
    to_datetime(String.to_integer(year), month, day, hour, minute, second)
  end

  defp decode_general_time(_value) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Certificate generalized time could not be parsed",
       %{reason: :invalid_certificate_pem}
     )}
  end

  defp to_datetime(year, month, day, hour, minute, second) do
    with {:ok, date} <-
           Date.new(year, String.to_integer(month), String.to_integer(day)),
         {:ok, time} <-
           Time.new(
             String.to_integer(hour),
             String.to_integer(minute),
             String.to_integer(second),
             0
           ),
         {:ok, datetime} <- DateTime.new(date, time, "Etc/UTC") do
      {:ok, datetime}
    else
      _error ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "Certificate time could not be converted to UTC",
           %{reason: :invalid_certificate_pem}
         )}
    end
  end
end
