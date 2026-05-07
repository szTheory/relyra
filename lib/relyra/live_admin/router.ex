if Code.ensure_loaded?(Phoenix.LiveView.Router) do
  defmodule Relyra.LiveAdmin.Router do
    @moduledoc """
    Mountable LiveView router for the optional Relyra admin surface.
    """

    defmacro relyra_admin_routes(path \\ "/relyra/admin", opts \\ []) do
      quote bind_quoted: [path: path, opts: opts] do
        import Phoenix.LiveView.Router

        scope path, as: :relyra_admin do
          live_session :relyra_admin,
            on_mount: [
              {Relyra.LiveAdmin.OnMount, Keyword.put(opts, :base_path, path)}
            ] do
            live("/", Relyra.LiveAdmin.ConnectionsLive, :index)
            live("/connections/new", Relyra.LiveAdmin.ConnectionsLive, :new)
            live("/connections/:connection_id", Relyra.LiveAdmin.ConnectionsLive, :show)
            live("/connections/:connection_id/edit", Relyra.LiveAdmin.ConnectionsLive, :edit)

            live(
              "/connections/:connection_id/metadata",
              Relyra.LiveAdmin.ConnectionMetadataLive,
              :metadata
            )
          end
        end
      end
    end
  end
else
  defmodule Relyra.LiveAdmin.Router do
    @moduledoc """
    Fallback router macro when Phoenix LiveView is unavailable.
    """

    defmacro relyra_admin_routes(_path \\ "/relyra/admin", _opts \\ []) do
      Relyra.LiveAdmin.ensure_available!()
    end
  end
end
