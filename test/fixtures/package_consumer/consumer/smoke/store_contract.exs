alias PackageConsumer.Repo
alias Relyra.Error

contract_error = fn message ->
  raise "package consumer store contract: #{message}"
end

run_pair = fn operation ->
  parent = self()

  tasks =
    for _ <- 1..2 do
      Task.async(fn ->
        send(parent, {:ready, self()})

        receive do
          :release -> operation.()
        after
          5_000 -> contract_error.("concurrency barrier timed out")
        end
      end)
    end

  Enum.each(tasks, fn task ->
    receive do
      {:ready, pid} when pid == task.pid -> :ok
    after
      5_000 -> contract_error.("concurrent store operation did not reach the launch barrier")
    end
  end)

  Enum.each(tasks, &send(&1.pid, :release))
  Enum.map(tasks, &Task.await(&1, 5_000))
end

assert_race! = fn label, results, expected_error ->
  successes = Enum.count(results, &(&1 == :ok))
  errors = for {:error, %Error{type: type}} <- results, do: type
  unexpected = Enum.count(results, &(&1 != :ok and not match?({:error, %Error{}}, &1)))

  unless length(results) == 2 and successes == 1 and errors == [expected_error] and
           unexpected == 0 do
    contract_error.(
      "#{label} race expected one :ok and one #{inspect(expected_error)}; observed #{successes} successes, #{inspect(errors)} errors, #{unexpected} unexpected outcomes"
    )
  end
end

artifact_root = System.fetch_env!("PACKAGE_CONSUMER_ARTIFACT_ROOT")
checkout_root = System.fetch_env!("PACKAGE_CONSUMER_CHECKOUT")
consumer_root = System.fetch_env!("PACKAGE_CONSUMER_CONSUMER")

inside? = fn path, root ->
  expanded_path = Path.expand(path)
  expanded_root = Path.expand(root)
  relative = Path.relative_to(expanded_path, expanded_root)

  relative not in [".", ".."] and Path.type(relative) == :relative and
    not String.starts_with?(relative, "../")
end

relyra_path = Mix.Project.deps_paths()[:relyra] |> Path.expand()
library_migrations = Path.join(relyra_path, "priv/repo/migrations")
compiled_migrations = Application.app_dir(:relyra, "priv/repo/migrations") |> Path.expand()
host_migrations = Path.join(consumer_root, "priv/repo/migrations") |> Path.expand()

unless (relyra_path == Path.expand(artifact_root) or inside?.(relyra_path, artifact_root)) and
         not (relyra_path == Path.expand(checkout_root) or inside?.(relyra_path, checkout_root)) do
  contract_error.(
    "Relyra migrations must be selected from the unpacked artifact, not the checkout"
  )
end

library_files =
  Path.wildcard(Path.join(library_migrations, "*.exs"))
  |> Enum.map(&Path.basename/1)
  |> Enum.sort()

compiled_files =
  Path.wildcard(Path.join(compiled_migrations, "*.exs"))
  |> Enum.map(&Path.basename/1)
  |> Enum.sort()

unless library_files != [] and library_files == compiled_files do
  contract_error.("artifact and compiled Relyra migration file sets must match")
end

host_migration_files = Path.wildcard(Path.join(host_migrations, "*.exs"))

unless length(host_migration_files) == 1 and not inside?.(host_migrations, checkout_root) do
  contract_error.("host migration must be owned by the clean-room consumer")
end

existing_tables =
  Repo.query!("""
  SELECT tablename
  FROM pg_catalog.pg_tables
  WHERE schemaname = 'public'
    AND tablename NOT LIKE 'pg_%'
    AND tablename <> 'schema_migrations'
  ORDER BY tablename
  """).rows

if existing_tables != [] do
  contract_error.("fresh PostgreSQL database must have no application tables before migrations")
end

run_migrations! = fn path ->
  case Ecto.Migrator.with_repo(Repo, fn repo ->
         Ecto.Migrator.run(repo, path, :up, all: true)
       end) do
    versions when is_list(versions) -> versions
    {:ok, versions} when is_list(versions) -> versions
    {:ok, versions, []} when is_list(versions) -> versions
    {:error, reason} -> contract_error.("migration failed for #{path}: #{inspect(reason)}")
    other -> contract_error.("unexpected migration result for #{path}: #{inspect(other)}")
  end
end

library_versions = run_migrations!.(library_migrations)

unless length(library_versions) == length(library_files) do
  contract_error.("Relyra migration run did not apply every migration from #{library_migrations}")
end

relyra_connection_table =
  Repo.query!("""
  SELECT table_name
  FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = 'relyra_connections'
  """).rows

unless relyra_connection_table == [["relyra_connections"]] do
  contract_error.(
    "Relyra-owned connection table was not created from the artifact migrations: #{inspect(relyra_connection_table)}"
  )
end

host_versions = run_migrations!.(host_migrations)

unless host_versions == [20_260_924_000_100] do
  contract_error.(
    "consumer-owned store migration did not apply exactly once from #{host_migrations}"
  )
end

host_tables =
  Repo.query!("""
  SELECT tablename
  FROM pg_catalog.pg_tables
  WHERE schemaname = 'public'
    AND tablename IN ('package_consumer_request_intents', 'package_consumer_replay_keys')
  ORDER BY tablename
  """).rows

unless host_tables == [["package_consumer_replay_keys"], ["package_consumer_request_intents"]] do
  contract_error.("consumer migration must create both host-owned store tables")
end

Application.put_env(:relyra, :request_store, PackageConsumer.RequestStore)
Application.put_env(:relyra, :replay_store, PackageConsumer.ReplayStore)

request_store_opts = [request_store: PackageConsumer.RequestStore]
replay_store_opts = [replay_store: PackageConsumer.ReplayStore]
expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)

request_intent = %{
  request_id: "consumer-request-1",
  connection_id: "conn-123",
  relay_state: "consumer-relay-1",
  in_response_to: "consumer-request-1",
  destination: "https://sp.example.com/saml/acs",
  recipient: "https://sp.example.com/saml/acs",
  issuer: "https://idp.example.com/metadata",
  sp_entity_id: "https://sp.example.com/metadata",
  acs_url: "https://sp.example.com/saml/acs",
  return_to: "/welcome",
  expires_at: expires_at
}

if Relyra.RequestStore.put_intent("consumer-relay-1", request_intent, request_store_opts) != :ok do
  contract_error.("configured request wrapper must accept the first request intent")
end

case Relyra.RequestStore.fetch_intent("consumer-relay-1", request_store_opts) do
  {:ok, fetched} when fetched.request_id == "consumer-request-1" -> :ok
  other -> contract_error.("request wrapper read returned #{inspect(other)}")
end

if Relyra.RequestStore.consume_intent(
     "consumer-relay-1",
     "consumer-request-1",
     request_store_opts
   ) != :ok do
  contract_error.("configured request wrapper must consume the existing request intent")
end

case Relyra.RequestStore.consume_intent(
       "consumer-relay-1",
       "consumer-request-1",
       request_store_opts
     ) do
  {:error, %Error{type: :request_intent_consumed}} ->
    :ok

  other ->
    contract_error.(
      "duplicate request consume must reject with :request_intent_consumed, got #{inspect(other)}"
    )
end

replay_metadata = %{
  connection_id: "conn-123",
  assertion_id: "consumer-assertion-1",
  issuer: "https://idp.example.com/metadata"
}

if Relyra.ReplayStore.consume_replay_key("consumer-replay-1", replay_metadata, replay_store_opts) !=
     :ok do
  contract_error.("configured replay wrapper must accept the first replay key")
end

case Relyra.ReplayStore.consume_replay_key(
       "consumer-replay-1",
       replay_metadata,
       replay_store_opts
     ) do
  {:error, %Error{type: :replayed_assertion}} ->
    :ok

  other ->
    contract_error.(
      "duplicate replay key must reject with :replayed_assertion, got #{inspect(other)}"
    )
end

race_intent = %{
  request_intent
  | request_id: "consumer-request-race",
    relay_state: "consumer-relay-race",
    in_response_to: "consumer-request-race"
}

request_race =
  run_pair.(fn ->
    Relyra.RequestStore.put_intent("consumer-relay-race", race_intent, request_store_opts)
  end)

assert_race!.(:request_intent, request_race, :request_intent_consumed)

replay_race =
  run_pair.(fn ->
    Relyra.ReplayStore.consume_replay_key(
      "consumer-replay-race",
      %{replay_metadata | assertion_id: "consumer-assertion-race"},
      replay_store_opts
    )
  end)

assert_race!.(:replay_key, replay_race, :replayed_assertion)

row_counts = fn ->
  request_count =
    Repo.query!("SELECT count(*) FROM package_consumer_request_intents").rows

  replay_count = Repo.query!("SELECT count(*) FROM package_consumer_replay_keys").rows
  {request_count, replay_count}
end

counts_before_reruns = row_counts.()

library_reruns = run_migrations!.(library_migrations)
host_reruns = run_migrations!.(host_migrations)

unless library_reruns == [] and host_reruns == [] do
  contract_error.(
    "rerunning both migration sources must apply zero versions; got #{length(library_reruns)} and #{length(host_reruns)}"
  )
end

unless counts_before_reruns == {[[2]], [[2]]} and row_counts.() == counts_before_reruns do
  contract_error.(
    "concurrent writes must leave one row per operation and migration reruns must preserve both tables"
  )
end

IO.puts(
  "library migration: PASS — #{length(library_versions)} versions from the unpacked artifact"
)

IO.puts("host migration: PASS — consumer-owned request and replay tables")
IO.puts("persistent adapters: PASS — request read/consume and typed request/replay rejections")
IO.puts("store concurrency: PASS — unique indexes allow one request and replay write each")
IO.puts("migration reruns: PASS — both sources applied zero versions without changing rows")
