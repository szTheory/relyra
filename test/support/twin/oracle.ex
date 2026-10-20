defmodule Relyra.Twin.Oracle do
  @moduledoc """
  Phase 82 adversarial twin — the invariant oracle.

  Runs a minted (and possibly mutated) `Relyra.Twin.Mint.Doc` through the real
  public API for its kind and judges the outcome against the SIGNED truth, never
  against Relyra's own re-parse:

    * `{:ok, _}` is legal only when the consumed identity fields equal exactly
      what the generator signed (`doc.truth`). Any other acceptance is a defect —
      this is the verified-node == consumed-node invariant.
    * Otherwise the result must be a `%Relyra.Error{}` whose `type` is in the
      allowlist of designed typed rejections. An un-allowlisted type is a defect
      (it signals an unexpected failure path, e.g. a masked crash).
    * A raise, exit, timeout, or heap blow-up is a defect.

  Each case runs in a bounded `Task` with a `max_heap_size` so a pathological
  input fails the property instead of taking down the suite.
  """

  alias Relyra.Error
  alias Relyra.Security.LogoutValidator
  alias Relyra.Twin.Mint
  alias Relyra.Twin.Mint.Doc

  # Every typed rejection the trust paths are DESIGNED to emit. Deliberately
  # excludes generic/internal wrappers (`:internal_protocol_error`) so a masked
  # crash surfaces as a defect rather than passing as a "typed rejection".
  @allowed_error_types MapSet.new([
                         # parse / pre-parse guards
                         :malformed_xml,
                         :payload_too_large,
                         :doctype_forbidden,
                         :entity_expansion_forbidden,
                         :invalid_parsed_doc,
                         :unexpected_root_element,
                         # structural binding
                         :ambiguous_signed_node,
                         :ambiguous_assertion,
                         :duplicate_xml_id,
                         :duplicate_ids,
                         :reference_mismatch,
                         :signature_placement_invalid,
                         :signature_wrapping_suspected,
                         :signed_node_binding_mismatch,
                         :document_keyinfo_forbidden,
                         :invalid_signed_node_handle,
                         :missing_protocol_field,
                         :logout_assertion_forbidden,
                         # cryptographic verification
                         :missing_signature,
                         :invalid_signature,
                         :signature_failed,
                         :signature_invalid,
                         :digest_mismatch,
                         :untrusted_certificate,
                         :trust_anchor_mismatch,
                         :unsupported_signature_algorithm,
                         :unsupported_signing_algorithm,
                         :unknown_signing_algorithm,
                         :deprecated_algorithm,
                         :legacy_algorithm_override_expired,
                         :unsupported_canonicalization_method,
                         :unsupported_transform,
                         :unsigned_or_partial_signature,
                         :invalid_signature_input,
                         :signature_verify,
                         # protocol validation
                         :issuer_mismatch,
                         :assertion_issuer_mismatch,
                         :invalid_audience,
                         :assertion_expired,
                         :assertion_not_yet_valid,
                         :subject_confirmation_invalid,
                         :subject_confirmation_expired,
                         :subject_confirmation_in_response_to,
                         :in_response_to_mismatch,
                         :unsupported_status,
                         :relay_state_missing,
                         :relay_state_mismatch,
                         :request_intent_not_found,
                         :request_intent_invalid,
                         :request_intent_expired,
                         # logout / redirect
                         :logout_request_invalid,
                         :logout_response_invalid,
                         :invalid_binding,
                         :invalid_binding_payload,
                         :redirect_signature_mismatch,
                         # metadata
                         :metadata_wrong_root,
                         :metadata_missing_entity_id,
                         :metadata_missing_sso_service,
                         :metadata_missing_certificate,
                         # configuration (benign, our fixtures shouldn't hit these)
                         :adapter_not_configured,
                         :connection_not_found,
                         :key_not_configured,
                         :optional_dependency_missing,
                         :invalid_connection_record,
                         :resolver_failed
                       ])

  @idp "https://idp.example.com/metadata"
  @sp "https://sp.example.com/metadata"
  @acs "https://sp.example.com/saml/acs"
  @request_id "id_request_123"

  @timeout_ms 5_000
  @max_heap_words 50_000_000

  @doc "The set of error types the oracle treats as legal typed rejections."
  @spec allowed_error_types() :: MapSet.t()
  def allowed_error_types, do: @allowed_error_types

  @doc """
  Judge a document. Returns `:legal` or `{:defect, reason, outcome}`.
  """
  @spec judge(Doc.t()) :: :legal | {:defect, atom(), term()}
  def judge(%Doc{} = doc) do
    case run(doc) do
      {:ok, consumed} ->
        if consumed_matches?(doc, consumed) do
          :legal
        else
          {:defect, :accepted_value_mismatch, {:consumed, consumed, :truth, doc.truth}}
        end

      {:error, %Error{type: type}} ->
        if MapSet.member?(@allowed_error_types, type) do
          :legal
        else
          {:defect, :unexpected_error_type, type}
        end

      {:error, other} ->
        {:defect, :non_error_rejection, other}

      {:crash, reason} ->
        {:defect, :crash, reason}

      :timeout ->
        {:defect, :timeout, @timeout_ms}
    end
  end

  @doc """
  Invoke the public API for `doc`, isolated in a bounded task. Normalizes to
  `{:ok, consumed}` | `{:error, term}` | `{:crash, reason}` | `:timeout`.
  """
  @spec run(Doc.t()) :: {:ok, map()} | {:error, term()} | {:crash, term()} | :timeout
  def run(%Doc{} = doc) do
    task =
      Task.async(fn ->
        Process.flag(:max_heap_size, %{size: @max_heap_words, kill: true, error_logger: false})

        try do
          {:called, invoke(doc)}
        rescue
          e -> {:raised, e}
        catch
          kind, reason -> {:caught, {kind, reason}}
        end
      end)

    case Task.yield(task, @timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:called, result}} -> normalize(doc.kind, result)
      {:ok, {:raised, e}} -> {:crash, e}
      {:ok, {:caught, reason}} -> {:crash, reason}
      {:exit, reason} -> {:crash, reason}
      nil -> :timeout
    end
  end

  # --- per-kind invocation ---------------------------------------------------

  defp invoke(%Doc{kind: :login, payload: xml, cert_chain: chain}) do
    Relyra.consume_response(xml, login_intent(), login_opts(chain))
  end

  defp invoke(%Doc{kind: :logout_redirect, payload: query, cert_chain: chain}) do
    LogoutValidator.validate_logout_request(
      query,
      logout_connection(),
      logout_opts(chain, :redirect)
    )
  end

  defp invoke(%Doc{kind: :logout_post, payload: xml, cert_chain: chain}) do
    LogoutValidator.validate_logout_request(xml, logout_connection(), logout_opts(chain, :post))
  end

  defp invoke(%Doc{kind: :metadata, payload: xml}) do
    Relyra.Metadata.Parser.parse(xml)
  end

  # --- outcome normalization -------------------------------------------------

  defp normalize(:login, {:ok, result}) do
    {:ok, %{name_id: result.principal.name_id, attributes: result.principal.attributes}}
  end

  defp normalize(kind, {:ok, msg}) when kind in [:logout_redirect, :logout_post] do
    {:ok,
     %{
       id: Map.get(msg, :id),
       name_id: Map.get(msg, :name_id),
       session_index: Map.get(msg, :session_index)
     }}
  end

  defp normalize(:metadata, {:ok, meta}) do
    sso =
      case meta.sso_services do
        [%{location: loc} | _] -> loc
        _ -> nil
      end

    {:ok, %{entity_id: meta.entity_id, sso: sso}}
  end

  defp normalize(_kind, {:error, _} = err), do: err
  defp normalize(_kind, other), do: {:error, {:unexpected_return, other}}

  # --- truth comparison ------------------------------------------------------

  defp consumed_matches?(%Doc{kind: :login, truth: t}, consumed) do
    consumed.name_id == t.name_id and consumed.attributes == t.attributes
  end

  defp consumed_matches?(%Doc{kind: kind, truth: t}, consumed)
       when kind in [:logout_redirect, :logout_post] do
    consumed.id == t.id and consumed.name_id == t.name_id and
      consumed.session_index == t.session_index
  end

  defp consumed_matches?(%Doc{kind: :metadata, truth: t}, consumed) do
    consumed.entity_id == t.entity_id and consumed.sso == t.sso
  end

  # --- fixed harness context (mirrors Mint constants) ------------------------

  defp login_intent do
    %{
      request_id: @request_id,
      connection_id: "conn-123",
      relay_state: "rs_1234567890abcdef",
      in_response_to: @request_id,
      destination: @acs,
      recipient: @acs,
      issuer: @idp,
      sp_entity_id: @sp,
      acs_url: @acs
    }
  end

  defp login_connection(chain) do
    %{
      id: "conn-123",
      connection_id: "conn-123",
      idp_entity_id: @idp,
      issuer: @idp,
      sp_entity_id: @sp,
      acs_url: @acs,
      cert_chain: chain
    }
  end

  defp login_opts(chain) do
    [
      connection: login_connection(chain),
      resolved_connection: login_connection(chain),
      relay_state: "rs_1234567890abcdef",
      request_store: Relyra.Testing.Adapters.RequestStore,
      replay_store: Relyra.Testing.Adapters.ReplayStore,
      connection_resolver: Relyra.Testing.Adapters.ConnectionResolver,
      request_intent: login_intent(),
      now: Mint.now()
    ]
  end

  defp logout_connection do
    %{id: "conn-123", connection_id: "conn-123", idp_entity_id: @idp, issuer: @idp}
  end

  defp logout_opts(chain, binding) do
    [
      cert_chain: chain,
      binding: binding,
      # no-op replay so repeated property cases never collide on a message ID
      replay_store_consume: fn _key, _meta, _opts -> :ok end
    ]
  end
end
