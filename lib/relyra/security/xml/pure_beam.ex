defmodule Relyra.Security.XML.PureBeam do
  @moduledoc """
  Pure-BEAM baseline adapter for XML seam enforcement.

  Phase 28 (D-04): a single hardened parser path. `parse_safely/2` runs the
  pre-parse byte guards (DOCTYPE / ENTITY / size) on the raw binary BEFORE any
  parse (XXE-before-verify invariant, D-09), then routes the well-formed arm to
  `Relyra.Security.XML.SaxyTree` and re-derives EVERY downstream protocol field
  from the resulting parse tree in one pass — the regex extractors are retired so
  no parser/canonicalization differential exists (D-04, threat T-28-11).

  The flat `parsed_doc` key contract is preserved additively (D-08): every legacy
  key downstream readers (`Relyra.Security.Signature`,
  `Relyra.Protocol.ValidationPipeline`) consume is reproduced, and the parse tree
  is attached as a NEW `:parse_tree` key. The selected handle binds the EXACT
  tree node `canonicalize/2` serializes (D-10, anti-XSW), and `canonicalize/2`
  delegates to the `Relyra.Security.XML.C14N` exclusive-C14N engine on that node
  while failing closed (`:canonicalization_failed`) for any non-bindable handle
  (Pitfall 9, threat T-28-12).
  """

  @behaviour Relyra.Security.XML

  alias Relyra.Error
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node

  @default_opts [max_bytes: 1_048_576]

  @impl true
  def parse_safely(xml, opts \\ [])

  def parse_safely(xml, opts) when is_binary(xml) do
    max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)

    cond do
      byte_size(xml) > max_bytes ->
        {:error,
         Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{
           max_bytes: max_bytes
         })}

      String.contains?(xml, "<!DOCTYPE") ->
        {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

      String.contains?(xml, "<!ENTITY") ->
        {:error, Error.new(:entity_expansion_forbidden, "ENTITY declarations are forbidden")}

      true ->
        parse_tree(xml)
    end
  end

  def parse_safely(_xml, _opts), do: malformed_xml_error()

  # Route the well-formed arm to the saxy tree builder, then derive the flat
  # parsed_doc from the tree. The pre-parse byte guards above already ran on the
  # raw binary, so no DTD / entity / oversize payload reaches Saxy.
  defp parse_tree(xml) do
    case SaxyTree.parse(xml) do
      {:ok, %Node{} = root} ->
        build_parsed_doc(root)

      {:error, %Saxy.ParseError{} = error} ->
        {:error,
         Error.new(:malformed_xml, "Malformed XML payload", %{
           reason: Saxy.ParseError.message(error)
         })}
    end
  end

  # Single-pass derivation of every legacy parsed_doc key from the tree (D-04),
  # plus the additive :parse_tree key (D-07 / D-08). Required-field gates reuse
  # require_present_fields/4 so the :missing_protocol_field / :missing_signature
  # error shapes stay byte-identical to the regex era.
  defp build_parsed_doc(%Node{} = root) do
    with {:ok, response_fields} <- response_fields(root),
         {:ok, assertion_fields} <- assertion_fields(root),
         {:ok, signature_fields} <- signature_fields(root) do
      assertion_times = %{
        not_before: Map.fetch!(assertion_fields, :not_before),
        not_on_or_after: Map.fetch!(assertion_fields, :not_on_or_after),
        subject_confirmation_not_on_or_after:
          Map.fetch!(assertion_fields, :subject_confirmation_not_on_or_after)
      }

      {:ok,
       %{
         type: :parsed_xml,
         assertion_times: assertion_times,
         parse_tree: root
       }
       |> Map.merge(response_fields)
       |> Map.merge(assertion_fields)
       |> Map.merge(signature_fields)}
    end
  end

  defp response_fields(%Node{} = root) do
    fields = %{
      issuer: first_text(root, "Issuer"),
      status: first_attr(root, "StatusCode", "Value"),
      destination: attr(root, "Destination"),
      in_response_to: attr(root, "InResponseTo"),
      connection_id: attr(root, "ConnectionId")
    }

    require_present_fields(
      fields,
      [:issuer, :status, :destination],
      :missing_protocol_field,
      "Required protocol fields are missing from response payload"
    )
  end

  defp assertion_fields(%Node{} = root) do
    fields = %{
      audiences: all_texts(root, "Audience"),
      recipient: first_attr(root, "SubjectConfirmationData", "Recipient"),
      not_before: first_attr(root, "Conditions", "NotBefore"),
      not_on_or_after: first_attr(root, "Conditions", "NotOnOrAfter"),
      subject_confirmation_not_on_or_after:
        first_attr(root, "SubjectConfirmationData", "NotOnOrAfter"),
      consumed_xml_id: first_attr(root, "Assertion", "ID"),
      name_id: first_text(root, "NameID"),
      name_id_format: first_attr(root, "NameID", "Format"),
      session_index: first_attr(root, "AuthnStatement", "SessionIndex"),
      attributes: derive_attributes(root)
    }

    require_present_fields(
      fields,
      [
        :audiences,
        :recipient,
        :not_before,
        :not_on_or_after,
        :subject_confirmation_not_on_or_after,
        :consumed_xml_id
      ],
      :missing_protocol_field,
      "Required assertion fields are missing from response payload"
    )
  end

  defp signature_fields(%Node{} = root) do
    signature_method = first_attr(root, "SignatureMethod", "Algorithm")
    digest_method = first_attr(root, "DigestMethod", "Algorithm")

    fields = %{
      signature_method: signature_method,
      digest_method: digest_method,
      signed_candidates:
        signed_candidates(root)
        |> Enum.map(fn candidate ->
          Map.merge(candidate, %{
            signature_method: signature_method,
            digest_method: digest_method
          })
        end),
      duplicate_ids: duplicate_ids(root),
      key_info_trust: element_present?(root, "KeyInfo")
    }

    require_present_fields(
      fields,
      [:signature_method, :digest_method, :signed_candidates],
      :missing_signature,
      "Signed XML material is missing required signature fields"
    )
  end

  # Each <Assertion> with an ID attribute becomes a signed candidate. The xpath
  # indexes Assertion elements 1-based in document order (matching the regex-era
  # /Response/Assertion[N] shape). D-10: each candidate carries the EXACT tree
  # node (:node) plus the bound ds:Signature node (:signature_node) and that
  # Reference's ds:Transforms node (:transforms_node) so canonicalize/2 can apply
  # the reference transform chain over the same node it bound.
  defp signed_candidates(%Node{} = root) do
    signature_node = find_first(root, "Signature")
    transforms_node = if signature_node, do: find_first(signature_node, "Transforms"), else: nil

    root
    |> find_all("Assertion")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {%Node{} = assertion, index} ->
      case attr(assertion, "ID") do
        nil ->
          []

        assertion_id ->
          [
            %{
              xml_id: assertion_id,
              xpath: "/Response/Assertion[#{index}]",
              signed_xml: render_signed_xml(assertion),
              node: assertion,
              signature_node: signature_node,
              transforms_node: transforms_node
            }
          ]
      end
    end)
  end

  # All ID/id attribute values across the tree; return the values that occur more
  # than once (D-09 duplicate-ID guard, tree-derived). Document-order preserved
  # so the rejection details match the regex era (repeated occurrences listed).
  defp duplicate_ids(%Node{} = root) do
    ids =
      root
      |> all_nodes()
      |> Enum.flat_map(fn %Node{attrs: attrs} ->
        for {name, value} <- attrs, name in ["ID", "id"], do: value
      end)

    frequencies = Enum.frequencies(ids)
    Enum.filter(ids, fn id -> Map.get(frequencies, id, 0) > 1 end)
  end

  # Build the attribute map from <Attribute Name="..."><AttributeValue>..</> nodes.
  defp derive_attributes(%Node{} = root) do
    root
    |> find_all("Attribute")
    |> Enum.flat_map(fn %Node{} = attribute ->
      case attr(attribute, "Name") do
        nil ->
          []

        name ->
          values =
            attribute
            |> find_all("AttributeValue")
            |> Enum.map(&trimmed_text/1)

          [{name, values}]
      end
    end)
    |> Map.new()
  end

  @impl true
  def select_signed_node(parsed_doc, opts \\ [])

  def select_signed_node(parsed_doc, _opts) when is_map(parsed_doc) do
    duplicate_xml_ids = Map.get(parsed_doc, :duplicate_ids, [])

    cond do
      Map.get(parsed_doc, :key_info_trust) == true ->
        {:error,
         Error.new(
           :untrusted_certificate,
           "Document-provided KeyInfo cannot be used as a trust source",
           %{reason: :document_keyinfo_forbidden}
         )}

      duplicate_xml_ids != [] ->
        {:error,
         Error.new(
           :duplicate_xml_id,
           "Duplicate XML IDs detected in signed material",
           %{
             duplicate_ids: duplicate_xml_ids,
             duplicate_count: length(duplicate_xml_ids)
           }
         )}

      true ->
        select_candidate(parsed_doc)
    end
  end

  def select_signed_node(_parsed_doc, _opts) do
    {:error, Error.new(:missing_signature, "No signed node candidates were verified", %{})}
  end

  @impl true
  def canonicalize(signed_node_handle, opts \\ [])

  # A handle that binds a complete tree node (D-10): delegate to the Plan-02 C14N
  # engine, applying the signed Reference's transform chain over the EXACT bound
  # node (the same node select_signed_node/2 returned). The transform chain +
  # PrefixList are read from the bound ds:Signature's ds:Transforms node; the
  # SPECIFIC ds:Signature subtree is supplied so the enveloped-signature
  # transform prunes only that signature (anti-XSW). No ds:Transforms present =>
  # empty transform list (no prune, plain exclusive-C14N) — see canonicalize/2
  # binding note in 28-03-SUMMARY.md.
  def canonicalize(%{node: %Node{} = node} = handle, _opts) do
    transforms_node = Map.get(handle, :transforms_node)
    signature_node = Map.get(handle, :signature_node)
    transform_uris = C14N.transform_uris(transforms_node)
    prefix_list = C14N.prefix_list_from_transforms(transforms_node)

    case C14N.canonicalize_reference(node, transform_uris, signature_node, prefix_list: prefix_list) do
      {:ok, canonical_bytes} ->
        {:ok,
         %{
           canonical_xml: canonical_bytes,
           xml_id: Map.get(handle, :xml_id),
           xpath: Map.get(handle, :xpath)
         }}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  # Fail-closed fallback (Pitfall 9 / GATE-02 contract, threat T-28-12): any
  # handle lacking a bindable tree node — including the whole parsed_doc map the
  # corpus c14n-00x rows pass, and a bare atom handle (seam_contract) — is
  # rejected. The real engine must NOT succeed on incomplete / differential
  # inputs.
  def canonicalize(_signed_node_handle, _opts) do
    {:error,
     Error.new(
       :canonicalization_failed,
       "Signed node handle could not be canonicalized",
       %{reason: :invalid_signed_node_handle}
     )}
  end

  defp select_candidate(parsed_doc) do
    signed_candidates = Map.get(parsed_doc, :signed_candidates, [])
    signature_method = Map.get(parsed_doc, :signature_method)
    digest_method = Map.get(parsed_doc, :digest_method)

    case signed_candidates do
      [] ->
        {:error, Error.new(:missing_signature, "No signed node candidates were verified", %{})}

      [candidate] when is_map(candidate) ->
        # The legacy flat keys stay for backward-compat (D-08); :node /
        # :signature_node / :transforms_node are carried additively (D-10) so
        # canonicalize/2 serializes the EXACT bound node.
        {:ok,
         %{
           xml_id: Map.get(candidate, :xml_id),
           xpath: Map.get(candidate, :xpath),
           signed_xml: Map.get(candidate, :signed_xml),
           signature_method: Map.get(candidate, :signature_method, signature_method),
           digest_method: Map.get(candidate, :digest_method, digest_method),
           node: Map.get(candidate, :node),
           signature_node: Map.get(candidate, :signature_node),
           transforms_node: Map.get(candidate, :transforms_node)
         }}

      candidates ->
        {:error,
         Error.new(
           :ambiguous_signed_node,
           "Exactly one verified signed node is required",
           %{candidate_count: length(candidates)}
         )}
    end
  end

  defp require_present_fields(fields, required_keys, error_type, message) do
    missing =
      Enum.reject(required_keys, fn key ->
        present?(Map.get(fields, key))
      end)

    if missing == [] do
      {:ok, fields}
    else
      {:error,
       Error.new(error_type, message, %{
         expected: required_keys,
         actual: required_keys -- missing,
         missing: missing
       })}
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value) when is_list(value), do: value != []
  defp present?(value), do: not is_nil(value)

  # --- tree-walk derivation helpers ------------------------------------------

  # The first descendant-or-self element with the given local name, in document
  # order, or nil.
  defp find_first(%Node{local: local} = node, local), do: node

  defp find_first(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> find_first(child, local) end)
  end

  defp find_first(_other, _local), do: nil

  # All descendant-or-self elements with the given local name, in document order.
  defp find_all(%Node{} = node, local) do
    node
    |> collect(local, [])
    |> Enum.reverse()
  end

  defp collect(%Node{local: local, children: children} = node, local, acc) do
    Enum.reduce(children, [node | acc], fn child, a -> collect(child, local, a) end)
  end

  defp collect(%Node{children: children}, local, acc) do
    Enum.reduce(children, acc, fn child, a -> collect(child, local, a) end)
  end

  # Every element node in the tree, document order.
  defp all_nodes(%Node{} = root) do
    root
    |> collect_all([])
    |> Enum.reverse()
  end

  defp collect_all(%Node{children: children} = node, acc) do
    Enum.reduce(children, [node | acc], fn child, a -> collect_all(child, a) end)
  end

  # Trimmed text of the first descendant-or-self element with this local name, or
  # nil. Trimming matches the regex-era first_tag_text/2 contract.
  defp first_text(%Node{} = root, local) do
    case find_first(root, local) do
      %Node{} = node -> trimmed_text(node)
      _ -> nil
    end
  end

  # Trimmed text of every descendant-or-self element with this local name,
  # dropping empties (matches regex-era all_tag_texts/2).
  defp all_texts(%Node{} = root, local) do
    root
    |> find_all(local)
    |> Enum.map(&trimmed_text/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp trimmed_text(%Node{text: text}), do: String.trim(text)

  # The value of the first descendant-or-self element (with this local name)
  # carrying the given attribute, trimmed; or nil. Matches the regex-era
  # first_attribute/3 contract.
  defp first_attr(%Node{} = root, local, attribute_name) do
    root
    |> find_all(local)
    |> Enum.find_value(fn node -> attr(node, attribute_name) end)
  end

  # A single attribute value off a node, trimmed; or nil.
  defp attr(%Node{attrs: attrs}, attribute_name) do
    case List.keyfind(attrs, attribute_name, 0) do
      {_name, value} -> String.trim(value)
      nil -> nil
    end
  end

  defp attr(_other, _attribute_name), do: nil

  defp element_present?(%Node{} = root, local), do: find_first(root, local) != nil

  # A plain, deterministic XML serialization of a tree node for the legacy
  # :signed_xml backward-compat key (consumed only as an opaque binary by
  # do_verify). This is NOT canonical C14N — canonical bytes come from the C14N
  # engine via canonicalize/2 over the bound :node.
  defp render_signed_xml(%Node{qname: qname, attrs: attrs, children: children, text: text}) do
    attr_iodata = Enum.map(attrs, fn {name, value} -> [" ", name, "=\"", value, "\""] end)
    child_iodata = Enum.map(children, &render_signed_xml/1)
    IO.iodata_to_binary(["<", qname, attr_iodata, ">", text, child_iodata, "</", qname, ">"])
  end

  defp malformed_xml_error do
    {:error, Error.new(:malformed_xml, "Malformed XML payload", %{})}
  end
end
