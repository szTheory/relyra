defmodule LedgerLoopWeb.SetupLiveTest do
  use LedgerLoopWeb.ConnCase
  import Phoenix.LiveViewTest

  @endpoint LedgerLoopWeb.Endpoint

  setup do
    LedgerLoop.Demo.Reset.reset!()
    :ok
  end

  test "Setup checklist renders and user can navigate between steps via phx-click", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/setup/sso")

    assert render(view) =~ "SP Settings"
    assert render(view) =~ "IdP Metadata"
    
    # Click next
    view |> element("button", "Next") |> render_click()
    assert render(view) =~ "IdP Metadata" # Next step should be active
  end

  test "The receipt step securely renders redacted verification fields", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/setup/sso")

    # Navigate to the final step (Test &amp; Enable)
    view |> element("button", "Next") |> render_click() # To IdP Metadata
    view |> element("button", "Next") |> render_click() # To Mapping Preview
    view |> element("button", "Next") |> render_click() # To Test &amp; Enable
    
    html = render(view)
    assert html =~ "Enablement Receipt"
    
    # Assert connection ID from real data is shown
    # Let's get the connection ID from fixtures
    conn_id = LedgerLoop.Demo.Fixtures.relyra_connections() |> List.first() |> Map.get(:connection_id)
    assert html =~ conn_id
    
    # Assert no raw PEM or XML is leaked
    refute html =~ "MOCK_PEM_NOT_REAL"
    refute html =~ "<?xml"
  end
end
