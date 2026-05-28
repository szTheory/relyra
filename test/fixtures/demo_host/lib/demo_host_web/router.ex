defmodule DemoHostWeb.Router do
  @moduledoc false
  use Phoenix.Router

  # --- Relyra SAML routes ---
  import Relyra.Phoenix.Router
  saml_routes()
end
