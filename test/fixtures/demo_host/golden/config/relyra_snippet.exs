# --- Relyra START ---
config :relyra,
  connection_resolver: Relyra.ConnectionResolver.Default,
  request_store: Relyra.RequestStore.ETS,
  replay_store: Relyra.ReplayStore.ETS

# --- Relyra END ---
