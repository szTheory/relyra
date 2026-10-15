case Relyra.TestGsdTools.resolve() do
  {:ok, _path} ->
    :ok

  {:error, {:gsd_tools_unavailable, message}} ->
    IO.puts(
      "Relyra.TestGsdTools: #{message}; tests tagged :requires_gsd_tools are reported as skipped"
    )
end

ExUnit.start(exclude: [:pending, :integration, :external_idp, :phase78_clean_state_receipt])

Relyra.TestSupport.MigrationCase.bootstrap!()

# Async tests sign redirect queries with FakeIdP.keypair/0; concurrent first access
# used to race on :persistent_term.put/2 and yield :invalid_signature flakes.
_ = Relyra.TestSupport.FakeIdP.keypair()
