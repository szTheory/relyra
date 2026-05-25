defmodule Relyra.Protocol.ValidationPipeline do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Security.SignedNode
  alias Relyra.Security.XML.SaxyTree.Node

  @ordered_stages [
    :parse_safely,
    :issuer_connection_match,
    :signature_verify,
    :signed_node_bind,
    :status,
    :destination,
    :audience,
    :recipient,
    :time_conditions
  ]

  def ordered_stages, do: @ordered_stages

  @spec run(binary(), map() | nil, map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  # Verification anchor: def run(response_payload, request_intent, connection, opts \ [])
  def run(response_payload, request_intent, connection, opts \\ [])

  def run(response_payload, request_intent, connection, opts)
      when is_binary(response_payload) and (is_map(request_intent) or is_nil(request_intent)) and
             is_map(connection) and
             is_list(opts) do
    metadata = %{
      connection_id: expected_connection_id(request_intent, connection),
      flow: if(is_nil(request_intent), do: :idp_initiated, else: :sp_initiated)
    }

    Relyra.Telemetry.span([:response, :validate], metadata, fn ->
      result = do_run(response_payload, request_intent, connection, opts)

      case result do
        {:ok, login_result, assertion_count} ->
          {{:ok, login_result},
           Map.merge(metadata, %{outcome: :ok, assertion_count: assertion_count})}

        {:error, %Error{} = error, assertion_count} ->
          {{:error, error},
           Map.merge(metadata, %{
             outcome: :error,
             error_code: error.type,
             assertion_count: assertion_count
           })}
      end
    end)
  end

  def run(_response_payload, _request_intent, _connection, _opts) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "ValidationPipeline.run/4 received invalid arguments",
       %{}
     )}
  end

  defp do_run(response_payload, request_intent, connection, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    cert_chain = cert_chain(connection, opts)

    case Relyra.Security.XML.PureBeam.parse_safely(response_payload, parse_opts(opts)) do
      {:ok, parsed_doc} ->
        # :decrypt_assertion pre-stage (D-01): detect EncryptedAssertion from the
        # OUTER parse tree, reject the cleartext+encrypted ambiguity BEFORE any
        # crypto (D-03), decrypt a single EncryptedAssertion via the unchanged
        # XMLEnc.decrypt/3, string-splice the plaintext into the Response binary,
        # and re-parse through the SAME parse_safely/2 seam. The :none path is a
        # byte-identical no-op — the original parsed_doc flows straight through
        # (D-02). The pre-stage reads NO identity field (Pitfall 3 / CLAUDE.md #4).
        case decrypt_assertion(response_payload, parsed_doc, connection, opts) do
          {:ok, effective_doc} ->
            case do_run_validations(
                   effective_doc,
                   request_intent,
                   connection,
                   cert_chain,
                   opts,
                   now
                 ) do
              {:ok, login_result} -> {:ok, login_result, assertion_count(effective_doc)}
              {:error, %Error{} = error} -> {:error, error, assertion_count(effective_doc)}
            end

          {:error, %Error{} = error} ->
            # No re-parse happened on the ambiguity / decryption-failure arms, so
            # the count is taken off the OUTER parsed_doc still in scope.
            {:error, error, assertion_count(parsed_doc)}
        end

      {:error, %Error{} = error} ->
        {:error, error, 0}
    end
  end

  # The :decrypt_assertion pre-stage (D-01). Returns {:ok, parsed_doc} (the
  # effective doc do_run_validations/6 will consume) or {:error, %Error{}}.
  #
  #   :none        -> {:ok, parsed_doc}  byte-identical no-op (D-02): NO re-parse,
  #                   NO XMLEnc.decrypt/3 call.
  #   :ambiguous   -> {:error, :ambiguous_assertion}  produced BEFORE any decrypt
  #                   (D-03 / SC#2 / Pitfall 2).
  #   {:single, _} -> resolve the key-resolver MODULE (pass the module, never the
  #                   resolved PEM — XMLEnc.decrypt/3 re-resolves via apply), splice
  #                   the prefix-aware exactly-one-match EncryptedAssertion substring,
  #                   decrypt, re-parse the recomposed binary via parse_safely/2.
  #                   Any decryption failure collapses to the opaque
  #                   :decryption_failed (no oracle).
  defp decrypt_assertion(response_payload, parsed_doc, connection, opts) do
    case detect_encrypted(Map.get(parsed_doc, :parse_tree)) do
      :none ->
        {:ok, parsed_doc}

      :ambiguous ->
        {:error,
         Error.new(
           :ambiguous_assertion,
           "Response contains both cleartext and encrypted assertions",
           %{}
         )}

      {:single, _node} ->
        case locate_encrypted_assertion(response_payload) do
          {:ok, enc_bytes} ->
            resolver = Keyword.get(opts, :key_resolver, Relyra.KeyResolver.Default)
            decrypt_opts = Keyword.put(opts, :connection, connection)

            case Relyra.Security.XMLEnc.decrypt(enc_bytes, resolver, decrypt_opts) do
              {:ok, plaintext} ->
                recomposed = String.replace(response_payload, enc_bytes, plaintext, global: false)
                Relyra.Security.XML.PureBeam.parse_safely(recomposed, parse_opts(opts))

              :decryption_failed ->
                {:error,
                 Error.new(
                   :decryption_failed,
                   "Encrypted assertion could not be decrypted",
                   %{}
                 )}
            end

          # The prefix-aware locator found zero or >1 EncryptedAssertion substrings
          # in the raw binary — reject as ambiguous rather than splicing the first
          # (exactly-one-match guard, RESEARCH A1; consistent with the >1 detector
          # branch).
          :ambiguous ->
            {:error,
             Error.new(
               :ambiguous_assertion,
               "Response contains both cleartext and encrypted assertions",
               %{}
             )}
        end
    end
  end

  # Tree-walk detector over the OUTER parse tree (prefix-agnostic, by local name).
  # Models the RESEARCH code example; reuses the prefix-agnostic find_first/find_all
  # shape (pure_beam.ex:584-618) — NO second parser (CLAUDE.md invariant #2).
  defp detect_encrypted(%Node{} = parse_tree) do
    enc = find_first(parse_tree, "EncryptedAssertion")
    cleartext = find_first(parse_tree, "Assertion")
    encs = find_all(parse_tree, "EncryptedAssertion")

    cond do
      is_nil(enc) -> :none
      not is_nil(cleartext) -> :ambiguous
      length(encs) > 1 -> :ambiguous
      true -> {:single, enc}
    end
  end

  defp detect_encrypted(_other), do: :none

  # The first descendant-or-self element with the given local name, document order,
  # or nil (prefix-agnostic).
  defp find_first(%Node{local: local} = node, local), do: node

  defp find_first(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> find_first(child, local) end)
  end

  defp find_first(_other, _local), do: nil

  # All descendant-or-self elements with the given local name, document order.
  defp find_all(%Node{} = node, local) do
    node
    |> collect_nodes(local, [])
    |> Enum.reverse()
  end

  defp collect_nodes(%Node{local: local, children: children} = node, local, acc) do
    Enum.reduce(children, [node | acc], fn child, a -> collect_nodes(child, local, a) end)
  end

  defp collect_nodes(%Node{children: children}, local, acc) do
    Enum.reduce(children, acc, fn child, a -> collect_nodes(child, local, a) end)
  end

  defp collect_nodes(_other, _local, acc), do: acc

  # Prefix-aware, exactly-one-match locator for the <EncryptedAssertion>...</...>
  # substring in the RAW Response binary (RESEARCH Pattern 1 + A1). Matches both an
  # unprefixed <EncryptedAssertion>...</EncryptedAssertion> AND a namespace-prefixed
  # <saml:EncryptedAssertion>...</saml:EncryptedAssertion> (any prefix), requiring the
  # closing tag's prefix to match the opening tag's. EncryptedAssertion cannot nest
  # another EncryptedAssertion (XML-Enc), so a non-greedy match is unambiguous for a
  # single element. If zero or >1 substrings are present, return :ambiguous rather
  # than silently splicing the first (exactly-one-match guard).
  defp locate_encrypted_assertion(response_payload) do
    regex = ~r/<(?:([\w.-]+):)?EncryptedAssertion\b.*?<\/(?:\1:)?EncryptedAssertion>/s

    case Regex.scan(regex, response_payload) do
      [[whole | _]] -> {:ok, whole}
      _ -> :ambiguous
    end
  end

  defp do_run_validations(parsed_doc, request_intent, connection, cert_chain, opts, now) do
    with :ok <- validate_request_correlation(parsed_doc, request_intent, connection, opts),
         :ok <- validate_issuer_connection_match(parsed_doc, connection, request_intent),
         {:ok, signed_node} <-
           Relyra.Security.Signature.verify(parsed_doc, connection, cert_chain, opts),
         :ok <- bind_signed_node(parsed_doc, signed_node),
         :ok <- Relyra.Protocol.Response.validate_status(Map.get(parsed_doc, :status)),
         :ok <-
           Relyra.Protocol.Response.validate_destination(
             Map.get(parsed_doc, :destination),
             expected_destination(connection, request_intent)
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_audience(
             Map.get(parsed_doc, :audiences),
             expected_audience(connection),
             connection
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_recipient(
             Map.get(parsed_doc, :recipient),
             expected_recipient(connection, request_intent)
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_time_conditions(
             assertion_times(parsed_doc),
             now,
             skew_seconds: Keyword.get(opts, :skew_seconds, 120)
           ) do
      {:ok, login_result(parsed_doc, signed_node, request_intent, connection, opts)}
    else
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp validate_request_correlation(parsed_doc, request_intent, connection, _opts) do
    case request_intent do
      nil ->
        actual_id = Map.get(parsed_doc, :in_response_to)

        cond do
          not is_nil(actual_id) ->
            {:error,
             Error.new(
               :in_response_to_mismatch,
               "SAML Response contains InResponseTo but no matching request was found",
               %{actual: actual_id}
             )}

          !read_field(connection, :allow_idp_initiated) ->
            {:error,
             Error.new(
               :idp_initiated_not_allowed,
               "IdP-initiated SSO is not enabled for this connection"
             )}

          true ->
            :ok
        end

      intent ->
        expected_id = Map.get(intent, :request_id) || Map.get(intent, :in_response_to)
        actual_id = Map.get(parsed_doc, :in_response_to)

        if expected_id == actual_id do
          :ok
        else
          {:error,
           Error.new(
             :in_response_to_mismatch,
             "SAML Response InResponseTo does not match request ID",
             %{
               expected: expected_id,
               actual: actual_id
             }
           )}
        end
    end
  end

  defp validate_issuer_connection_match(parsed_doc, connection, _request_intent) do
    expected_issuer = Map.get(connection, :idp_entity_id) || Map.get(connection, :issuer)
    actual_issuer = Map.get(parsed_doc, :issuer)

    if expected_issuer == actual_issuer do
      :ok
    else
      {:error,
       Error.new(
         :issuer_mismatch,
         "SAML Response Issuer does not match connection configuration",
         %{
           expected: expected_issuer,
           actual: actual_issuer
         }
       )}
    end
  end

  defp bind_signed_node(_parsed_doc, _signed_node) do
    :ok
  end

  defp login_result(
         protocol_payload,
         %SignedNode{} = signed_node,
         request_intent,
         connection,
         opts
       ) do
    %{
      connection_id:
        read_field(protocol_payload, :connection_id) ||
          expected_connection_id(request_intent, connection),
      issuer: Map.get(protocol_payload, :issuer),
      in_response_to: Map.get(protocol_payload, :in_response_to),
      signed_xml_id: signed_node.xml_id,
      signed_xpath: signed_node.xpath,
      name_id: read_field(protocol_payload, :name_id),
      name_id_format: read_field(protocol_payload, :name_id_format),
      session_index: read_field(protocol_payload, :session_index),
      attributes: read_field(protocol_payload, :attributes) || %{},
      return_to: read_field(request_intent, :return_to),
      relay_state: read_field(request_intent, :relay_state) || Keyword.get(opts, :relay_state),
      connection: connection
    }
  end

  defp parse_opts(opts), do: Keyword.take(opts, [:max_bytes])

  defp cert_chain(connection, opts) do
    Keyword.get(opts, :cert_chain) || Map.get(connection, :idp_certificates) ||
      Map.get(connection, :cert_chain) || []
  end

  defp expected_connection_id(request_intent, connection) do
    (request_intent && Map.get(request_intent, :connection_id)) || Map.get(connection, :id) ||
      Map.get(connection, :connection_id)
  end

  defp expected_destination(connection, request_intent) do
    (request_intent && Map.get(request_intent, :acs_url)) || Map.get(connection, :acs_url)
  end

  defp expected_audience(connection) do
    Map.get(connection, :sp_entity_id) || Map.get(connection, :issuer)
  end

  defp expected_recipient(connection, request_intent) do
    (request_intent && Map.get(request_intent, :acs_url)) || Map.get(connection, :acs_url)
  end

  defp assertion_times(parsed_doc) do
    Map.get(parsed_doc, :assertion_times) || %{}
  end

  defp assertion_count(parsed_doc) do
    parsed_doc
    |> Map.get(:signed_candidates, [])
    |> length()
  end

  defp read_field(nil, _key), do: nil

  defp read_field(map, key) when is_map(map) and is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end
end
