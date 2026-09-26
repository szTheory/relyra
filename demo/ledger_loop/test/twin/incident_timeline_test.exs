defmodule LedgerLoop.Twin.IncidentTimelineTest do
  use LedgerLoopWeb.ConnCase, async: false
  import Ecto.Query

  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.Repo
  alias Relyra.Diagnostic.AllowList
  alias Relyra.Ecto.AuditEvent
  alias Relyra.LiveAdmin.{Query, Scope}

  setup do
    Reset.reset!()
    :ok
  end

  test "support route, incident stages, trace, and safe exported correlation share one fixture",
       %{conn: conn} do
    conn = get(conn, "/support/scenario")

    assert redirected_to(conn) ==
             "/relyra/admin/connections/#{Fixtures.relyra_support_scenario_id()}/trace"

    connection_id = Fixtures.relyra_support_scenario_id()
    connection_record_id = Fixtures.relyra_support_scenario_record_id()

    events =
      Repo.all(
        from(event in AuditEvent,
          where: event.connection_record_id == ^connection_record_id and event.domain == :login,
          order_by: [asc: event.inserted_at, asc: event.id]
        )
      )

    stages =
      events
      |> Enum.filter(&(&1.diff_summary["kind"] == "support_incident"))

    assert Enum.map(stages, & &1.diff_summary["stage"]) ==
             Enum.map(Fixtures.relyra_support_incident_stages(), &Atom.to_string/1)

    stage_times = Enum.map(stages, & &1.inserted_at)
    assert stage_times == Enum.sort(stage_times)
    assert length(Enum.uniq(stage_times)) == 5
    assert Enum.map(stages, & &1.diff_summary["sequence"]) == Enum.to_list(0..4)

    traces = Enum.filter(events, &(&1.diff_summary["kind"] == "login_trace"))

    assert Enum.map(traces, & &1.diff_summary["step"]) == Fixtures.relyra_support_trace_steps()
    assert Enum.all?(traces, &(&1.connection_record_id == connection_record_id))

    raw_correlation = "support-incident-northstar-20260612"
    assert Enum.all?(events, &(&1.correlation_id == raw_correlation))

    assert {:ok, exports} =
             Query.get_login_traces(
               Repo,
               %Scope{actor: "support-test", organization_id: "northstar"},
               connection_id
             )

    assert length(exports) == length(Fixtures.relyra_support_trace_events()) + length(stages)
    expected_hash = AllowList.hash_correlation_id(raw_correlation)
    assert Enum.all?(exports, &(&1.correlation_id == expected_hash))
    refute Enum.any?(exports, &(inspect(&1) =~ raw_correlation))

    for exported <- exports, step <- exported.steps do
      assert Map.keys(step)
             |> Enum.all?(
               &(&1 in ["outcome", "error_code", "duration_ms", "attributes", "roles", "step"])
             )
    end

    for event <- events do
      summaries = Jason.encode!([event.before_summary, event.after_summary, event.diff_summary])
      refute summaries =~ "<EntityDescriptor"
      refute summaries =~ "BEGIN CERTIFICATE"
      refute summaries =~ "PRIVATE KEY"
      refute summaries =~ "SAMLResponse"
      refute summaries =~ "RelayState"
    end
  end
end
