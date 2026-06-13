defmodule LedgerLoopWeb.HealthControllerTest do
  use LedgerLoopWeb.ConnCase, async: false

  setup do
    previous = Application.fetch_env(:ledger_loop, :ready_state)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:ledger_loop, :ready_state, value)
        :error -> Application.delete_env(:ledger_loop, :ready_state)
      end
    end)

    :ok
  end

  test "GET /healthz reports booted", %{conn: conn} do
    conn = get(conn, ~p"/healthz")

    assert conn.status == 200
    assert conn.resp_body =~ "booted"
  end

  test "GET /readyz reports ready when forced ready", %{conn: conn} do
    Application.put_env(:ledger_loop, :ready_state, :force_ready)

    conn = get(conn, ~p"/readyz")

    assert conn.status == 200
    assert conn.resp_body =~ "ready"
  end

  test "GET /readyz reports unavailable when forced unavailable", %{conn: conn} do
    Application.put_env(:ledger_loop, :ready_state, :force_unavailable)

    conn = get(conn, ~p"/readyz")

    assert conn.status == 503
    assert conn.resp_body =~ "unavailable"
  end
end
