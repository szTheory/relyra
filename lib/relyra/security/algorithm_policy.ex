defmodule Relyra.Security.AlgorithmPolicy do
  @moduledoc false

  alias Relyra.Error

  @sha1_signature_methods MapSet.new([
                            "http://www.w3.org/2000/09/xmldsig#rsa-sha1",
                            "http://www.w3.org/2001/04/xmldsig-more#rsa-sha1"
                          ])

  @sha1_digest_methods MapSet.new([
                         "http://www.w3.org/2000/09/xmldsig#sha1",
                         "http://www.w3.org/2001/04/xmlenc#sha1"
                       ])

  defstruct [:allowed_signature_methods, :allowed_digest_methods, :legacy_sha1]

  @type legacy_sha1_override :: %{
          reason: String.t(),
          expires_at: DateTime.t()
        }

  @type t :: %__MODULE__{
          allowed_signature_methods: [String.t()],
          allowed_digest_methods: [String.t()],
          legacy_sha1: legacy_sha1_override() | nil
        }

  @spec default() :: t()
  def default do
    %__MODULE__{
      allowed_signature_methods: [
        "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256",
        "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384",
        "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512",
        "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256",
        "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha384",
        "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha512"
      ],
      allowed_digest_methods: [
        "http://www.w3.org/2001/04/xmlenc#sha256",
        "http://www.w3.org/2001/04/xmldsig-more#sha384",
        "http://www.w3.org/2001/04/xmlenc#sha512"
      ],
      legacy_sha1: nil
    }
  end

  @spec from_connection(map(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def from_connection(connection, _opts \\ []) do
    # In v0.1 we use default policy unless something is in connection
    case Map.get(connection, :algorithm_policy) do
      %__MODULE__{} = policy -> {:ok, policy}
      _ -> {:ok, default()}
    end
  end

  @spec validate_method(t(), term(), keyword()) :: :ok | {:error, Error.t()}
  def validate_method(policy, method, _opts \\ []) do
    case enforce_signature_method(policy, method) do
      :ok -> :ok
      %Error{} = error -> {:error, error}
    end
  end

  @spec validate_digest(t(), term(), keyword()) :: :ok | {:error, Error.t()}
  def validate_digest(policy, method, _opts \\ []) do
    case enforce_digest_method(policy, method) do
      :ok -> :ok
      %Error{} = error -> {:error, error}
    end
  end

  @spec enforce_signature_method(t(), term()) :: :ok | Error.t()
  def enforce_signature_method(policy, method) do
    if method_allowed?(policy.allowed_signature_methods, method) do
      :ok
    else
      enforce_sha1_policy(policy.legacy_sha1, method, :signature_method, @sha1_signature_methods)
    end
  end

  @spec enforce_digest_method(t(), term()) :: :ok | Error.t()
  def enforce_digest_method(policy, method) do
    if method_allowed?(policy.allowed_digest_methods, method) do
      :ok
    else
      enforce_sha1_policy(policy.legacy_sha1, method, :digest_method, @sha1_digest_methods)
    end
  end

  defp method_allowed?(allowed_methods, method)
       when is_binary(method) and is_list(allowed_methods) do
    Enum.member?(allowed_methods, method)
  end

  defp method_allowed?(_allowed_methods, _method), do: false

  defp enforce_sha1_policy(legacy_sha1, method, method_type, sha1_methods)
       when is_binary(method) do
    if MapSet.member?(sha1_methods, method) do
      enforce_legacy_override(legacy_sha1, method, method_type)
    else
      deprecated_algorithm(method, method_type)
    end
  end

  defp enforce_sha1_policy(_legacy_sha1, method, method_type, _sha1_methods) do
    deprecated_algorithm(method, method_type)
  end

  defp enforce_legacy_override(
         %{reason: reason, expires_at: %DateTime{} = expires_at},
         method,
         method_type
       )
       when is_binary(reason) and byte_size(reason) > 0 do
    case DateTime.compare(expires_at, DateTime.utc_now()) do
      :gt ->
        :ok

      _ ->
        Error.new(
          :legacy_algorithm_override_expired,
          "Legacy SHA-1 override has expired",
          %{
            algorithm: method,
            algorithm_type: method_type,
            reason: reason,
            expires_at: expires_at
          }
        )
    end
  end

  defp enforce_legacy_override(_legacy_sha1, method, method_type) do
    deprecated_algorithm(method, method_type)
  end

  defp deprecated_algorithm(method, method_type) do
    Error.new(
      :deprecated_algorithm,
      "Algorithm is not allowed by strict policy",
      %{
        algorithm: method,
        algorithm_type: method_type,
        policy: :sha256_plus_default
      }
    )
  end
end
