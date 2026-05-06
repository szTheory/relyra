if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.ConnectionsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Relyra.Ecto.{CertificateInventory, Connections, MappingCommands}
    alias Relyra.LiveAdmin.Components.{ConnectionDetail, ConnectionForm, ConnectionList, PresetPicker}
    alias Relyra.LiveAdmin.Query
    alias Relyra.LiveAdmin.Scope
    alias Relyra.Metadata

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
       |> assign(:connection_form_data, default_connection_form_data(nil, socket.assigns.admin_scope))
       |> assign(:attribute_mappings_json, "[]")
       |> assign(:group_mappings_json, "[]")
       |> assign(:metadata_import_xml, "")
       |> assign(:metadata_source_url, "")}
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
          :new -> Connections.create(attrs, repo: repo, audit: audit)
          _other -> Connections.update(socket.assigns.connection_id, attrs, repo: repo, audit: audit)
        end

      case result do
        {:ok, connection} ->
          {:noreply,
           socket
           |> put_flash(:info, "Connection saved.")
           |> push_navigate(to: show_path(socket.assigns.relyra_admin_base_path, connection.connection_id))}

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

    def handle_event("confirm_activate_certificate", %{"fingerprint" => fingerprint, "confirmation" => confirmation}, socket) do
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
             |> put_flash(:error, "The connection was modified by another operator. Please review the updated trust state.")
             |> reload_detail()}
        end
      else
        {:noreply, put_flash(socket, :error, "Confirmation did not match the certificate fingerprint.")}
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
           |> put_flash(:error, "The connection was modified by another operator. Please review the updated trust state.")
           |> reload_detail()}
      end
    end

    def handle_event(
          "rollback_certificate",
          %{"restore_fingerprint" => restore_fingerprint, "retire_fingerprint" => retire_fingerprint},
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
           |> put_flash(:error, "The connection was modified by another operator. Please review the updated trust state.")
           |> reload_detail()}
      end
    end

    def handle_event("save_attribute_mappings", %{"mapping" => %{"json" => json}}, socket) do
      with {:ok, mappings} <- decode_mapping_json(json) do
        handle_reload_result(
          socket,
          MappingCommands.replace_attribute_mappings(
            socket.assigns.connection_id,
            mappings,
            repo: socket.assigns.relyra_admin_repo,
            audit: audit_context(socket.assigns.admin_scope, "live_admin_attribute_mapping_update")
          ),
          "Attribute mappings saved."
        )
      else
        {:error, message} ->
          {:noreply, put_flash(socket, :error, message)}
      end
    end

    def handle_event("save_group_mappings", %{"mapping" => %{"json" => json}}, socket) do
      with {:ok, mappings} <- decode_mapping_json(json) do
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
        {:error, message} ->
          {:noreply, put_flash(socket, :error, message)}
      end
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
          <ConnectionList.connection_list connections={@connections} base_path={@relyra_admin_base_path} />

          <main>
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
                  attribute_mappings_json={@attribute_mappings_json}
                  group_mappings_json={@group_mappings_json}
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

        {:error, %Relyra.Error{type: :invalid_connection_record, details: %{errors: errors}} = error} ->
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
      assign(socket,
        connection_form_data: connection_form_data(detail.connection, socket.assigns.admin_scope),
        attribute_mappings_json: Jason.encode!(detail.attribute_mappings, pretty: true),
        group_mappings_json: Jason.encode!(detail.group_mappings, pretty: true)
      )
    end

    defp connection_form_data(connection, scope) do
      runtime_policy = if(connection, do: connection.runtime_policy || %{}, else: %{})
      algorithm_policy = Map.get(runtime_policy, :algorithm_policy) || %{}

      %{
        "display_name" => if(connection, do: connection.display_name || "", else: ""),
        "organization_id" => if(connection, do: connection.organization_id || scope.organization_id || "", else: scope.organization_id || ""),
        "provider_preset" => if(connection && connection.provider_preset, do: Atom.to_string(connection.provider_preset), else: ""),
        "sp_entity_id" => if(connection, do: connection.sp_entity_id || "", else: ""),
        "acs_url" => if(connection, do: connection.acs_url || "", else: ""),
        "idp_entity_id" => if(connection, do: connection.idp_entity_id || "", else: ""),
        "idp_sso_url" => if(connection, do: connection.idp_sso_url || "", else: ""),
        "allow_idp_initiated?" => boolean_string(Map.get(runtime_policy, :allow_idp_initiated?, false)),
        "require_signed_assertions?" => boolean_string(Map.get(runtime_policy, :require_signed_assertions?, true)),
        "require_signed_response?" => boolean_string(Map.get(runtime_policy, :require_signed_response?, true)),
        "clock_skew_seconds" => if(connection && runtime_policy.clock_skew_seconds, do: Integer.to_string(runtime_policy.clock_skew_seconds), else: ""),
        "name_id_format" => Map.get(runtime_policy, :name_id_format) || "",
        "algorithm_policy_json" => Jason.encode!(algorithm_policy, pretty: true)
      }
    end

    defp default_connection_form_data(_connection, scope) do
      connection_form_data(nil, scope)
    end

    defp connection_attrs(params, %Scope{} = scope) do
      organization_id = if(scope.organization_id, do: scope.organization_id, else: blank_to_nil(params["organization_id"]))

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

    defp decode_mapping_json(json) when is_binary(json) do
      case Jason.decode(json) do
        {:ok, value} when is_list(value) -> {:ok, value}
        {:ok, _other} -> {:error, "Mappings JSON must decode to a list."}
        {:error, _error} -> {:error, "Mappings JSON is invalid."}
      end
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

    defp maybe_put_req(opts, nil), do: opts
    defp maybe_put_req(opts, req), do: Keyword.put(opts, :req, req)

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
          raise ArgumentError, "Relyra admin requires :relyra_admin_repo to be assigned before mount"

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
