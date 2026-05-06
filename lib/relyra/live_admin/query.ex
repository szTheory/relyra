if Code.ensure_loaded?(Ecto.Query) and Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.LiveAdmin.Query do
    @moduledoc false

    import Ecto.Query

    alias Relyra.Ecto.{
      AttributeMapping,
      AuditEvent,
      Certificate,
      Connection,
      GroupMapping,
      MappingRevision,
      MetadataRevision,
      MetadataSource
    }

    alias Relyra.Error
    alias Relyra.LiveAdmin.Scope
    alias Relyra.Provider

    @spec list_connections(module(), Scope.t()) :: {:ok, [map()]} | {:error, Error.t()}
    def list_connections(repo, %Scope{} = scope) when is_atom(repo) do
      with :ok <- ensure_repo(repo, :list_connections) do
        rows =
          Connection
          |> scope_query(scope)
          |> order_by([connection], asc: connection.organization_id, asc: connection.display_name)
          |> repo.all()
          |> Enum.map(&connection_summary/1)

        {:ok, rows}
      end
    end

    @spec get_connection_detail(module(), Scope.t(), binary(), map()) ::
            {:ok, map()} | {:error, Error.t()}
    def get_connection_detail(repo, %Scope{} = scope, connection_id, audit_filters \\ %{})
        when is_atom(repo) and is_binary(connection_id) and is_map(audit_filters) do
      with :ok <- ensure_repo(repo, :get_connection_detail),
           {:ok, connection} <- fetch_connection(repo, scope, connection_id) do
        connection =
          repo.preload(connection, [
            :certificates,
            :attribute_mappings,
            :group_mappings,
            :mapping_revisions,
            :audit_events,
            :active_metadata_revision,
            :last_known_good_metadata_revision
          ])

        metadata_source = repo.get_by(MetadataSource, connection_record_id: connection.id)

        metadata_revisions =
          MetadataRevision
          |> where([revision], revision.connection_record_id == ^connection.id)
          |> order_by([revision], desc: revision.inserted_at)
          |> preload([:metadata_source])
          |> repo.all()

        mapping_revisions =
          MappingRevision
          |> where([revision], revision.connection_record_id == ^connection.id)
          |> order_by([revision], desc: revision.inserted_at)
          |> repo.all()

        audit_events =
          AuditEvent
          |> where([event], event.connection_record_id == ^connection.id)
          |> apply_audit_filters(audit_filters)
          |> order_by([event], desc: event.inserted_at)
          |> limit(50)
          |> repo.all()

        {:ok,
         %{
           connection: connection,
           metadata_source: metadata_source,
           metadata_revisions: metadata_revisions,
           mapping_revisions: mapping_revisions,
           audit_events: audit_events,
           attribute_mappings: normalize_attribute_mappings(connection.attribute_mappings),
           group_mappings: normalize_group_mappings(connection.group_mappings),
           certificates_by_state: certificates_by_state(connection.certificates),
           risk_flags: risk_flags(connection),
           provider_label: provider_label(connection.provider_preset)
         }}
      end
    end

    def get_metadata_revisions(repo, %Scope{} = scope, connection_id)
        when is_atom(repo) and is_binary(connection_id) do
      with :ok <- ensure_repo(repo, :get_metadata_revisions),
           {:ok, connection} <- fetch_connection(repo, scope, connection_id) do
        revisions =
          MetadataRevision
          |> where([revision], revision.connection_record_id == ^connection.id)
          |> order_by([revision], desc: revision.inserted_at)
          |> preload([:metadata_source])
          |> limit(10)
          |> repo.all()

        metadata_source = repo.get_by(MetadataSource, connection_record_id: connection.id)

        {:ok,
         %{
           connection: connection,
           metadata_source: metadata_source,
           revisions: revisions
         }}
      end
    end

    @spec provider_options() :: [{String.t(), String.t()}]
    def provider_options do
      Provider.list()
      |> Enum.map(fn preset ->
        {Provider.display_name(preset), Atom.to_string(preset)}
      end)
    end

    defp fetch_connection(repo, %Scope{} = scope, connection_id) do
      query =
        Connection
        |> scope_query(scope)
        |> where([connection], connection.connection_id == ^connection_id)

      case repo.one(query) do
        nil ->
          {:error,
           Error.new(
             :connection_not_found,
             "Connection record was not found",
             %{operation: :get_connection_detail, connection_id: connection_id}
           )}

        connection ->
          {:ok, connection}
      end
    end

    defp scope_query(query, %Scope{organization_id: nil}), do: query

    defp scope_query(query, %Scope{organization_id: organization_id}) do
      where(query, [connection], connection.organization_id == ^organization_id)
    end

    defp connection_summary(connection) do
      %{
        connection_id: connection.connection_id,
        display_name: connection.display_name || connection.connection_id,
        organization_id: connection.organization_id,
        status: connection.status,
        provider_preset: connection.provider_preset,
        provider_label: provider_label(connection.provider_preset),
        inserted_at: connection.inserted_at,
        updated_at: connection.updated_at
      }
    end

    defp normalize_attribute_mappings(rows) do
      Enum.map(rows, fn %AttributeMapping{} = row ->
        %{
          source_attribute: row.source_attribute,
          target_field: row.target_field,
          multivalue_strategy: row.multivalue_strategy
        }
      end)
    end

    defp normalize_group_mappings(rows) do
      Enum.map(rows, fn %GroupMapping{} = row ->
        %{
          source_attribute: row.source_attribute,
          source_value: row.source_value,
          role_target: row.role_target,
          role_value: row.role_value
        }
      end)
    end

    defp certificates_by_state(certificates) do
      Enum.reduce(certificates, %{active: [], next: [], retired: []}, fn %Certificate{} = certificate, acc ->
        Map.update!(acc, certificate.lifecycle_state, &[certificate | &1])
      end)
      |> Map.new(fn {state, rows} ->
        {state, Enum.sort_by(rows, &{&1.not_after || ~U[0000-01-01 00:00:00Z], &1.fingerprint_sha256})}
      end)
    end

    defp risk_flags(%Connection{runtime_policy: nil}), do: []

    defp risk_flags(%Connection{runtime_policy: runtime_policy}) do
      algorithm_policy = Map.get(runtime_policy, :algorithm_policy) || %{}

      if algorithm_policy == %{} do
        []
      else
        label =
          if Map.get(algorithm_policy, "legacy_sha1") || Map.get(algorithm_policy, :legacy_sha1) do
            "Legacy SHA-1 support enabled (compatibility override)"
          else
            "Legacy algorithm policy override"
          end

        [
          %{
            label: label,
            details: algorithm_policy
          }
        ]
      end
    end

    defp provider_label(nil), do: "Custom"

    defp provider_label(preset) do
      try do
        Provider.display_name(preset)
      rescue
        ArgumentError -> "Custom"
      end
    end

    defp apply_audit_filters(query, filters) do
      query
      |> maybe_filter_actor(Map.get(filters, "actor"))
      |> maybe_filter_domain(Map.get(filters, "domain"))
      |> maybe_filter_action(Map.get(filters, "action"))
    end

    defp maybe_filter_actor(query, actor) when is_binary(actor) and actor != "" do
      where(query, [event], event.actor == ^actor)
    end

    defp maybe_filter_actor(query, _actor), do: query

    defp maybe_filter_domain(query, domain) when is_binary(domain) and domain != "" do
      case safe_existing_atom(domain) do
        nil -> query
        atom -> where(query, [event], event.domain == ^atom)
      end
    end

    defp maybe_filter_domain(query, _domain), do: query

    defp maybe_filter_action(query, action) when is_binary(action) and action != "" do
      case safe_existing_atom(action) do
        nil -> query
        atom -> where(query, [event], event.action == ^atom)
      end
    end

    defp maybe_filter_action(query, _action), do: query

    defp safe_existing_atom(value) do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> nil
    end

    defp ensure_repo(repo, operation) do
      cond do
        not Code.ensure_loaded?(repo) ->
          {:error,
           Error.new(
              :adapter_not_configured,
             "Relyra admin repo is unavailable",
              %{operation: operation, repo: inspect(repo)}
            )}

        true ->
          :ok
      end
    end
  end
else
  defmodule Relyra.LiveAdmin.Query do
    @moduledoc false
  end
end
