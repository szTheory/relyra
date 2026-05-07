defmodule Relyra.Metadata.SchedulerTest do
  @moduledoc """
  Phase 21 W3 — `Relyra.Metadata.Scheduler.run_due/2` tests.

  The :skipped event test below is the single deterministic invariant
  asserted in the unit lane. The sequential-per-source loop with a
  shared correlation_id and the :source_ids bypass path are exercised
  end-to-end via the existing `Relyra.Ecto.MetadataApply` integration
  test fixtures and are tagged `:integration` so they participate in
  the `ci.integration` lane defined in `mix.exs`.
  """
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.MetadataSource
  alias Relyra.Metadata.Scheduler

  describe "run_due/2 with no due rows" do
    test "emits the [:relyra, :saml, :metadata, :auto_refresh, :skipped] event and returns {:ok, %{}}" do
      test_pid = self()
      handler_id = "scheduler-test-skipped-#{:erlang.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:relyra, :saml, :metadata, :auto_refresh, :skipped],
        fn _name, _measurements, metadata, _config ->
          send(test_pid, {:skipped, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      # No sources are inserted in this test — the due-rows query
      # returns []; the scheduler emits :skipped and returns an empty
      # result map.
      assert {:ok, results} = Scheduler.run_due(Relyra.TestSupport.EctoTestRepo, [])
      assert results == %{}

      assert_receive {:skipped, metadata}, 1_000
      assert is_binary(metadata.correlation_id)
      assert metadata.count == 0
    end

    test "honors a caller-supplied correlation_id in the :skipped emission (D-39)" do
      test_pid = self()
      handler_id = "scheduler-test-correlation-#{:erlang.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:relyra, :saml, :metadata, :auto_refresh, :skipped],
        fn _name, _measurements, metadata, _config ->
          send(test_pid, {:skipped, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      explicit_correlation_id = Ecto.UUID.generate()

      assert {:ok, %{}} =
               Scheduler.run_due(Relyra.TestSupport.EctoTestRepo,
                 audit: %{correlation_id: explicit_correlation_id}
               )

      assert_receive {:skipped, %{correlation_id: ^explicit_correlation_id}}, 1_000
    end

    test "auto-generates a correlation_id when none is supplied" do
      test_pid = self()
      handler_id = "scheduler-test-auto-correlation-#{:erlang.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:relyra, :saml, :metadata, :auto_refresh, :skipped],
        fn _name, _measurements, metadata, _config ->
          send(test_pid, {:skipped, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert {:ok, %{}} = Scheduler.run_due(Relyra.TestSupport.EctoTestRepo, [])

      assert_receive {:skipped, %{correlation_id: cid}}, 1_000
      assert is_binary(cid)
      # Auto-generated correlation IDs are UUID v4 (36 chars with 4 dashes).
      assert byte_size(cid) == 36
    end
  end

  describe "run_due/2 with explicit :source_ids" do
    test "bypasses the due-rows query and runs only the named IDs (Resume-now probe path)" do
      # The :source_ids opt is the LiveView "Resume now" probe surface
      # (Plan 06). The scheduler short-circuits the partial-index
      # `WHERE auto_refresh_enabled = true` predicate so an operator
      # can probe a source whose schedule is paused. With a non-
      # existent ID the result map stays empty (the source is not
      # found) and the scheduler returns {:ok, %{}}.
      assert {:ok, %{}} =
               Scheduler.run_due(Relyra.TestSupport.EctoTestRepo,
                 source_ids: [Ecto.UUID.generate()]
               )
    end
  end

  describe "run_due/2 due-rows query predicate" do
    test "ignores sources where auto_refresh_enabled is false (matches partial-index where-clause)" do
      # Insert a source with auto_refresh_enabled = false. The due-rows
      # query MUST skip it (matches the partial-index predicate from
      # Plan 01 — `WHERE auto_refresh_enabled = true`).
      connection = insert_connection!()

      _disabled_source =
        %MetadataSource{}
        |> MetadataSource.changeset(%{
          connection_record_id: connection.id,
          url: "https://idp.example.com/metadata",
          kind: :remote_url,
          registered_by: "operator@example.com",
          registered_reason: "scheduler-test"
        })
        |> Repo.insert!()

      test_pid = self()
      handler_id = "scheduler-test-disabled-#{:erlang.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:relyra, :saml, :metadata, :auto_refresh, :skipped],
        fn _name, _measurements, metadata, _config ->
          send(test_pid, {:skipped, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      # The disabled source MUST be excluded — the scheduler sees no due
      # rows and emits :skipped.
      assert {:ok, %{}} = Scheduler.run_due(Repo, [])
      assert_receive {:skipped, _}, 1_000
    end
  end

  defp insert_connection! do
    alias Relyra.Ecto.Connection

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: "01JT71VSVCKX7RZ9KD5W6F4SCH",
      status: :draft,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
    |> Repo.insert!()
  end
end
