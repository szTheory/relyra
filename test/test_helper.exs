ExUnit.start(exclude: [:pending, :integration])

Relyra.TestSupport.MigrationCase.bootstrap!()

# Async tests sign redirect queries with FakeIdP.keypair/0; concurrent first access
# used to race on :persistent_term.put/2 and yield :invalid_signature flakes.
_ = Relyra.TestSupport.FakeIdP.keypair()
