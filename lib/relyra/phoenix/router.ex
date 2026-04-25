defmodule Relyra.Phoenix.Router do
  @moduledoc """
  Exposes the `saml_routes/2` macro for mounting SAML endpoints in a Phoenix router.
  """

  defmacro saml_routes(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      scope "/", Relyra.Phoenix.Controllers do
        pipe_through Relyra.Phoenix.Pipeline.SkipCSRF

        # Metadata endpoint
        get "/:connection_id/metadata", MetadataController, :show, as: :saml_metadata

        # Start login (GET for links, POST for forms)
        get "/:connection_id/login", LoginController, :new, as: :saml_login
        post "/:connection_id/login", LoginController, :create

        # ACS - inbound assertion
        post "/:connection_id/acs", ACSController, :create, [as: :saml_acs, private: %{relyra_skip_csrf: true}]
      end
    end
  end
end
