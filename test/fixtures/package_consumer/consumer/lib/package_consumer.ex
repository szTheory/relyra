defmodule PackageConsumer.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PackageConsumer.Repo,
      PackageConsumer.ProofSession,
      PackageConsumerWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PackageConsumer.Supervisor)
  end
end

defmodule PackageConsumer.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :package_consumer,
    adapter: Ecto.Adapters.Postgres
end

defmodule PackageConsumer.RelyraOptions do
  @moduledoc false
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    Plug.Conn.assign(conn, :relyra_opts, Application.get_env(:relyra, :consumer_opts, []))
  end
end

defmodule PackageConsumerWeb.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :package_consumer

  plug(Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"],
    query_string_length: 1_000_000
  )

  plug(PackageConsumer.RelyraOptions)
  plug(PackageConsumerWeb.Router)
end

defmodule PackageConsumer.ProofSession do
  @moduledoc false

  def child_spec(_opts) do
    %{id: __MODULE__, start: {Agent, :start_link, [fn -> nil end, [name: __MODULE__]]}}
  end

  def get, do: Agent.get(__MODULE__, & &1)

  def record(receipt), do: Agent.update(__MODULE__, fn _previous -> receipt end)
end

defmodule PackageConsumer.ProofResolver do
  @moduledoc false
  @behaviour Relyra.ConnectionResolver

  @impl true
  def resolve_connection(%{connection_id: connection_id}, opts) do
    case Keyword.get(opts, :resolved_connection) do
      %{connection_id: ^connection_id} = connection ->
        {:ok, connection}

      %{id: ^connection_id} = connection ->
        {:ok, connection}

      _ ->
        {:error,
         Relyra.Error.new(:connection_unavailable, "Unknown consumer connection", %{
           reason: :not_found,
           operation: :resolve_connection
         })}
    end
  end
end

defmodule PackageConsumer.ProofMapper do
  @moduledoc false
  @behaviour Relyra.UserMapper

  @impl true
  def map_attributes(login_result, _connection, _opts) do
    user_id = login_result.principal.name_id
    {:ok, %{id: user_id, email: user_id}}
  end
end

defmodule PackageConsumer.ProofSessionAdapter do
  @moduledoc false
  @behaviour Relyra.SessionAdapter

  @impl true
  def establish_session(user, login_result, _opts) do
    PackageConsumer.ProofSession.record(%{
      user_id: user.id,
      connection_id: login_result.connection.connection_id
    })

    {:ok, %{user_id: user.id}}
  end

  @impl true
  def revoke_session(_subject, _session_index, _context, _opts), do: {:ok, :revoked}

  @impl true
  def index_session(_session_index, _issuer, _context, _opts), do: {:ok, :indexed}

  @impl true
  def terminate_by_session_index(_session_index, _issuer, _context, _opts),
    do: {:ok, :terminated}
end
