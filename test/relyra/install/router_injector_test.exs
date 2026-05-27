defmodule Relyra.Install.RouterInjectorTest do
  use ExUnit.Case, async: true

  alias Relyra.Install.RouterInjector

  @marker "# --- Relyra SAML routes ---"

  test "inject success inserts marker, import, and saml_routes after use Router" do
    router = """
    defmodule DemoAppWeb.Router do
      use Phoenix.Router

      pipeline :browser do
        plug :accepts, ["html"]
      end
    end
    """

    assert {:ok, result} = RouterInjector.inject(router)
    assert result =~ @marker
    assert result =~ "import Relyra.Phoenix.Router"
    assert result =~ "saml_routes()"
    assert result =~ "use Phoenix.Router\n#{@marker}"
  end

  test "idempotent when marker already present" do
    router = """
    defmodule DemoAppWeb.Router do
      use Phoenix.Router
      #{@marker}
      import Relyra.Phoenix.Router
      saml_routes()
    end
    """

    assert {:already_injected, ^router} = RouterInjector.inject(router)
  end

  test "ambiguous when no use Router anchor exists" do
    router = """
    defmodule DemoAppWeb.NotRouter do
      use DemoAppWeb, :controller
    end
    """

    assert :ambiguous = RouterInjector.inject(router)
  end

  test "already_injected when saml_routes exists without marker" do
    router = """
    defmodule DemoAppWeb.Router do
      use Phoenix.Router
      saml_routes()
    end
    """

    assert {:already_injected, ^router} = RouterInjector.inject(router)
  end
end
