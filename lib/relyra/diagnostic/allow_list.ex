defmodule Relyra.Diagnostic.AllowList do
  @moduledoc """
  Explicit redaction and transformation engine for diagnostic bundle generation.
  Ensures that sensitive data (PII, secrets, keys) does not leak when exporting
  system state for debugging.
  """

  @doc """
  Exports allowed fields from a Connection struct or map.
  Explicitly drops non-allowed keys (secrets/keys) but keeps ID, entity_id, state.
  """
  def export_connection(connection) do
    %{
      id: Map.get(connection, :id),
      connection_id: Map.get(connection, :connection_id),
      display_name: Map.get(connection, :display_name),
      organization_id: Map.get(connection, :organization_id),
      status: Map.get(connection, :status),
      provider_preset: Map.get(connection, :provider_preset),
      sp_entity_id: Map.get(connection, :sp_entity_id),
      acs_url: Map.get(connection, :acs_url),
      idp_entity_id: Map.get(connection, :idp_entity_id),
      idp_sso_url: Map.get(connection, :idp_sso_url),
      allow_idp_initiated: Map.get(connection, :allow_idp_initiated),
      lock_version: Map.get(connection, :lock_version),
      active_metadata_revision_id: Map.get(connection, :active_metadata_revision_id),
      last_known_good_metadata_revision_id: Map.get(connection, :last_known_good_metadata_revision_id),
      inserted_at: Map.get(connection, :inserted_at),
      updated_at: Map.get(connection, :updated_at)
    }
    |> reject_nil()
  end

  @doc """
  Exports allowed fields from an AuditEvent struct or map.
  Drops `actor` and hashes `correlation_id` to prevent PII leakage.
  """
  def export_audit_log(event) do
    %{
      id: Map.get(event, :id),
      connection_record_id: Map.get(event, :connection_record_id),
      domain: Map.get(event, :domain),
      action: Map.get(event, :action),
      cause: Map.get(event, :cause),
      correlation_id: hash_correlation_id(Map.get(event, :correlation_id)),
      before_summary: Map.get(event, :before_summary),
      after_summary: Map.get(event, :after_summary),
      diff_summary: Map.get(event, :diff_summary),
      inserted_at: Map.get(event, :inserted_at),
      updated_at: Map.get(event, :updated_at)
    }
    |> reject_nil()
  end

  @doc """
  Exports a summary of a Certificate.
  Includes only fingerprint, not_before, not_after, issuer, role, lifecycle_state.
  Explicitly excludes PEM and private keys.
  """
  def export_certificate_inventory(certificate) do
    %{
      id: Map.get(certificate, :id),
      connection_record_id: Map.get(certificate, :connection_record_id),
      fingerprint_sha256: Map.get(certificate, :fingerprint_sha256),
      not_before: Map.get(certificate, :not_before),
      not_after: Map.get(certificate, :not_after),
      issuer: Map.get(certificate, :issuer),
      role: Map.get(certificate, :role),
      lifecycle_state: Map.get(certificate, :lifecycle_state),
      source: Map.get(certificate, :source),
      staged_at: Map.get(certificate, :staged_at),
      activated_at: Map.get(certificate, :activated_at),
      retired_at: Map.get(certificate, :retired_at),
      inserted_at: Map.get(certificate, :inserted_at),
      updated_at: Map.get(certificate, :updated_at)
    }
    |> reject_nil()
  end

  @doc """
  Exports allowed fields from a MetadataRevision struct or map.
  """
  def export_metadata_revision(revision) do
    %{
      id: Map.get(revision, :id),
      connection_record_id: Map.get(revision, :connection_record_id),
      metadata_source_id: Map.get(revision, :metadata_source_id),
      source_kind: Map.get(revision, :source_kind),
      trigger: Map.get(revision, :trigger),
      outcome: Map.get(revision, :outcome),
      content_hash_sha256: Map.get(revision, :content_hash_sha256),
      effective_idp_entity_id: Map.get(revision, :effective_idp_entity_id),
      effective_idp_sso_url: Map.get(revision, :effective_idp_sso_url),
      certificate_fingerprints: Map.get(revision, :certificate_fingerprints),
      trust_summary: Map.get(revision, :trust_summary),
      cause: Map.get(revision, :cause),
      details: Map.get(revision, :details),
      inserted_at: Map.get(revision, :inserted_at),
      updated_at: Map.get(revision, :updated_at)
    }
    |> reject_nil()
  end

  @doc """
  Hashes a given correlation_id to prevent leaking user identifiable correlation strings
  across system boundaries.
  """
  def hash_correlation_id(nil), do: nil
  def hash_correlation_id(""), do: nil
  def hash_correlation_id(id) when is_binary(id) do
    :crypto.hash(:sha256, id)
    |> Base.encode16(case: :lower)
  end
  def hash_correlation_id(id), do: hash_correlation_id(to_string(id))

  defp reject_nil(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
