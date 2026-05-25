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

  @doc """
  Map a signature-method URI to the digest atom the verifier recomputes with (D-06),
  failing CLOSED for ECDSA and any unknown / non-binary input (D-07, Pitfall 5).

  This is the single source of truth for which hash drives the reference-digest
  recompute in Plan 03. ECDSA is rejected here BEFORE any verify attempt — the
  `default/0` allowlist still permits ECDSA URIs (for SHA-2 strength), so this
  explicit reject is what prevents the RFC 6931 r‖s-vs-DER fail-OPEN (T-29-04).
  Returns the bare `{:ok, atom} | {:error, :unsupported_signature_algorithm}`
  shape; Plan 03 wraps the error in a typed `%Relyra.Error{}`.
  """
  @spec digest_atom_for_signature_method(term()) ::
          {:ok, :sha256 | :sha384 | :sha512} | {:error, :unsupported_signature_algorithm}
  def digest_atom_for_signature_method(uri) when is_binary(uri) do
    cond do
      # D-07: any ECDSA URI fails CLOSED, checked BEFORE the rsa-sha* suffix match
      # (so an "...#ecdsa-sha256" can never fall through to a digest atom).
      String.contains?(uri, "ecdsa") -> {:error, :unsupported_signature_algorithm}
      String.ends_with?(uri, "rsa-sha256") -> {:ok, :sha256}
      String.ends_with?(uri, "rsa-sha384") -> {:ok, :sha384}
      String.ends_with?(uri, "rsa-sha512") -> {:ok, :sha512}
      true -> {:error, :unsupported_signature_algorithm}
    end
  end

  def digest_atom_for_signature_method(_uri), do: {:error, :unsupported_signature_algorithm}

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
