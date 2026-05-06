defmodule Relyra.TestSupport.MigrationCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Migrator
  alias Relyra.TestSupport.EctoTestRepo

  @migrations_path Path.expand("../../priv/repo/migrations", __DIR__)
  @truncate_tables [
    "relyra_metadata_revisions",
    "relyra_metadata_sources",
    "relyra_connection_certificates",
    "relyra_connections"
  ]

  using do
    quote do
      alias Relyra.TestSupport.EctoTestRepo, as: Repo
      import unquote(__MODULE__)
    end
  end

  setup tags do
    owner =
      Sandbox.start_owner!(
        EctoTestRepo,
        shared: Map.get(tags, :sandbox_shared, not tags[:async])
      )

    reset_tables!()

    on_exit(fn ->
      Sandbox.stop_owner(owner)
    end)

    :ok
  end

  def bootstrap! do
    Application.ensure_all_started(:ecto_sql)
    reset_storage!()
    start_repo!()
    migrate!()
    Sandbox.mode(EctoTestRepo, :manual)
  end

  def migrations_path, do: @migrations_path

  def reset_tables! do
    sql =
      "TRUNCATE TABLE " <>
        Enum.join(@truncate_tables, ", ") <>
        " RESTART IDENTITY CASCADE"

    case EctoTestRepo.query(sql, []) do
      {:ok, _result} -> :ok
      {:error, _reason} -> :ok
    end
  end

  defp reset_storage! do
    case EctoTestRepo.__adapter__().storage_down(EctoTestRepo.config()) do
      :ok -> :ok
      {:error, _reason} -> :ok
    end

    case EctoTestRepo.__adapter__().storage_up(EctoTestRepo.config()) do
      :ok ->
        :ok

      {:error, :already_up} ->
        :ok

      {:error, message} when is_binary(message) ->
        if String.contains?(message, "already exists") do
          :ok
        else
          raise "failed to create Phase 07 test database: #{inspect(message)}"
        end

      {:error, reason} ->
        raise "failed to create Phase 07 test database: #{inspect(reason)}"
    end
  end

  defp start_repo! do
    case EctoTestRepo.start_link(pool_size: 4) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> raise "failed to start Phase 07 test repo: #{inspect(reason)}"
    end
  end

  defp migrate! do
    Migrator.with_repo(EctoTestRepo, fn repo ->
      Migrator.run(repo, @migrations_path, :up, all: true)
    end)
  end
end
