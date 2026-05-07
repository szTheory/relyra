if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.ConnectionsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Relyra.Ecto.{BulkActions, CertificateInventory, Connections, MappingCommands}
    alias Relyra.Metadata

    alias Relyra.LiveAdmin.Components.{
      ConnectionDetail,
      ConnectionForm,
      ConnectionList,
      PresetPicker
    }

    alias Relyra.LiveAdmin.Query
    alias Relyra.LiveAdmin.Scope
    alias Relyra.LiveAdmin.AttributeMappingsForm
    alias Relyra.LiveAdmin.GroupMappingsForm

    @impl true
    def mount(_params, session, socket) do
      socket = ensure_admin_assigns(socket, session)

      {:ok,
       socket
       |> assign(:page_title, "Relyra Admin")
       |> assign(:detail, nil)
       |> assign(:connections, [])
       |> assign(:connection_id, nil)
       |> assign(:provider_options, Query.provider_options())
       |> assign(:audit_filters, %{})
       |> assign(
         :connection_form_data,
         default_connection_form_data(nil, socket.assigns.admin_scope)
       )
       |> assign(
         :attribute_mappings_changeset,
         AttributeMappingsForm.changeset(%AttributeMappingsForm{}, %{})
       )
       |> assign(
         :group_mappings_changeset,
         GroupMappingsForm.changeset(%GroupMappingsForm{}, %{})
       )
       |> assign(:metadata_import_xml, "")
       |> assign(:metadata_source_url, "")
       |> assign(:selected_ids, MapSet.new())}
    end

    @impl true
    def handle_params(params, _uri, socket) do
      audit_filters = Map.take(params, ["actor", "domain", "action"])
      connection_id = params["connection_id"]
      preset_param = params["preset"]

      with {:ok, connections} <-
             Query.list_connections(socket.assigns.relyra_admin_repo, socket.assigns.admin_scope),
           {:ok, detail} <- maybe_load_detail(socket, connection_id, audit_filters) do
        {:noreply,
         socket
         |> assign(:connections, connections)
         |> assign(:connection_id, connection_id)
         |> assign(:detail, detail)
         |> assign(:audit_filters, audit_filters)
         |> assign_forms(detail, preset_param)}
      else
        {:error, error} ->
          {:noreply,
           socket
           |> put_flash(:error, error.message)
           |> push_navigate(to: socket.assigns.relyra_admin_base_path)}
      end
    end

    @impl true
    def handle_event("save_connection", %{"connection" => params}, socket) do
      repo = socket.assigns.relyra_admin_repo
      scope = socket.assigns.admin_scope
      attrs = connection_attrs(params, scope)
      audit = audit_context(scope, "live_admin_connection_save")

      result =
        case socket.assigns.live_action do
          :new ->
            Connections.create(attrs, repo: repo, audit: audit)

          _other ->
            Connections.update(socket.assigns.connection_id, attrs, repo: repo, audit: audit)
        end

      case result do
        {:ok, connection} ->
          {:noreply,
           socket
           |> put_flash(:info, "Connection saved.")
           |> push_navigate(
             to: show_path(socket.assigns.relyra_admin_base_path, connection.connection_id)
           )}

        {:error, error} ->
          {:noreply, put_flash(socket, :error, error.message)}
      end
    end

    def handle_event("enable_connection", _params, socket) do
      transition_connection(socket, :enable)
    end

    def handle_event("disable_connection", _params, socket) do
      transition_connection(socket, :disable)
    end

    def handle_event("toggle_selection", %{"connection-id" => id}, socket) do
      selected_ids = socket.assigns.selected_ids

      selected_ids =
        if MapSet.member?(selected_ids, id) do
          MapSet.delete(selected_ids, id)
        else
          MapSet.put(selected_ids, id)
        end

      {:noreply, assign(socket, :selected_ids, selected_ids)}
    end

    def handle_event("bulk_action", %{"action" => action}, socket) do
      repo = socket.assigns.relyra_admin_repo
      scope = socket.assigns.admin_scope
      ids = MapSet.to_list(socket.assigns.selected_ids)
      audit = audit_context(scope, "live_admin_bulk_#{action}")

      action_fn =
        case action do
          "enable" -> &Connections.enable/2
          "disable" -> &Connections.disable/2
          "refresh_metadata" -> &Metadata.refresh/2
        end

      {:ok, results} = BulkActions.run(repo, ids, action_fn, audit: audit)

      success_count = Enum.count(results, fn {_, res} -> match?({:ok, _}, res) end)
      error_count = map_size(results) - success_count

      msg =
        "Processed #{map_size(results)} connections: #{success_count} succeeded, #{error_count} failed."

      {:noreply,
       socket
       |> put_flash(:info, msg)
       |> assign(:selected_ids, MapSet.new())
       |> reload_connections()}
    end

    def handle_event(
          "confirm_activate_certificate",
          %{"fingerprint" => fingerprint, "confirmation" => confirmation},
          socket
        ) do
      if confirmation == String.slice(fingerprint, 0..5) do
        try do
          handle_reload_result(
            socket,
            CertificateInventory.activate_signing_certificate(
              socket.assigns.relyra_admin_repo,
              socket.assigns.connection_id,
              fingerprint,
              audit: audit_context(socket.assigns.admin_scope, "live_admin_activate_certificate")
            ),
            "Certificate promoted."
          )
        rescue
          Ecto.StaleEntryError ->
            {:noreply,
             socket
             |> put_flash(
               :error,
               "The connection was modified by another operator. Please review the updated trust state."
             )
             |> reload_detail()}
        end
      else
        {:noreply,
         put_flash(socket, :error, "Confirmation did not match the certificate fingerprint.")}
      end
    end

    def handle_event("retire_certificate", %{"fingerprint" => fingerprint}, socket) do
      try do
        handle_reload_result(
          socket,
          CertificateInventory.retire_signing_certificate(
            socket.assigns.relyra_admin_repo,
            socket.assigns.connection_id,
            fingerprint,
            audit: audit_context(socket.assigns.admin_scope, "live_admin_retire_certificate")
          ),
          "Certificate retired."
        )
      rescue
        Ecto.StaleEntryError ->
          {:noreply,
           socket
           |> put_flash(
             :error,
             "The connection was modified by another operator. Please review the updated trust state."
           )
           |> reload_detail()}
      end
    end

    def handle_event(
          "rollback_certificate",
          %{
            "restore_fingerprint" => restore_fingerprint,
            "retire_fingerprint" => retire_fingerprint
          },
          socket
        ) do
      try do
        handle_reload_result(
          socket,
          CertificateInventory.rollback_signing_certificate(
            socket.assigns.relyra_admin_repo,
            socket.assigns.connection_id,
            restore_fingerprint,
            retire_fingerprint,
            audit: audit_context(socket.assigns.admin_scope, "live_admin_rollback_certificate")
          ),
          "Certificate rollback completed."
        )
      rescue
        Ecto.StaleEntryError ->
          {:noreply,
           socket
           |> put_flash(
             :error,
             "The connection was modified by another operator. Please review the updated trust state."
           )
           |> reload_detail()}
      end
    end

    def handle_event(
          "validate_attribute_mappings",
          %{"attribute_mappings_form" => params},
          socket
        ) do
      changeset =
        socket.assigns.attribute_mappings_changeset.data
        |> AttributeMappingsForm.changeset(params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :attribute_mappings_changeset, changeset)}
    end

    def handle_event("save_attribute_mappings", %{"attribute_mappings_form" => params}, socket) do
      changeset =
        AttributeMappingsForm.changeset(socket.assigns.attribute_mappings_changeset.data, params)

      if changeset.valid? do
        mappings =
          Ecto.Changeset.apply_changes(changeset).mappings
          |> Enum.map(&Map.from_struct/1)
          |> Enum.map(&Map.drop(&1, [:id]))

        handle_reload_result(
          socket,
          MappingCommands.replace_attribute_mappings(
            socket.assigns.connection_id,
            mappings,
            repo: socket.assigns.relyra_admin_repo,
            audit:
              audit_context(socket.assigns.admin_scope, "live_admin_attribute_mapping_update")
          ),
          "Attribute mappings saved."
        )
      else
        {:noreply,
         assign(socket, attribute_mappings_changeset: Map.put(changeset, :action, :insert))}
      end
    end

    def handle_event("add_attribute_mapping", _params, socket) do
      form = socket.assigns.attribute_mappings_changeset.data

      current_mappings =
        Ecto.Changeset.get_field(socket.assigns.attribute_mappings_changeset, :mappings) || []

      # Build params to recreate the current state + 1 new empty mapping
      params = %{
        "mappings" => current_mappings ++ [%{}]
      }

      changeset = AttributeMappingsForm.changeset(form, params)
      {:noreply, assign(socket, :attribute_mappings_changeset, changeset)}
    end

    def handle_event("remove_attribute_mapping", %{"index" => index}, socket) do
      form = socket.assigns.attribute_mappings_changeset.data

      current_mappings =
        Ecto.Changeset.get_field(socket.assigns.attribute_mappings_changeset, :mappings) || []

      idx = String.to_integer(index)
      updated_mappings = List.delete_at(current_mappings, idx)

      params = %{
        "mappings" => Enum.map(updated_mappings, &Map.from_struct(&1))
      }

      changeset = AttributeMappingsForm.changeset(form, params)
      {:noreply, assign(socket, :attribute_mappings_changeset, changeset)}
    end

    def handle_event("validate_group_mappings", %{"group_mappings_form" => params}, socket) do
      changeset =
        socket.assigns.group_mappings_changeset.data
        |> GroupMappingsForm.changeset(params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :group_mappings_changeset, changeset)}
    end

    def handle_event("save_group_mappings", %{"group_mappings_form" => params}, socket) do
      changeset =
        GroupMappingsForm.changeset(socket.assigns.group_mappings_changeset.data, params)

      if changeset.valid? do
        mappings =
          Ecto.Changeset.apply_changes(changeset).mappings
          |> Enum.map(&Map.from_struct/1)
          |> Enum.map(&Map.drop(&1, [:id]))

        handle_reload_result(
          socket,
          MappingCommands.replace_group_mappings(
            socket.assigns.connection_id,
            mappings,
            repo: socket.assigns.relyra_admin_repo,
            audit: audit_context(socket.assigns.admin_scope, "live_admin_group_mapping_update")
          ),
          "Group mappings saved."
        )
      else
        {:noreply, assign(socket, group_mappings_changeset: Map.put(changeset, :action, :insert))}
      end
    end

    def handle_event("add_group_mapping", _params, socket) do
      form = socket.assigns.group_mappings_changeset.data

      current_mappings =
        Ecto.Changeset.get_field(socket.assigns.group_mappings_changeset, :mappings) || []

      params = %{
        "mappings" => current_mappings ++ [%{}]
      }

      changeset = GroupMappingsForm.changeset(form, params)
      {:noreply, assign(socket, :group_mappings_changeset, changeset)}
    end

    def handle_event("remove_group_mapping", %{"index" => index}, socket) do
      form = socket.assigns.group_mappings_changeset.data

      current_mappings =
        Ecto.Changeset.get_field(socket.assigns.group_mappings_changeset, :mappings) || []

      idx = String.to_integer(index)
      updated_mappings = List.delete_at(current_mappings, idx)

      params = %{
        "mappings" => Enum.map(updated_mappings, &Map.from_struct(&1))
      }

      changeset = GroupMappingsForm.changeset(form, params)
      {:noreply, assign(socket, :group_mappings_changeset, changeset)}
    end

    def handle_event("filter_audits", %{"filters" => filters}, socket) do
      # Make sure we don't carry over extraneous params.
      filters = Map.take(filters, ["actor", "domain", "action"])

      # We could patch the URL to preserve the filters in query string.
      {:noreply,
       socket
       |> assign(:audit_filters, filters)
       |> push_patch(
         to:
           show_path(socket.assigns.relyra_admin_base_path, socket.assigns.connection_id) <>
             "?" <> URI.encode_query(filters)
       )}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div style="padding: 24px; font-family: Helvetica, Arial, sans-serif;">
        <header style="margin-bottom: 24px;">
          <h1 style="font-size: 28px; margin: 0;">Relyra Admin</h1>
          <p style="color: #555; margin-top: 8px;">
            {@admin_scope |> Scope.scope_label()} · acting as {@admin_scope |> Scope.actor_label()}
          </p>
        </header>

        <section style="display: grid; grid-template-columns: minmax(260px, 320px) 1fr; gap: 24px;">
          <ConnectionList.connection_list
            connections={@connections}
            base_path={@relyra_admin_base_path}
            selected_ids={@selected_ids}
          />

          <main>
            <div :if={MapSet.size(@selected_ids) > 0} style="margin-bottom: 20px; padding: 12px; background: #f0f4f8; border: 1px solid #d1d9e1; border-radius: 4px; display: flex; align-items: center; gap: 16px;">
              <span style="font-weight: bold;">Bulk Actions ({MapSet.size(@selected_ids)} selected):</span>
              <button phx-click="bulk_action" phx-value-action="enable" style="padding: 4px 8px; cursor: pointer;">Enable</button>
              <button phx-click="bulk_action" phx-value-action="disable" style="padding: 4px 8px; cursor: pointer;">Disable</button>
              <button phx-click="bulk_action" phx-value-action="refresh_metadata" style="padding: 4px 8px; cursor: pointer;">Refresh Metadata</button>
            </div>

            <%= case @live_action do %>
              <% :new -> %>
                {render_connection_editor(assigns, :new)}
              <% :edit -> %>
                {render_connection_editor(assigns, :edit)}
              <% :show -> %>
                <ConnectionDetail.connection_detail
                  detail={@detail}
                  base_path={@relyra_admin_base_path}
                  metadata_import_xml={@metadata_import_xml}
                  metadata_source_url={@metadata_source_url}
                  attribute_mappings_changeset={@attribute_mappings_changeset}
                  group_mappings_changeset={@group_mappings_changeset}
                  audit_filters={@audit_filters}
                />
              <% _ -> %>
                <div style="padding: 16px; border: 1px solid #ddd;">
                  Select a connection or create a new one.
                </div>
            <% end %>
          </main>
        </section>
      </div>
      """
    end

    defp render_connection_editor(assigns, mode) do
      assigns = assign(assigns, :mode, mode)

      ~H"""
      <section>
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
          <h2 style="font-size: 20px; margin: 0;">
            <%= if @mode == :new, do: "New connection", else: "Edit connection" %>
          </h2>
          <a :if={@detail} href={show_path(@relyra_admin_base_path, @detail.connection.connection_id)}>Back</a>
        </div>

        <PresetPicker.preset_picker
          :if={@mode == :new}
          provider_options={@provider_options}
          selected_preset={@connection_form_data["provider_preset"] || ""}
          base_path={@relyra_admin_base_path}
        />

        <ConnectionForm.connection_form
          connection_form_data={@connection_form_data}
          admin_scope={@admin_scope}
          risk_flags={if @detail, do: @detail.risk_flags, else: []}
        />
      </section>
      """
    end

    defp transition_connection(socket, transition) do
      repo = socket.assigns.relyra_admin_repo
      audit = audit_context(socket.assigns.admin_scope, "live_admin_connection_#{transition}")

      result =
        case transition do
          :enable -> Connections.enable(socket.assigns.connection_id, repo: repo, audit: audit)
          :disable -> Connections.disable(socket.assigns.connection_id, repo: repo, audit: audit)
        end

      case result do
        {:ok, _record} ->
          {:noreply, socket |> reload_detail() |> put_flash(:info, "Connection #{transition}d.")}

        {:error,
         %Relyra.Error{type: :invalid_connection_record, details: %{errors: errors}} = error} ->
          detail = socket.assigns.detail
          connection = %{detail.connection | readiness_errors: errors}
          detail = %{detail | connection: connection}
          {:noreply, socket |> assign(:detail, detail) |> put_flash(:error, error.message)}

        {:error, error} ->
          {:noreply, put_flash(socket, :error, error.message)}
      end
    end

    defp handle_reload_result(socket, {:ok, _result}, message) do
      {:noreply, socket |> reload_detail() |> put_flash(:info, message)}
    end

    defp handle_reload_result(socket, {:error, error}, _message) do
      {:noreply, put_flash(socket, :error, error.message)}
    end

    defp reload_connections(socket) do
      {:ok, connections} =
        Query.list_connections(socket.assigns.relyra_admin_repo, socket.assigns.admin_scope)

      assign(socket, :connections, connections)
    end

    defp maybe_load_detail(_socket, nil, _filters), do: {:ok, nil}

    defp maybe_load_detail(socket, connection_id, filters) do
      Query.get_connection_detail(
        socket.assigns.relyra_admin_repo,
        socket.assigns.admin_scope,
        connection_id,
        filters
      )
    end

    defp reload_detail(%{assigns: %{connection_id: nil}} = socket), do: socket

    defp reload_detail(socket) do
      {:ok, detail} =
        Query.get_connection_detail(
          socket.assigns.relyra_admin_repo,
          socket.assigns.admin_scope,
          socket.assigns.connection_id,
          socket.assigns.audit_filters
        )

      socket |> assign(:detail, detail) |> assign_forms(detail)
    end

    defp assign_forms(socket, detail, preset_param \\ nil)

    defp assign_forms(socket, nil, preset_param) do
      base_data = default_connection_form_data(nil, socket.assigns.admin_scope)

      form_data =
        if preset_param && preset_param != "" do
          try do
            preset_atom = String.to_existing_atom(preset_param)

            if preset_atom in Relyra.Provider.list() do
              defaults_map = Map.new(Relyra.Provider.apply_defaults(preset_atom, []))

              conn_map = %{
                display_name: nil,
                organization_id: nil,
                provider_preset: preset_atom,
                sp_entity_id: Map.get(defaults_map, :sp_entity_id),
                acs_url: Map.get(defaults_map, :acs_url),
                idp_entity_id: Map.get(defaults_map, :idp_entity_id),
                idp_sso_url: Map.get(defaults_map, :idp_sso_url),
                runtime_policy: defaults_map
              }

              connection_form_data(conn_map, socket.assigns.admin_scope)
            else
              base_data
            end
          rescue
            ArgumentError -> base_data
          end
        else
          base_data
        end

      assign(socket, :connection_form_data, form_data)
    end

    defp assign_forms(socket, detail, _preset_param) do
      attribute_mappings_form = %AttributeMappingsForm{
        mappings:
          Enum.map(detail.attribute_mappings, fn m ->
            %Relyra.LiveAdmin.AttributeMappingForm{
              source_attribute: m.source_attribute,
              target_field: m.target_field,
              multivalue_strategy: m.multivalue_strategy
            }
          end)
      }

      group_mappings_form = %GroupMappingsForm{
        mappings:
          Enum.map(detail.group_mappings, fn m ->
            %Relyra.LiveAdmin.GroupMappingForm{
              source_attribute: m.source_attribute,
              source_value: m.source_value,
              role_target: m.role_target,
              role_value: m.role_value
            }
          end)
      }

      assign(socket,
        connection_form_data: connection_form_data(detail.connection, socket.assigns.admin_scope),
        attribute_mappings_changeset:
          AttributeMappingsForm.changeset(attribute_mappings_form, %{}),
        group_mappings_changeset: GroupMappingsForm.changeset(group_mappings_form, %{})
      )
    end

    defp connection_form_data(connection, scope) do
      runtime_policy = if(connection, do: connection.runtime_policy || %{}, else: %{})
      algorithm_policy = Map.get(runtime_policy, :algorithm_policy) || %{}

      %{
        "display_name" => if(connection, do: connection.display_name || "", else: ""),
        "organization_id" =>
          if(connection,
            do: connection.organization_id || scope.organization_id || "",
            else: scope.organization_id || ""
          ),
        "provider_preset" =>
          if(connection && connection.provider_preset,
            do: Atom.to_string(connection.provider_preset),
            else: ""
          ),
        "sp_entity_id" => if(connection, do: connection.sp_entity_id || "", else: ""),
        "acs_url" => if(connection, do: connection.acs_url || "", else: ""),
        "idp_entity_id" => if(connection, do: connection.idp_entity_id || "", else: ""),
        "idp_sso_url" => if(connection, do: connection.idp_sso_url || "", else: ""),
        "allow_idp_initiated?" =>
          boolean_string(Map.get(runtime_policy, :allow_idp_initiated?, false)),
        "require_signed_assertions?" =>
          boolean_string(Map.get(runtime_policy, :require_signed_assertions?, true)),
        "require_signed_response?" =>
          boolean_string(Map.get(runtime_policy, :require_signed_response?, true)),
        "clock_skew_seconds" =>
          if(connection && runtime_policy.clock_skew_seconds,
            do: Integer.to_string(runtime_policy.clock_skew_seconds),
            else: ""
          ),
        "name_id_format" => Map.get(runtime_policy, :name_id_format) || "",
        "algorithm_policy_json" => Jason.encode!(algorithm_policy, pretty: true)
      }
    end

    defp default_connection_form_data(_connection, scope) do
      connection_form_data(nil, scope)
    end

    defp connection_attrs(params, %Scope{} = scope) do
      organization_id =
        if(scope.organization_id,
          do: scope.organization_id,
          else: blank_to_nil(params["organization_id"])
        )

      %{
        display_name: blank_to_nil(params["display_name"]),
        organization_id: organization_id,
        provider_preset: maybe_to_atom(params["provider_preset"]),
        sp_entity_id: blank_to_nil(params["sp_entity_id"]),
        acs_url: blank_to_nil(params["acs_url"]),
        idp_entity_id: blank_to_nil(params["idp_entity_id"]),
        idp_sso_url: blank_to_nil(params["idp_sso_url"]),
        runtime_policy: %{
          allow_idp_initiated?: truthy?(params["allow_idp_initiated?"]),
          require_signed_assertions?: truthy?(params["require_signed_assertions?"]),
          require_signed_response?: truthy?(params["require_signed_response?"]),
          clock_skew_seconds: parse_integer(params["clock_skew_seconds"]),
          name_id_format: blank_to_nil(params["name_id_format"]),
          algorithm_policy: decode_json_map(params["algorithm_policy_json"])
        }
      }
    end

    defp audit_context(%Scope{} = scope, cause) do
      %{actor: scope.actor, cause: cause}
    end

    defp decode_json_map(json) when is_binary(json) do
      case Jason.decode(json) do
        {:ok, value} when is_map(value) -> value
        _other -> %{}
      end
    end

    defp decode_json_map(_json), do: %{}

    defp blank_to_nil(nil), do: nil

    defp blank_to_nil(value) when is_binary(value) do
      value = String.trim(value)
      if value == "", do: nil, else: value
    end

    defp parse_integer(nil), do: nil
    defp parse_integer(""), do: nil

    defp parse_integer(value) when is_binary(value) do
      case Integer.parse(value) do
        {parsed, ""} -> parsed
        _other -> nil
      end
    end

    defp maybe_to_atom(nil), do: nil
    defp maybe_to_atom(""), do: nil
    defp maybe_to_atom(value), do: String.to_atom(value)

    defp truthy?(value), do: value in ["true", "on", true]
    defp boolean_string(true), do: "true"
    defp boolean_string(false), do: "false"

    defp ensure_admin_assigns(socket, session) do
      socket = ensure_changed_assigns(socket)
      admin_scope = socket.assigns[:admin_scope] || session_value(session, "admin_scope")
      repo = socket.assigns[:relyra_admin_repo] || session_value(session, "relyra_admin_repo")
      req = socket.assigns[:relyra_admin_req] || session_value(session, "relyra_admin_req")

      base_path =
        socket.assigns[:relyra_admin_base_path] ||
          session_value(session, "relyra_admin_base_path") ||
          "/relyra/admin"

      cond do
        is_nil(admin_scope) ->
          raise ArgumentError, "Relyra admin requires :admin_scope to be assigned before mount"

        is_nil(repo) ->
          raise ArgumentError,
                "Relyra admin requires :relyra_admin_repo to be assigned before mount"

        true ->
          socket
          |> assign(:admin_scope, admin_scope)
          |> assign(:relyra_admin_repo, repo)
          |> assign(:relyra_admin_req, req)
          |> assign(:relyra_admin_base_path, base_path)
      end
    end

    defp ensure_changed_assigns(%Phoenix.LiveView.Socket{assigns: assigns} = socket) do
      if Map.has_key?(assigns, :__changed__) do
        socket
      else
        %{socket | assigns: Map.put(assigns, :__changed__, %{})}
      end
    end

    defp session_value(session, key) do
      Map.get(session, key) || Map.get(session, String.to_atom(key))
    end

    defp show_path(base_path, connection_id), do: "#{base_path}/connections/#{connection_id}"
  end
else
  defmodule Relyra.LiveAdmin.ConnectionsLive do
    @moduledoc false
  end
end
