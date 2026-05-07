defmodule Relyra.Metadata.DriftDetector do
  @moduledoc """
  Drift detection for Phase 21 scheduled metadata refresh per D-18.

  A "drift" is either:
    - the freshly-fetched `entityID` does not match the persisted
      `idp_entity_id` on the connection (`:entity_id_drift`), or
    - the freshly-fetched signing-cert fingerprint set contains an
      element NOT in the persisted `last_known_metadata_signing_certs`
      MapSet (`:new_signing_cert`).

  On drift, the wrapper auto-suspends the source and refuses to apply
  this revision. Per D-32, the new cert still stages as `:next` via the
  existing certificate-inventory path — drift detection ONLY pauses the
  scheduled apply pending operator review (Phase 10/12 D-08 unchanged).

  Why fingerprints, not PEMs: comparing PEM strings is whitespace-sensitive
  (RESEARCH Pitfall 7). A metadata reformat that re-emits the same cert
  with different line wrapping would re-fire `:new_signing_cert`. Compare
  MapSets of SHA-256 fingerprints only.

  Pure: no I/O, no Ecto. Caller passes already-fingerprint-extracted lists.
  """

  @type drift_result ::
          {:ok, :no_drift}
          | {:drift,
             %{
               entity_id_changed?: boolean(),
               new_signing_certs: [String.t()],
               reason: :entity_id_drift | :new_signing_cert
             }}

  @doc """
  Compares a freshly-parsed metadata `candidate` against the stored
  connection + source state.

  `candidate`:
    - `:idp_entity_id` (string)
    - `:certificate_fingerprints` (list of SHA-256 hex strings)

  `source_state`:
    - `:idp_entity_id` (string — from the `Connection`, not the source row)
    - `:last_known_metadata_signing_certs` (list of SHA-256 hex strings — from `MetadataSource`)

  Returns `{:ok, :no_drift}` or `{:drift, %{reason: ...}}`.
  """
  @spec diff(map(), map()) :: drift_result()
  def diff(%{} = candidate, %{} = source_state) do
    candidate_fps = MapSet.new(Map.get(candidate, :certificate_fingerprints, []))
    known_fps = MapSet.new(Map.get(source_state, :last_known_metadata_signing_certs, []))
    new_fps = MapSet.difference(candidate_fps, known_fps)

    candidate_entity_id = Map.get(candidate, :idp_entity_id)
    stored_entity_id = Map.get(source_state, :idp_entity_id)

    entity_id_changed? = entity_id_drift?(stored_entity_id, candidate_entity_id)

    cond do
      entity_id_changed? ->
        {:drift,
         %{
           entity_id_changed?: true,
           new_signing_certs: MapSet.to_list(new_fps),
           reason: :entity_id_drift
         }}

      MapSet.size(known_fps) > 0 and MapSet.size(new_fps) > 0 ->
        # A `:new_signing_cert` is only a drift when there IS prior known
        # state to compare against. The first-ever fetch (known_fps empty)
        # is initialization, not drift.
        {:drift,
         %{
           entity_id_changed?: false,
           new_signing_certs: MapSet.to_list(new_fps),
           reason: :new_signing_cert
         }}

      true ->
        {:ok, :no_drift}
    end
  end

  defp entity_id_drift?(nil, _candidate), do: false
  defp entity_id_drift?(_stored, nil), do: false
  defp entity_id_drift?(stored, candidate), do: stored != candidate
end
