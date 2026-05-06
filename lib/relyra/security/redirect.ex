defmodule Relyra.Security.Redirect do
  @moduledoc """
  Security utility for validating redirect paths to prevent Open Redirect vulnerabilities.
  """

  alias Relyra.Error

  @doc """
  Validates a path is a safe local redirect.

  Rejects:
  - Absolute URLs (http://, https://)
  - Protocol-relative URLs (//)
  - Paths not starting with /
  - Nil or non-binary values
  """
  @spec safe_local_redirect(binary() | nil, keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def safe_local_redirect(path, opts \\ [])

  def safe_local_redirect(path, _opts) when is_binary(path) do
    cond do
      String.starts_with?(path, "//") ->
        rejected(:protocol_relative, %{path: path})

      String.starts_with?(path, "http://") or String.starts_with?(path, "https://") ->
        rejected(:absolute_url, %{path: path})

      String.starts_with?(path, "/") ->
        {:ok, path}

      true ->
        rejected(:not_local, %{path: path})
    end
  end

  def safe_local_redirect(nil, _opts) do
    rejected(:nil_path, %{path: nil})
  end

  def safe_local_redirect(_path, _opts) do
    rejected(:non_binary, %{path: :non_binary})
  end

  defp rejected(reason, details) do
    {:error,
     Error.new(
       :invalid_redirect,
       "Redirect path rejected by safety policy",
       Map.put(details, :reason, reason)
     )}
  end
end
