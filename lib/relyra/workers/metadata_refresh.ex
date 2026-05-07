# Two compile lanes per D-02 (engineering-DNA §3): when Oban is in the
# adopter's deps tree, this module IS an `Oban.Worker` with the LOCKED
# `unique:` constraint per D-03 and `max_attempts: 1` per D-25; when
# Oban is absent, the module still exists and `perform/1` returns the
# typed optional-dep error so adopter docs/examples that reference the
# worker still type-check.
#
# The module-level `Code.ensure_loaded?(Oban.Worker)` guard MUST sit
# OUTSIDE the `defmodule`, not inside its body. The Elixir `if/2` macro
# eagerly compiles both branches when the condition is a function call;
# `use Oban.Worker` therefore cannot live inside an in-body `if`. The
# canonical pattern in this codebase (`lib/relyra/live_admin.ex`,
# `lib/relyra/live_admin/connection_metadata_live.ex`) is to gate the
# whole `defmodule`.

if Code.ensure_loaded?(Oban.Worker) do
  defmodule Relyra.Workers.MetadataRefresh do
    @moduledoc """
    Optional Oban worker that drives `Relyra.Metadata.Scheduler.run_due/2`
    per D-02. Compiles whether or not Oban is in the adopter's deps tree
    (Pitfall 5 — `mix compile --no-optional-deps --warnings-as-errors`
    lane).

    Adopters add ONE Cron line to their host config:

        config :my_app, Oban,
          repo: MyApp.Repo,
          queues: [relyra_metadata: 1],
          plugins: [
            {Oban.Plugins.Cron,
             crontab: [
               {"*/15 * * * *", Relyra.Workers.MetadataRefresh,
                args: %{"repo" => "MyApp.Repo"}}
             ]}
          ]

    The 15-minute Cron interval is fine even though Phase 21 cadence
    presets are 1h+ — `Scheduler.run_due/2` only acts on rows whose
    `next_refresh_at` is in the past, so an empty tick just emits the
    `:skipped` event (D-07) and returns.

    `unique:` constraint per D-03: at most one in-flight job per
    source_id across the entire Oban cluster. Multi-node dedup is
    delegated to `Oban.Peers.Database` leader election.
    """

    # Pitfall 5: silences "module Oban is not available" warnings under
    # `mix compile --no-optional-deps --warnings-as-errors` for any
    # qualified Oban reference compiled into this branch.
    @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

    use Oban.Worker,
      queue: :relyra_metadata,
      # Phase 21 owns its OWN backoff via the auto-suspend state machine
      # (D-25). Mixing Oban's per-job retry with our own per-source
      # backoff is the double-counting footgun (RESEARCH "Don't
      # Hand-Roll" row 3). One attempt per scheduler tick.
      max_attempts: 1,
      unique: [
        period: :infinity,
        states: [:available, :scheduled, :executing],
        keys: [:source_id]
      ]

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      repo = repo_for(args)
      opts = opts_for(args)

      case Relyra.Metadata.Scheduler.run_due(repo, opts) do
        {:ok, _results} ->
          :ok

        # Defensive fallback for the Ecto-absent `Scheduler` stub which
        # returns `{:error, %Relyra.Error{}}`. The Ecto-present body
        # only returns `{:ok, _}` — Elixir's set-theoretic typer cannot
        # see this branch in the present-Ecto compile lane, so we keep
        # it as a wildcard rather than an explicit `{:error, _}` match
        # that would be flagged unreachable.
        other ->
          other
      end
    end

    defp repo_for(args) do
      args
      |> Map.fetch!("repo")
      |> String.to_existing_atom()
    end

    defp opts_for(args) do
      args
      |> Map.get("opts", [])
      |> normalize_opts()
    end

    defp normalize_opts(opts) when is_list(opts), do: opts
    defp normalize_opts(_), do: []
  end
else
  defmodule Relyra.Workers.MetadataRefresh do
    @moduledoc """
    Oban-absent compile lane (D-02 / Pitfall 5). The module name still
    exists so adopter docs/examples that reference the worker still
    type-check; calling `perform/1` returns the typed optional-dep
    error from `Relyra.OptionalDeps.Oban`.
    """

    alias Relyra.OptionalDeps.Oban, as: ObanGateway

    @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

    @doc false
    def perform(_job), do: ObanGateway.ensure_available!(:perform)
  end
end
