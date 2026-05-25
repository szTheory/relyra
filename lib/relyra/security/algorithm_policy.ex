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

  @rsa_pkcs1_uri "http://www.w3.org/2001/04/xmlenc#rsa-1_5"

  @aes_cbc_uris MapSet.new([
                  "http://www.w3.org/2001/04/xmlenc#aes128-cbc",
                  "http://www.w3.org/2001/04/xmlenc#aes256-cbc"
                ])

  defstruct [
    :allowed_signature_methods,
    :allowed_digest_methods,
    :legacy_sha1,
    :allowed_key_transport_algorithms,
    :allowed_content_encryption_algorithms,
    :legacy_aes_cbc
  ]

  @type legacy_sha1_override :: %{
          reason: String.t(),
          expires_at: DateTime.t()
        }

  @type legacy_aes_cbc_override :: %{
          reason: String.t(),
          expires_at: DateTime.t()
        }

  @type t :: %__MODULE__{
          allowed_signature_methods: [String.t()],
          allowed_digest_methods: [String.t()],
          legacy_sha1: legacy_sha1_override() | nil,
          allowed_key_transport_algorithms: [String.t()],
          allowed_content_encryption_algorithms: [String.t()],
          legacy_aes_cbc: legacy_aes_cbc_override() | nil
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
      legacy_sha1: nil,
      allowed_key_transport_algorithms: [
        "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
      ],
      allowed_content_encryption_algorithms: [
        "http://www.w3.org/2001/04/xmlenc#aes128-gcm",
        "http://www.w3.org/2001/04/xmlenc#aes256-gcm"
      ],
      legacy_aes_cbc: nil
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

  @spec enforce_key_transport_algorithm(t(), term()) :: :ok | Error.t()
  def enforce_key_transport_algorithm(_policy, @rsa_pkcs1_uri) do
    Error.new(
      :deprecated_algorithm,
      "RSA-PKCS1v1.5 key transport is permanently blocked — no escape hatch",
      %{algorithm: @rsa_pkcs1_uri, algorithm_type: :key_transport_algorithm}
    )
  end

  def enforce_key_transport_algorithm(policy, method) do
    if method_allowed?(policy.allowed_key_transport_algorithms, method) do
      :ok
    else
      deprecated_algorithm(method, :key_transport_algorithm)
    end
  end

  @spec enforce_content_encryption_algorithm(t(), term(), keyword()) ::
          :ok | Error.t() | :decryption_failed
  def enforce_content_encryption_algorithm(policy, method, opts \\ []) do
    auth_tag = Keyword.get(opts, :auth_tag)

    cond do
      # D-03: auth tag guard fires FIRST — before allowlist and AES-CBC hatch checks.
      # Returns opaque atom :decryption_failed (never an %Error{}) to prevent padding oracle.
      is_binary(auth_tag) and byte_size(auth_tag) < 16 ->
        :decryption_failed

      method_allowed?(policy.allowed_content_encryption_algorithms, method) ->
        :ok

      # D-05: AES-CBC may be allowed via legacy_aes_cbc hatch (mirrors legacy_sha1 pattern)
      MapSet.member?(@aes_cbc_uris, method) ->
        enforce_legacy_override(policy.legacy_aes_cbc, method, :content_encryption_algorithm)

      true ->
        deprecated_algorithm(method, :content_encryption_algorithm)
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
        label =
          case method_type do
            :content_encryption_algorithm -> "AES-CBC"
            _ -> "SHA-1"
          end

        Error.new(
          :legacy_algorithm_override_expired,
          "Legacy #{label} override has expired",
          %{
            algorithm: method,
            algorithm_type: method_type,
            reason: reason,
            expires_at: expires_at
          }
        )
    end
  end

  defp enforce_legacy_override(_legacy_override, method, method_type) do
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
