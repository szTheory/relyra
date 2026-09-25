alias PackageConsumer.ProofSession
alias PackageConsumer.Repo
alias Relyra.Testing

contract_error = fn contract, expected, actual, next_action ->
  raise "package consumer contract failed (#{contract}): expected #{expected}; actual #{actual}; next: #{next_action}"
end

inside? = fn path, root ->
  expanded_path = Path.expand(path)
  expanded_root = Path.expand(root)
  relative = Path.relative_to(expanded_path, expanded_root)

  relative not in [".", ".."] and Path.type(relative) == :relative and
    not String.starts_with?(relative, "../")
end

within? = fn path, root ->
  Path.expand(path) == Path.expand(root) or inside?.(path, root)
end

run_root = System.fetch_env!("PACKAGE_CONSUMER_RUN_ROOT")
artifact_root = System.fetch_env!("PACKAGE_CONSUMER_ARTIFACT_ROOT")
checkout_root = System.fetch_env!("PACKAGE_CONSUMER_CHECKOUT")
build_root = System.fetch_env!("MIX_BUILD_ROOT")
source_path = Mix.Project.deps_paths()[:relyra] |> Path.expand()
compiled_path = :code.lib_dir(:relyra) |> to_string() |> Path.expand()
testing_beam = :code.which(Relyra.Testing) |> to_string() |> Path.expand()

unless within?.(source_path, artifact_root) and not within?.(source_path, checkout_root) do
  contract_error.(
    "dependency provenance",
    "Relyra source under #{artifact_root} and outside #{checkout_root}",
    source_path,
    "check the consumer path dependency and rebuild the artifact with scripts/check_clean_room_consumer.sh --profile full"
  )
end

unless inside?.(compiled_path, build_root) and inside?.(testing_beam, build_root) do
  contract_error.(
    "compiled provenance",
    "Relyra BEAM files under #{build_root}",
    "application=#{compiled_path}; testing=#{testing_beam}",
    "check MIX_BUILD_ROOT and rerun scripts/check_clean_room_consumer.sh --profile full"
  )
end

unless within?.(source_path, run_root) do
  contract_error.(
    "run-root isolation",
    "Relyra source below #{run_root}",
    source_path,
    "check artifact creation and run scripts/check_clean_room_consumer.sh --profile full again"
  )
end

testing_source = Path.join(source_path, "lib/relyra/testing.ex")

unless File.regular?(testing_source) do
  contract_error.(
    "required package file",
    "#{testing_source} to exist in the unpacked artifact",
    "file missing",
    "add the required public testing module to the package file list and rebuild the Hex artifact"
  )
end

migrations_source = Path.join(source_path, "priv/repo/migrations")

unless File.dir?(migrations_source) do
  contract_error.(
    "package migration directory",
    "#{migrations_source} to exist in the unpacked artifact",
    "directory missing",
    "include priv/repo/migrations in the package artifact and rerun the full profile"
  )
end

checkout_paths =
  (:code.get_path() ++ Enum.map(:code.all_loaded(), fn {_module, path} -> path end))
  |> Enum.reject(&(&1 in [:preloaded, :cover_compiled]))
  |> Enum.map(fn path -> path |> to_string() |> Path.expand() end)

if leaked_path = Enum.find(checkout_paths, &within?.(&1, checkout_root)) do
  contract_error.(
    "checkout source isolation",
    "no loaded code or compiler path under #{checkout_root}",
    leaked_path,
    "remove inherited Mix paths and rerun the consumer with isolated directories"
  )
end

if Code.ensure_loaded?(Relyra.TestSupport) do
  contract_error.(
    "private support exclusion",
    "Relyra.TestSupport to be unavailable",
    "module loaded",
    "remove checkout test-support paths and rebuild the consumer only from the unpacked artifact"
  )
end

unless match?({:ok, %{rows: [[1]]}}, Repo.query("SELECT 1")) do
  contract_error.(
    "consumer database",
    "PackageConsumer.Repo to return one row containing 1",
    "query did not return the expected result",
    "check the isolated PostgreSQL connection settings and rerun the full profile"
  )
end

fixture = Testing.signed_success(name_id: "alice@example.com")

request_intent =
  fixture.request_intent
  |> Map.put(:return_to, "/welcome")
  |> Map.put(:expires_at, DateTime.utc_now() |> DateTime.add(3600, :second))

opts =
  Testing.consume_opts(fixture,
    request_intent: request_intent,
    connection_resolver: PackageConsumer.ProofResolver,
    user_mapper: PackageConsumer.ProofMapper,
    session_adapter: PackageConsumer.ProofSessionAdapter
  )

Application.put_env(:relyra, :consumer_opts, opts)

if ProofSession.get() != nil do
  raise "package consumer contract: receipt Agent must be empty before the signed ACS POST"
end

conn =
  Phoenix.ConnTest.build_conn()
  |> Relyra.Testing.Phoenix.post_response(
    PackageConsumerWeb.Endpoint,
    "/conn-123/acs",
    fixture
  )

receipt = ProofSession.get()

unless receipt == %{user_id: "alice@example.com", connection_id: "conn-123"} do
  contract_error.(
    "verified host receipt",
    "%{user_id: \"alice@example.com\", connection_id: \"conn-123\"}",
    inspect(receipt),
    "check the configured resolver, mapper and session adapter, then rerun the signed ACS smoke"
  )
end

location = Plug.Conn.get_resp_header(conn, "location")

unless conn.status == 302 and location == ["/welcome"] do
  contract_error.(
    "ACS route response",
    "HTTP 302 with Location /welcome",
    "HTTP #{conn.status} with Location #{inspect(location)}",
    "check the installer-injected ACS route and request intent, then rerun the full profile"
  )
end

IO.puts("PostgreSQL: PASS — consumer Repo queried its owned database")
IO.puts("provenance: PASS — artifact source and isolated BEAM paths")
IO.puts("private support: PASS — checkout support is unavailable")
IO.puts("signed ACS: PASS — verified host receipt and /welcome redirect")
