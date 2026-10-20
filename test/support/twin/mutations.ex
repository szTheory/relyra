defmodule Relyra.Twin.Mutations do
  @moduledoc """
  Phase 82 adversarial twin — the mutation catalog.

  A mutation is a small, shrinkable term applied to a document payload (XML for
  `:login`/`:logout_post`/`:metadata`, a signed redirect query for
  `:logout_redirect`). Ops are deliberately total: if an op's anchor is not
  present in the current payload it returns the payload unchanged, so arbitrary
  op *lists* compose without ever raising — shrinking then acts on the list and
  on each op's integer/position component, never on raw bytes.

  Families (roadmap PROP success #2 enumerates them):

      :wrap_move_duplicate  — :wrap_signed, :duplicate_signed, :move_signature
      :envelope_injection   — :inject
      :namespace            — :rebind_ns
      :comment_pi_cdata     — :comment, :pi, :cdata
      :whitespace_encoding  — :whitespace, :entity_encode
      :duplicate_ids        — :duplicate_id, :id_variant
      :time_boundary        — realized at MINT time (see Generators); listed for
                              coverage so every named family is reachable
      :truncation_size      — :truncate, :pad

  `:time_boundary` carries no byte op: a signed document whose validity window
  straddles `now` can only be produced by signing, not by post-hoc byte edits
  (those would break the digest). The generator realizes it as a mint parameter;
  this module records it in `families/0` so the coverage test sees every family.
  """

  alias Relyra.Twin.Mint.Doc

  @positions [:before_signed, :after_signed, :inside_signed_start, :root_start, :root_end]

  @families [
    :wrap_move_duplicate,
    :envelope_injection,
    :namespace,
    :comment_pi_cdata,
    :whitespace_encoding,
    :duplicate_ids,
    :time_boundary,
    :truncation_size
  ]

  @spec families() :: [atom()]
  def families, do: @families

  @spec positions() :: [atom()]
  def positions, do: @positions

  @doc "Map a concrete op to its family (for coverage assertions)."
  @spec family_of(tuple()) :: atom()
  def family_of({op, _}), do: family_of_name(op)
  def family_of({op, _, _}), do: family_of_name(op)
  def family_of(op) when is_atom(op), do: family_of_name(op)

  defp family_of_name(:wrap_signed), do: :wrap_move_duplicate
  defp family_of_name(:duplicate_signed), do: :wrap_move_duplicate
  defp family_of_name(:move_signature), do: :wrap_move_duplicate
  defp family_of_name(:inject), do: :envelope_injection
  defp family_of_name(:rebind_ns), do: :namespace
  defp family_of_name(:comment), do: :comment_pi_cdata
  defp family_of_name(:pi), do: :comment_pi_cdata
  defp family_of_name(:cdata), do: :comment_pi_cdata
  defp family_of_name(:whitespace), do: :whitespace_encoding
  defp family_of_name(:entity_encode), do: :whitespace_encoding
  defp family_of_name(:duplicate_id), do: :duplicate_ids
  defp family_of_name(:id_variant), do: :duplicate_ids
  defp family_of_name(:truncate), do: :truncation_size
  defp family_of_name(:pad), do: :truncation_size
  # redirect-query ops (a distinct taxonomy from the XML byte families)
  defp family_of_name(:dup_param), do: :redirect_query
  defp family_of_name(:append_param), do: :redirect_query
  defp family_of_name(:flip_byte), do: :redirect_query

  @doc """
  Ops that annotate the signed tree between elements without changing any leaf
  text value — safe to apply to a template and then re-sign (mutate-then-resign),
  because the same C14N engine signs and verifies, so the round-trip must still
  accept with the original truth. Excludes `:entity_encode` (rewrites a leaf
  value) and every structural / injection op.
  """
  @spec equivalence_op?(tuple() | atom()) :: boolean()
  def equivalence_op?({op, _}), do: op in [:comment, :pi, :cdata, :whitespace]
  def equivalence_op?({op, _, _}), do: op in [:comment, :pi, :cdata, :whitespace]
  def equivalence_op?(op) when is_atom(op), do: false

  @doc """
  Apply an op list to a payload under the kind's profile. Returns the mutated
  payload (a binary).
  """
  @spec apply_ops(String.t(), atom(), [tuple()]) :: String.t()
  def apply_ops(payload, kind, ops) when is_binary(payload) and is_list(ops) do
    profile = profile(kind)
    Enum.reduce(ops, payload, fn op, acc -> apply_op(acc, profile, op) end)
  end

  @spec apply_ops(Doc.t(), [tuple()]) :: String.t()
  def apply_ops(%Doc{payload: payload, kind: kind}, ops), do: apply_ops(payload, kind, ops)

  # ---------------------------------------------------------------------------
  # Op interpreters
  # ---------------------------------------------------------------------------

  defp apply_op(payload, %{query?: true} = _profile, op), do: apply_query_op(payload, op)

  defp apply_op(payload, profile, {:inject, position, idx}) do
    fragment = pick(profile.decoys, idx)
    insert_at(payload, profile, position, fragment)
  end

  defp apply_op(payload, profile, {:wrap_signed, idx}) do
    {open, close} = pick(profile.wrappers, idx)

    case signed_span(payload, profile) do
      {s, e} ->
        block = binary_part(payload, s, e - s)

        binary_part(payload, 0, s) <>
          open <> block <> close <> binary_part(payload, e, byte_size(payload) - e)

      nil ->
        payload
    end
  end

  defp apply_op(payload, profile, :duplicate_signed) do
    case signed_span(payload, profile) do
      {s, e} ->
        block = binary_part(payload, s, e - s)
        binary_part(payload, 0, s) <> block <> binary_part(payload, s, byte_size(payload) - s)

      nil ->
        payload
    end
  end

  defp apply_op(payload, profile, :move_signature) do
    # Pull the first <...Signature>...</Signature> out and re-insert it just
    # before the signed element's close tag (a placement shuffle).
    with {ss, se} <- tag_span(payload, "Signature"),
         sig <- binary_part(payload, ss, se - ss),
         without <-
           binary_part(payload, 0, ss) <> binary_part(payload, se, byte_size(payload) - se),
         {_s, e} when is_integer(e) <- signed_span(without, profile) do
      # insert sig right after the signed element opens (inside_signed_start-ish)
      insert_at(without, profile, :inside_signed_start, sig)
    else
      _ -> payload
    end
  end

  defp apply_op(payload, profile, {:comment, position}) do
    insert_at(payload, profile, position, "<!-- #{profile.decoy_text} -->")
  end

  defp apply_op(payload, profile, {:pi, position}) do
    insert_at(payload, profile, position, "<?twin #{profile.decoy_text}?>")
  end

  defp apply_op(payload, profile, {:cdata, position}) do
    insert_at(payload, profile, position, "<![CDATA[#{profile.decoy_text}]]>")
  end

  defp apply_op(payload, profile, {:whitespace, position}) do
    insert_at(payload, profile, position, "\n\t  ")
  end

  defp apply_op(payload, _profile, {:entity_encode, which}) do
    # Replace one character of a chosen signed text value with its numeric
    # entity. Post-sign this breaks the digest; after a resign it must round-trip.
    targets = ["user@example.com", "member", "https://idp.example.com/metadata"]
    target = Enum.at(targets, rem(abs(which), length(targets)))

    case payload do
      <<_::binary>> ->
        if String.contains?(payload, target) and target != "" do
          <<first::utf8, rest::binary>> = target
          encoded = "&##{first};" <> rest
          String.replace(payload, target, encoded, global: false)
        else
          payload
        end
    end
  end

  defp apply_op(payload, profile, :duplicate_id) do
    case Regex.run(~r/#{Regex.escape(profile.signed_open)}[^>]*\bID="([^"]+)"/, payload) do
      [_, id] -> insert_at(payload, profile, :before_signed, ~s(<saml:Dup ID="#{id}"/>))
      _ -> payload
    end
  end

  defp apply_op(payload, profile, {:id_variant, variant}) do
    replacement = Enum.at(["Id", "AssertionID", "iD", "id"], rem(abs(variant), 4))

    case profile.signed_open do
      open when is_binary(open) ->
        String.replace(payload, open <> "ID=", open <> replacement <> "=", global: false)

      _ ->
        payload
    end
  end

  defp apply_op(payload, _profile, {:rebind_ns, which}) do
    decoys = [
      {~s(xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"),
       ~s(xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:x="urn:evil")},
      {~s(<saml:NameID>), ~s(<saml:NameID xmlns:saml="urn:evil:lookalike">)}
    ]

    {from, to} = Enum.at(decoys, rem(abs(which), length(decoys)))
    String.replace(payload, from, to, global: false)
  end

  defp apply_op(payload, _profile, {:truncate, frac}) do
    keep = max(1, div(byte_size(payload) * clamp(frac, 1, 99), 100))
    binary_part(payload, 0, keep)
  end

  defp apply_op(payload, _profile, {:pad, n}) do
    payload <> String.duplicate("<!--x-->", clamp(n, 0, 64))
  end

  defp apply_op(payload, _profile, _unknown), do: payload

  # --- redirect-query ops ----------------------------------------------------

  # The redirect query is signed octets, not a tree. The security-relevant
  # mutations are duplicate parameters (S16) and signed-byte tampering.
  defp apply_query_op(query, {:dup_param, idx}) do
    param = Enum.at(["SAMLRequest", "RelayState", "SigAlg", "Signature"], rem(abs(idx), 4))

    case Regex.run(~r/(^|&)#{param}=([^&]*)/, query) do
      [_, _, value] -> query <> "&#{param}=#{value}"
      _ -> query <> "&#{param}=injected"
    end
  end

  defp apply_query_op(query, {:append_param, idx}) do
    extra = Enum.at(["RelayState=evil", "Foo=bar", "SAMLResponse=xxx"], rem(abs(idx), 3))
    query <> "&" <> extra
  end

  defp apply_query_op(query, {:flip_byte, pos}) do
    # Flip one character inside the Signature value → signature must fail.
    Regex.replace(~r/Signature=([^&]+)/, query, fn _full, sig ->
      i = rem(abs(pos), max(String.length(sig), 1))
      flipped = flip_char_at(sig, i)
      "Signature=#{flipped}"
    end)
  end

  defp apply_query_op(query, {:truncate, frac}) do
    keep = max(1, div(byte_size(query) * clamp(frac, 1, 99), 100))
    binary_part(query, 0, keep)
  end

  defp apply_query_op(query, _other), do: query

  # ---------------------------------------------------------------------------
  # Positioning
  # ---------------------------------------------------------------------------

  defp insert_at(payload, _profile, :root_start, fragment) do
    case :binary.match(payload, ">") do
      {open_end, 1} -> splice_in(payload, open_end + 1, fragment)
      :nomatch -> payload
    end
  end

  defp insert_at(payload, _profile, :root_end, fragment) do
    case last_close_tag(payload) do
      pos when is_integer(pos) -> splice_in(payload, pos, fragment)
      _ -> payload
    end
  end

  defp insert_at(payload, profile, :before_signed, fragment) do
    case signed_span(payload, profile) do
      {s, _e} -> splice_in(payload, s, fragment)
      nil -> payload
    end
  end

  defp insert_at(payload, profile, :after_signed, fragment) do
    case signed_span(payload, profile) do
      {_s, e} -> splice_in(payload, e, fragment)
      nil -> payload
    end
  end

  defp insert_at(payload, profile, :inside_signed_start, fragment) do
    case signed_span(payload, profile) do
      {s, _e} ->
        rel = :binary.match(payload, ">", scope: {s, byte_size(payload) - s})

        case rel do
          {open_end, 1} -> splice_in(payload, open_end + 1, fragment)
          :nomatch -> payload
        end

      nil ->
        payload
    end
  end

  defp splice_in(payload, pos, fragment) do
    binary_part(payload, 0, pos) <>
      fragment <> binary_part(payload, pos, byte_size(payload) - pos)
  end

  # Byte span [start, end) of the signed element (open tag .. matching close).
  defp signed_span(payload, %{signed_open: open, signed_close: close}) do
    with {s, _} <- :binary.match(payload, open),
         {ce, _} <- last_match(payload, close) do
      {s, ce + byte_size(close)}
    else
      _ -> nil
    end
  end

  # Byte span of the first <...LocalName>...</...LocalName> (prefix-agnostic).
  defp tag_span(payload, local) do
    with [open] <- Regex.run(~r/<(?:[\w.-]+:)?#{local}\b[^>]*>/, payload),
         {s, open_len} <- :binary.match(payload, open),
         close <- ~r/<\/(?:[\w.-]+:)?#{local}>/,
         [close_tag] <- Regex.run(close, payload),
         {ce, cl} <- :binary.match(payload, close_tag) do
      _ = open_len
      {s, ce + cl}
    else
      _ -> nil
    end
  end

  defp last_match(payload, needle) do
    case :binary.matches(payload, needle) do
      [] -> nil
      list -> List.last(list)
    end
  end

  defp last_close_tag(payload) do
    case Regex.scan(~r/<\/[^>]+>/, payload, return: :index) do
      [] -> nil
      list -> list |> List.last() |> hd() |> elem(0)
    end
  end

  defp flip_char_at(string, i) do
    graphemes = String.graphemes(string)

    case Enum.at(graphemes, i) do
      nil ->
        string

      ch ->
        flipped = if ch == "A", do: "B", else: "A"
        graphemes |> List.replace_at(i, flipped) |> Enum.join()
    end
  end

  defp pick(list, idx), do: Enum.at(list, rem(abs(idx), length(list)))
  defp clamp(n, lo, hi), do: n |> max(lo) |> min(hi)

  # ---------------------------------------------------------------------------
  # Per-kind profiles
  # ---------------------------------------------------------------------------

  defp profile(:login) do
    %{
      query?: false,
      signed_open: "<saml:Assertion ",
      signed_close: "</saml:Assertion>",
      signed_id: nil,
      decoy_text: "twin",
      decoys: [
        "<saml:NameID>attacker@evil.com</saml:NameID>",
        ~s(<saml:Conditions NotBefore="2000-01-01T00:00:00Z" NotOnOrAfter="2099-01-01T00:00:00Z"><saml:AudienceRestriction><saml:Audience>https://sp.example.com/metadata</saml:Audience></saml:AudienceRestriction></saml:Conditions>),
        "<saml:Audience>https://sp.example.com/metadata</saml:Audience>",
        ~s(<saml:AttributeStatement><saml:Attribute Name="groups"><saml:AttributeValue>admins</saml:AttributeValue></saml:Attribute></saml:AttributeStatement>),
        ~s(<x:NameID xmlns:x="urn:evil">attacker@evil.com</x:NameID>)
      ],
      wrappers: [
        {~s(<samlp:Extensions>), "</samlp:Extensions>"},
        {~s(<saml:Advice>), "</saml:Advice>"}
      ]
    }
  end

  defp profile(:logout_post) do
    %{
      query?: false,
      signed_open: "<samlp:LogoutRequest ",
      signed_close: "</samlp:LogoutRequest>",
      signed_id: nil,
      decoy_text: "twin",
      decoys: [
        "<saml:NameID>attacker@evil.com</saml:NameID>",
        "<samlp:SessionIndex>evil</samlp:SessionIndex>",
        ~s(<saml:Assertion ID="smuggled"><saml:Subject><saml:NameID>attacker@evil.com</saml:NameID></saml:Subject></saml:Assertion>)
      ],
      wrappers: [{~s(<samlp:Wrapper>), "</samlp:Wrapper>"}]
    }
  end

  defp profile(:metadata) do
    %{
      query?: false,
      signed_open: "<md:EntityDescriptor ",
      signed_close: "</md:EntityDescriptor>",
      signed_id: nil,
      decoy_text: "twin",
      decoys: [
        ~s(<md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"><md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://evil.example.com/sso"/></md:IDPSSODescriptor>),
        ~s(<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data><ds:X509Certificate>ZXZpbA==</ds:X509Certificate></ds:X509Data></ds:KeyInfo></md:KeyDescriptor>)
      ],
      # Outer, UNSIGNED descriptors that carry rival entityID / SSO / cert. The
      # authoritative-node selection (S18 / Phase 81) must still derive every
      # field from the inner SIGNED descriptor, never from these wrappers.
      wrappers: [
        {~s(<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://evil.example.com/metadata"><md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"><md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://evil.example.com/sso"/></md:IDPSSODescriptor>),
         "</md:EntityDescriptor>"},
        {~s(<md:EntitiesDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"><md:EntityDescriptor entityID="https://evil.example.com/metadata"><md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"><md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://evil.example.com/sso"/></md:IDPSSODescriptor></md:EntityDescriptor>),
         "</md:EntitiesDescriptor>"}
      ]
    }
  end

  defp profile(:logout_redirect), do: %{query?: true}
end
