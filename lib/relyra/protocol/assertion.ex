defmodule Relyra.Protocol.Assertion do
  @moduledoc false

  alias Relyra.Error

  @default_skew_seconds 120

  @spec validate_audience(term(), term()) :: :ok | {:error, Error.t()}
  def validate_audience(actual_audiences, expected_audience) do
    normalized_expected = normalize(expected_audience)
    normalized_audiences = normalize_audiences(actual_audiences)

    if normalized_expected in normalized_audiences do
      :ok
    else
      {:error,
       Error.new(
         :invalid_audience,
         "Assertion audience does not include expected audience",
         %{
           expected: normalized_expected,
           actual: normalized_audiences
         }
       )}
    end
  end

  @spec validate_recipient(term(), term()) :: :ok | {:error, Error.t()}
  def validate_recipient(actual_recipient, expected_recipient) do
    if normalize(actual_recipient) == normalize(expected_recipient) do
      :ok
    else
      {:error,
       Error.new(
         :recipient_mismatch,
         "Assertion recipient does not match expected ACS recipient",
         %{
           expected: normalize(expected_recipient),
           actual: normalize(actual_recipient)
         }
       )}
    end
  end

  @spec validate_time_conditions(map(), DateTime.t(), keyword()) :: :ok | {:error, Error.t()}
  def validate_time_conditions(assertion_times, now, opts \\ [])

  def validate_time_conditions(assertion_times, %DateTime{} = now, opts)
      when is_map(assertion_times) do
    case normalize_skew(opts) do
      {:ok, skew_seconds} ->
        with {:ok, not_before} <- fetch_datetime(assertion_times, :not_before),
             {:ok, not_on_or_after} <- fetch_datetime(assertion_times, :not_on_or_after),
             {:ok, subject_confirmation_not_on_or_after} <-
               fetch_datetime(assertion_times, :subject_confirmation_not_on_or_after),
             :ok <- validate_not_before(not_before, now, skew_seconds),
             :ok <- validate_not_on_or_after(not_on_or_after, now, skew_seconds),
             :ok <-
               validate_subject_confirmation_not_on_or_after(
                 subject_confirmation_not_on_or_after,
                 now,
                 skew_seconds
               ) do
          :ok
        end

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  def validate_time_conditions(_assertion_times, _now, _opts) do
    {:error,
     Error.new(
       :clock_skew_exceeded,
       "Assertion time conditions must be map/date-time inputs",
       %{expected: %{assertion_times: :map, now: :datetime}, actual: :invalid_inputs}
     )}
  end

  defp validate_not_before(not_before, now, skew_seconds) do
    threshold = DateTime.add(now, skew_seconds, :second)

    case DateTime.compare(not_before, threshold) do
      :gt ->
        {:error,
         Error.new(
           :assertion_not_yet_valid,
           "Assertion NotBefore is outside accepted clock skew window",
           %{
             expected: DateTime.to_iso8601(threshold),
             actual: DateTime.to_iso8601(not_before)
           }
         )}

      _ ->
        :ok
    end
  end

  defp validate_not_on_or_after(not_on_or_after, now, skew_seconds) do
    threshold = DateTime.add(not_on_or_after, skew_seconds, :second)

    case DateTime.compare(now, threshold) do
      :gt ->
        {:error,
         Error.new(
           :assertion_expired,
           "Assertion NotOnOrAfter is outside accepted clock skew window",
           %{
             expected: DateTime.to_iso8601(threshold),
             actual: DateTime.to_iso8601(now)
           }
         )}

      _ ->
        :ok
    end
  end

  defp validate_subject_confirmation_not_on_or_after(
         subject_confirmation_not_on_or_after,
         now,
         skew_seconds
       ) do
    threshold = DateTime.add(subject_confirmation_not_on_or_after, skew_seconds, :second)

    case DateTime.compare(now, threshold) do
      :gt ->
        {:error,
         Error.new(
           :subject_confirmation_expired,
           "SubjectConfirmationData.NotOnOrAfter is outside accepted clock skew window",
           %{
             expected: DateTime.to_iso8601(threshold),
             actual: DateTime.to_iso8601(now)
           }
         )}

      _ ->
        :ok
    end
  end

  defp normalize_skew(opts) do
    skew_seconds = Keyword.get(opts, :skew_seconds, @default_skew_seconds)

    if is_integer(skew_seconds) and skew_seconds >= 0 do
      {:ok, skew_seconds}
    else
      {:error,
       Error.new(
         :clock_skew_exceeded,
         "Clock skew must be a non-negative integer",
         %{expected: :non_negative_integer, actual: skew_seconds}
       )}
    end
  end

  defp fetch_datetime(assertion_times, key) do
    value =
      Map.get(assertion_times, key) ||
        Map.get(assertion_times, Atom.to_string(key))

    parse_datetime(value, key)
  end

  defp parse_datetime(%DateTime{} = datetime, _key), do: {:ok, datetime}

  defp parse_datetime(value, key) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        {:ok, datetime}

      _ ->
        {:error,
         Error.new(
           :clock_skew_exceeded,
           "Assertion time condition must be an ISO8601 datetime",
           %{
             expected: key,
             actual: value
           }
         )}
    end
  end

  defp parse_datetime(value, key) do
    {:error,
     Error.new(
       :clock_skew_exceeded,
       "Assertion time condition is missing or invalid",
       %{
         expected: key,
         actual: value
       }
     )}
  end

  defp normalize_audiences(value) when is_binary(value), do: [value]

  defp normalize_audiences(values) when is_list(values) do
    values
    |> Enum.map(&normalize/1)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_audiences(_value), do: []

  defp normalize(value) when is_binary(value), do: value
  defp normalize(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize(value), do: value
end
