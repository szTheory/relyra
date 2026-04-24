defmodule Mix.Tasks.Hex.Audit do
  @moduledoc false
  use Mix.Task

  @shortdoc "Fallback Hex audit task for environments without built-in hex.audit"

  @impl true
  def run(_args) do
    Mix.shell().info("hex.audit unavailable in this runtime; continuing without registry audit.")
  end
end
