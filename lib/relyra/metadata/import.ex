defmodule Relyra.Metadata.Import do
  @moduledoc false

  alias Relyra.Ecto.CertificateFacts
  alias Relyra.Ecto.MetadataApply
  alias Relyra.Error
  alias Relyra.Metadata.{Candidate, Parser, TrustAnchor}

  @redirect_binding "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
  @post_binding "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"

  @spec import_xml(binary(), binary(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def import_xml(connection_id, xml, opts \\ [])

  def import_xml(connection_id, xml, opts)
      when is_binary(connection_id) and is_binary(xml) and is_list(opts) do
    case Parser.parse(xml, opts) do
      {:ok, parsed} ->
        candidate = build_candidate(parsed)

        MetadataApply.apply_revision(
          connection_id,
          Map.from_struct(candidate),
          %{
            source_kind: :xml_import,
            trigger: :manual_import,
            actor: Keyword.get(opts, :actor, "unknown"),
            cause: Keyword.get(opts, :cause, "manual import"),
            content_hash_sha256: sha256(xml),
            trust_summary: candidate.trust_summary
          },
          opts
        )

      {:error, %Error{} = error} ->
        _ =
          MetadataApply.record_attempt(
            connection_id,
            %{
              source_kind: :xml_import,
              trigger: :manual_import,
              actor: Keyword.get(opts, :actor, "unknown"),
              cause: Keyword.get(opts, :cause, Atom.to_string(error.type)),
              outcome: failure_outcome(error),
              content_hash_sha256: sha256(xml),
              details: %{error_code: error.type, xml_bytes: byte_size(xml)},
              trust_summary: %{status: "failed", error_code: error.type}
            },
            opts
          )

        {:error, error}
    end
  end

  def import_xml(_connection_id, _xml, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and XML bytes are required for metadata import",
       %{operation: :import_xml, repo: inspect(Keyword.get(opts, :repo))}
     )}
  end

  @spec build_candidate(map()) :: Candidate.t()
  def build_candidate(parsed) do
    {service_url, service_binding} = select_sso_service(Map.fetch!(parsed, :sso_services))
    certificates = Enum.map(Map.fetch!(parsed, :certificates), &normalize_certificate/1)

    Candidate.new(%{
      idp_entity_id: Map.fetch!(parsed, :entity_id),
      idp_sso_url: service_url,
      sso_binding: service_binding,
      provider_preset: nil,
      source_kind: :xml_import,
      trust_summary: %{
        certificate_count: length(certificates),
        sso_binding: service_binding,
        idp_certificates: length(certificates)
      },
      certificates: certificates
    })
  end

  defp normalize_certificate(base64) do
    pem = to_pem(base64)
    # Certificate fingerprint = SHA-256 of the DER bytes (CR-02), via the canonical
    # TrustAnchor compute, so the admin-displayed / drift-detector fingerprint
    # equals the operator-pinned (openssl DER) fingerprint. NOTE: the generic
    # sha256/1 below still hashes XML CONTENT (not certs) and is intentionally
    # unchanged.
    fingerprint_sha256 = TrustAnchor.fingerprint(pem)

    case CertificateFacts.extract(pem) do
      {:ok, facts} ->
        Map.merge(facts, %{pem: pem, fingerprint_sha256: fingerprint_sha256})

      {:error, %Error{} = error} ->
        %{pem: pem, fingerprint_sha256: fingerprint_sha256, error: error}
    end
  end

  # Imported metadata must resolve to the same single runtime destination that the
  # redirect-based login path already consumes: prefer HTTP-Redirect, else HTTP-POST,
  # else the first remaining SingleSignOnService in document order.
  defp select_sso_service(services) do
    service =
      Enum.find(services, &(&1.binding == @redirect_binding)) ||
        Enum.find(services, &(&1.binding == @post_binding)) ||
        List.first(services)

    {service.location, service.binding}
  end

  defp failure_outcome(%Error{type: :malformed_xml}), do: :parse_failed
  defp failure_outcome(%Error{type: :metadata_wrong_root}), do: :parse_failed
  defp failure_outcome(%Error{type: _type}), do: :validation_failed

  defp to_pem(base64) do
    body =
      base64
      |> String.replace(~r/\s+/, "")
      |> String.codepoints()
      |> Enum.chunk_every(64)
      |> Enum.map_join("\n", &Enum.join/1)

    "-----BEGIN CERTIFICATE-----\n#{body}\n-----END CERTIFICATE-----"
  end

  defp sha256(value) do
    :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  end
end
