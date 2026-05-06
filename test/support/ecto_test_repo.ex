defmodule Relyra.TestSupport.EctoTestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :relyra,
    adapter: Ecto.Adapters.Postgres
end
