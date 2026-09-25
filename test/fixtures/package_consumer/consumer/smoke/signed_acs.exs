alias PackageConsumer.ProofSession
alias PackageConsumer.Repo
alias Relyra.Testing

contract_error = fn message ->
  raise "package consumer contract: #{message}"
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
  contract_error.("Relyra source must resolve under the unpacked artifact, outside the checkout")
end

unless inside?.(compiled_path, build_root) and inside?.(testing_beam, build_root) do
  contract_error.("Relyra BEAM files must resolve under the isolated build root")
end

unless within?.(source_path, run_root) and
         File.regular?(Path.join(source_path, "lib/relyra/testing.ex")) and
         File.dir?(Path.join(source_path, "priv/repo/migrations")) do
  contract_error.("unpacked artifact is missing shipped testing helpers or migration files")
end

checkout_paths =
  (:code.get_path() ++ Enum.map(:code.all_loaded(), fn {_module, path} -> path end))
  |> Enum.reject(&(&1 in [:preloaded, :cover_compiled]))
  |> Enum.map(fn path -> path |> to_string() |> Path.expand() end)

if Enum.any?(checkout_paths, &within?.(&1, checkout_root)) do
  contract_error.("loaded code or compiler paths must not point into the checkout")
end

if Code.ensure_loaded?(Relyra.TestSupport) do
  contract_error.("private test support must not be loadable by the package consumer")
end

unless match?({:ok, %{rows: [[1]]}}, Repo.query("SELECT 1")) do
  contract_error.("consumer-owned Repo must query its owned PostgreSQL database")
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
  raise "package consumer contract: verified ACS did not produce the expected host receipt"
end

unless conn.status == 302 and Plug.Conn.get_resp_header(conn, "location") == ["/welcome"] do
  raise "package consumer contract: verified ACS did not redirect to /welcome"
end

IO.puts("PostgreSQL: PASS — consumer Repo queried its owned database")
IO.puts("provenance: PASS — artifact source and isolated BEAM paths")
IO.puts("private support: PASS — checkout support is unavailable")
IO.puts("signed ACS: PASS — verified host receipt and /welcome redirect")
