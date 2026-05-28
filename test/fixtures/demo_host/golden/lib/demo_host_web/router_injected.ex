defmodule DemoHostWeb.Router do
  use Phoenix.Router
  # --- Relyra SAML routes ---
  import Relyra.Phoenix.Router
  saml_routes()
end
