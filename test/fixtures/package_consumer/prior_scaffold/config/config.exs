# --- Relyra START ---
config :relyra,
  connection_resolver: PackageConsumer.Relyra.Connections,
  request_store: Relyra.RequestStore.ETS,
  replay_store: Relyra.ReplayStore.ETS,
  user_mapper: PackageConsumer.Relyra.UserMapper

# --- Relyra END ---
