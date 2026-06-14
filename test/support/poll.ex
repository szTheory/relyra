defmodule Relyra.TestSupport.Poll do
  @moduledoc false

  @doc """
  Retry `fun` until it returns `:ok`, sleeping `sleep_ms` between attempts.

  Mirrors `Mix.Tasks.Verify.ReleaseParity.retry_until!/4` for test and CI probes.
  """
  @spec retry_until!(String.t(), pos_integer(), non_neg_integer(), (-> :ok | {:error, term()})) ::
          :ok | no_return()
  def retry_until!(label, attempts, sleep_ms, fun) when is_function(fun, 0) do
    Enum.reduce_while(1..attempts, nil, fn attempt, _acc ->
      case fun.() do
        :ok ->
          {:halt, :ok}

        {:error, reason} when attempt < attempts ->
          IO.puts(:stderr, "#{label} (attempt #{attempt}/#{attempts}): #{format_reason(reason)}")
          Process.sleep(sleep_ms)
          {:cont, nil}

        {:error, reason} ->
          raise "#{label} failed after #{attempts} attempts\n\n#{format_reason(reason)}"
      end
    end)
  end

  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason), do: inspect(reason)
end
