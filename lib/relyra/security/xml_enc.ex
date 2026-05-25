defmodule Relyra.Security.XMLEnc do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Security.AlgorithmPolicy
  alias Relyra.Security.XML.SaxyTree

  @aes128_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes128-gcm"
  @aes256_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes256-gcm"

  @spec decrypt(binary(), module(), keyword()) :: {:ok, binary()} | :decryption_failed
  def decrypt(encrypted_assertion_bytes, key_resolver_module, opts)
      when is_binary(encrypted_assertion_bytes) and is_atom(key_resolver_module) and
             is_list(opts) do
    policy = Keyword.get(opts, :algorithm_policy, AlgorithmPolicy.default())
    connection = Keyword.get(opts, :connection, %{})

    with {:ok, fields} <- parse_enc_fields(encrypted_assertion_bytes),
         :ok <- check_key_transport(policy, fields.key_transport_alg),
         {:ok, content_cipher_bytes} <- b64_decode(fields.content_cipher_value),
         {:ok, _iv, _ciphertext, auth_tag} <- split_cipher_value(content_cipher_bytes),
         :ok <- check_content_encryption(policy, fields.content_alg, auth_tag),
         {:ok, pem} <- resolve_key(key_resolver_module, connection) do
      do_decrypt(fields.key_cipher_value, pem, content_cipher_bytes, fields.content_alg)
    else
      _ -> :decryption_failed
    end
  end

  def decrypt(_bytes, _resolver, _opts), do: :decryption_failed

  # All OTP crypto inside rescue -- mirrors safe_verify/4 discipline in signature.ex.
  # Private key term and PEM binary stay strictly in this function's local scope —
  # never passed to Logger, telemetry, or Error.new/3 details (T-33-02-07).
  defp do_decrypt(key_cipher_b64, pem, content_cipher_bytes, content_alg) do
    with {:ok, encrypted_cek} <- b64_decode(key_cipher_b64),
         {:ok, private_key} <- decode_pem_key(pem),
         {:ok, cek} <- unwrap_cek(encrypted_cek, private_key),
         {:ok, iv, ciphertext, auth_tag} <- split_cipher_value(content_cipher_bytes),
         {:ok, cipher_atom} <- cipher_atom(content_alg) do
      case :crypto.crypto_one_time_aead(cipher_atom, cek, iv, ciphertext, <<>>, auth_tag, false) do
        plaintext when is_binary(plaintext) -> {:ok, plaintext}
        :error -> :decryption_failed
      end
    else
      _ -> :decryption_failed
    end
  rescue
    _ -> :decryption_failed
  end

  defp decode_pem_key(pem) do
    case :public_key.pem_decode(pem) do
      [entry | _] -> {:ok, :public_key.pem_entry_decode(entry)}
      [] -> :decryption_failed
    end
  rescue
    _ -> :decryption_failed
  end

  defp unwrap_cek(encrypted_cek, private_key) do
    {:ok,
     :public_key.decrypt_private(encrypted_cek, private_key, [
       {:rsa_padding, :rsa_pkcs1_oaep_padding}
     ])}
  rescue
    _ -> :decryption_failed
  end

  defp split_cipher_value(bytes) when byte_size(bytes) >= 28 do
    <<iv::binary-12, rest::binary>> = bytes
    ct_size = byte_size(rest) - 16
    <<ciphertext::binary-size(ct_size), auth_tag::binary-16>> = rest
    {:ok, iv, ciphertext, auth_tag}
  end

  defp split_cipher_value(_bytes), do: :decryption_failed

  defp cipher_atom(@aes128_gcm_uri), do: {:ok, :aes_128_gcm}
  defp cipher_atom(@aes256_gcm_uri), do: {:ok, :aes_256_gcm}
  defp cipher_atom(_uri), do: :decryption_failed

  defp b64_decode(value) when is_binary(value) do
    Base.decode64(value, ignore: :whitespace)
  end

  defp b64_decode(_), do: :decryption_failed

  defp check_key_transport(policy, uri) do
    case AlgorithmPolicy.enforce_key_transport_algorithm(policy, uri) do
      :ok -> :ok
      %Error{} -> :decryption_failed
    end
  end

  defp check_content_encryption(policy, uri, auth_tag) do
    case AlgorithmPolicy.enforce_content_encryption_algorithm(policy, uri, auth_tag: auth_tag) do
      :ok -> :ok
      %Error{} -> :decryption_failed
      :decryption_failed -> :decryption_failed
    end
  end

  # Key is sourced exclusively from the key_resolver_module callback (D-05).
  # Document KeyInfo is silently ignored — this is the only code path for key retrieval.
  defp resolve_key(key_resolver_module, connection) do
    case apply(key_resolver_module, :resolve, [connection]) do
      {:ok, pem} when is_binary(pem) -> {:ok, pem}
      _ -> :decryption_failed
    end
  rescue
    _ -> :decryption_failed
  end

  # Parse the raw EncryptedAssertion bytes using SaxyTree — the single hardened
  # parse seam. No secondary parse paths permitted (T-33-02-08).
  defp parse_enc_fields(bytes) do
    with {:ok, root} <- SaxyTree.parse(bytes),
         enc_data when not is_nil(enc_data) <- find_first(root, "EncryptedData"),
         key_info when not is_nil(key_info) <- find_first(enc_data, "KeyInfo"),
         enc_key when not is_nil(enc_key) <- find_first(key_info, "EncryptedKey"),
         key_transport_alg when is_binary(key_transport_alg) <- enc_method_alg(enc_key),
         content_alg when is_binary(content_alg) <- enc_method_alg(enc_data),
         key_cv when is_binary(key_cv) <- cipher_value_text(enc_key),
         content_cv when is_binary(content_cv) <- cipher_value_text(enc_data) do
      {:ok,
       %{
         key_transport_alg: key_transport_alg,
         content_alg: content_alg,
         key_cipher_value: key_cv,
         content_cipher_value: content_cv
       }}
    else
      _ -> :decryption_failed
    end
  end

  defp enc_method_alg(node) do
    em = find_first(node, "EncryptionMethod")

    em &&
      Enum.find_value(em.attrs, fn
        {"Algorithm", v} -> v
        _ -> nil
      end)
  end

  defp cipher_value_text(node) do
    cd = find_first(node, "CipherData")
    cv = cd && find_first(cd, "CipherValue")
    cv && cv.text
  end

  # Depth-first traversal by local element name (prefix-agnostic).
  # Returns the first matching node or nil.
  defp find_first(%{local: local} = node, local), do: node

  defp find_first(%{children: children}, local) do
    Enum.find_value(children, fn child -> find_first(child, local) end)
  end

  defp find_first(_other, _local), do: nil
end
