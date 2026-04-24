defmodule Relyra.Security.Signature do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Security.AlgorithmPolicy
  alias Relyra.Security.SignedNode

  @spec verify(map(), map(), [binary()], keyword()) :: {:ok, SignedNode.t()} | {:error, Error.t()}
  def verify(parsed_doc, connection, cert_chain, opts \\ [])

  def verify(parsed_doc, connection, cert_chain, opts)
      when is_map(parsed_doc) and is_map(connection) and is_list(cert_chain) and is_list(opts) do
    details = connection_details(connection)
    duplicate_xml_ids = duplicate_xml_ids(parsed_doc)

    cond do
      cert_chain == [] ->
        {:error,
         Error.new(:untrusted_certificate, "Configured certificate chain is required", details)}

      Map.get(parsed_doc, :key_info_trust) == true ->
        {:error,
         Error.new(
           :untrusted_certificate,
           "Document-provided KeyInfo cannot be used as a trust source",
           Map.put(details, :reason, :document_keyinfo_forbidden)
         )}

      duplicate_xml_ids != [] ->
        {:error,
         Error.new(
           :duplicate_xml_id,
           "Duplicate XML IDs detected in signed material",
           Map.merge(details, %{
             duplicate_ids: duplicate_xml_ids,
             duplicate_count: length(duplicate_xml_ids)
           })
         )}

      true ->
        verify_algorithms_and_candidates(parsed_doc, details, opts)
    end
  end

  def verify(_parsed_doc, connection, _cert_chain, _opts) do
    details = connection_details(connection)

    {:error,
     Error.new(
       :invalid_signature,
       "Signature verification inputs are invalid",
       Map.put(details, :reason, :invalid_signature_input)
     )}
  end

  defp verify_algorithms_and_candidates(parsed_doc, details, opts) do
    policy = Keyword.get(opts, :algorithm_policy, AlgorithmPolicy.default())
    signature_method = Map.get(parsed_doc, :signature_method)
    digest_method = Map.get(parsed_doc, :digest_method)

    with :ok <-
           evaluate_policy(
             AlgorithmPolicy.enforce_signature_method(policy, signature_method),
             details
           ),
         :ok <-
           evaluate_policy(AlgorithmPolicy.enforce_digest_method(policy, digest_method), details) do
      verified_signed_node(parsed_doc, signature_method, digest_method, details)
    end
  end

  defp evaluate_policy(:ok, _details), do: :ok

  defp evaluate_policy(%Error{} = error, details) do
    {:error, merge_error_details(error, details)}
  end

  defp verified_signed_node(parsed_doc, signature_method, digest_method, details) do
    signed_candidates = Map.get(parsed_doc, :signed_candidates, [])

    case signed_candidates do
      [] ->
        {:error,
         Error.new(:missing_signature, "No signed node candidates were verified", details)}

      [candidate] ->
        {:ok,
         %SignedNode{
           xml_id: Map.get(candidate, :xml_id),
           xpath: Map.get(candidate, :xpath),
           signed_xml: Map.get(candidate, :signed_xml, ""),
           signature_method: signature_method,
           digest_method: digest_method
         }}

      candidates ->
        {:error,
         Error.new(
           :ambiguous_signed_node,
           "Exactly one verified signed node is required",
           Map.merge(details, %{candidate_count: length(candidates)})
         )}
    end
  end

  defp duplicate_xml_ids(parsed_doc) do
    parsed_doc
    |> Map.get(:duplicate_ids, [])
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
  end

  defp merge_error_details(%Error{details: error_details} = error, details)
       when is_map(error_details) do
    %{error | details: Map.merge(details, error_details)}
  end

  defp merge_error_details(%Error{} = error, details), do: %{error | details: details}

  defp connection_details(connection) when is_map(connection) do
    connection_id =
      Map.get(connection, :connection_id) ||
        Map.get(connection, "connection_id") ||
        Map.get(connection, :id) ||
        Map.get(connection, "id")

    %{connection_id: connection_id}
  end

  defp connection_details(_connection), do: %{connection_id: nil}
end
