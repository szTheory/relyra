defmodule Relyra.TestSupport do
  @moduledoc """
  Test helpers for adapter and controller tests.

  The helpers are designed to compose with Phoenix.ConnTest and the
  library's own resolver / user-mapper seams. They intentionally keep
  the call surface small so adopters can write a full SSO round-trip
  test without learning internal plumbing.
  """

  @prod_build Mix.env() == :prod

  defmacro __using__(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    resolver = Keyword.get(opts, :connection_resolver, Relyra.ConnectionResolver.Default)

    quote bind_quoted: [endpoint: endpoint, resolver: resolver] do
      import Phoenix.ConnTest
      import Plug.Conn
      import Relyra.TestSupport.Assertions

      @endpoint endpoint
      @relyra_connection_resolver resolver

      def setup_saml_connection(conn, opts \\ []) do
        Relyra.TestSupport.setup_saml_connection(
          conn,
          Keyword.put_new(opts, :endpoint, @endpoint)
        )
      end

      def post_saml_response(conn, response_xml, opts \\ []) do
        Relyra.TestSupport.post_saml_response(
          conn,
          response_xml,
          Keyword.put_new(opts, :endpoint, @endpoint)
        )
      end

      def fake_idp_metadata, do: Relyra.TestSupport.fake_idp_metadata()
      def build_saml_response(opts \\ []), do: Relyra.TestSupport.build_saml_response(opts)

      def sign_saml_response(builder, opts \\ []),
        do: Relyra.TestSupport.sign_saml_response(builder, opts)

      def saml_login(conn), do: Relyra.TestSupport.saml_login(conn)
    end
  end

  @spec setup_saml_connection(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def setup_saml_connection(conn, opts \\ []) do
    ensure_not_prod!()
    relyra_opts = Keyword.merge([connection_resolver: Relyra.ConnectionResolver.Default], opts)
    connection_id = Keyword.get(relyra_opts, :connection_id)

    conn
    |> Plug.Conn.assign(:relyra_opts, relyra_opts)
    |> Plug.Conn.assign(:relyra_connection_id, connection_id)
    |> Plug.Conn.put_private(:relyra_resolver, Keyword.get(relyra_opts, :connection_resolver))
  end

  @spec post_saml_response(Plug.Conn.t(), String.t(), keyword()) :: Plug.Conn.t()
  def post_saml_response(conn, response_xml, opts \\ []) when is_binary(response_xml) do
    ensure_not_prod!()
    endpoint = Keyword.fetch!(opts, :endpoint)

    path =
      Keyword.get(opts, :path) ||
        case conn.assigns[:relyra_connection_id] do
          nil ->
            raise ArgumentError,
                  "post_saml_response/3 requires :path or a prior setup_saml_connection/2 with :connection_id"

          connection_id ->
            "/#{connection_id}/acs"
        end

    params =
      %{
        Keyword.get(opts, :saml_response_key, "SAMLResponse") =>
          Base.encode64(response_xml, padding: false),
        Keyword.get(opts, :relay_state_key, "RelayState") => Keyword.get(opts, :relay_state, "")
      }
      |> Enum.reject(fn {_k, v} -> v == "" end)
      |> Map.new()

    Phoenix.ConnTest.dispatch(conn, endpoint, :post, path, params)
  end

  defdelegate fake_idp_metadata(), to: Relyra.TestSupport.FakeIdP, as: :metadata
  defdelegate build_saml_response(opts \\ []), to: Relyra.TestSupport.FakeIdP, as: :build_response
  defdelegate sign_saml_response(builder, opts \\ []), to: Relyra.TestSupport.FakeIdP, as: :sign

  @spec saml_login(Plug.Conn.t()) :: {:ok, term()} | {:error, atom()}
  def saml_login(%Plug.Conn{assigns: %{current_user: current_user}})
      when not is_nil(current_user) do
    ensure_not_prod!()
    {:ok, current_user}
  end

  def saml_login(_conn), do: {:error, :no_saml_login}

  defp ensure_not_prod! do
    if @prod_build do
      raise "Relyra.TestSupport is test-only"
    end
  end
end

defmodule Relyra.TestSupport.Assertions do
  @moduledoc false

  defmacro assert_saml_login(conn, pattern) do
    ensure_supported_pattern!(pattern, __CALLER__, :assert_saml_login)

    quote bind_quoted: [conn: conn, pattern: pattern] do
      assert %Plug.Conn{assigns: %{current_user: current_user}} = conn
      assert match?(pattern, current_user)
    end
  end

  defmacro assert_saml_error(conn, pattern) do
    ensure_supported_pattern!(pattern, __CALLER__, :assert_saml_error)

    quote bind_quoted: [conn: conn, pattern: pattern] do
      assert %Plug.Conn{status: 400} = conn
      assert conn.resp_body =~ "SAML Authentication Error"
      assert conn.resp_body =~ inspect(pattern)
    end
  end

  defp ensure_supported_pattern!({:_, _, _}, caller, macro_name) do
    raise CompileError,
      file: caller.file,
      line: caller.line,
      description: "#{macro_name}/2 requires a concrete pattern, not `_`"
  end

  defp ensure_supported_pattern!({:%{}, _, []}, caller, macro_name) do
    raise CompileError,
      file: caller.file,
      line: caller.line,
      description: "#{macro_name}/2 requires a non-empty pattern"
  end

  defp ensure_supported_pattern!(_pattern, _caller, _macro_name), do: :ok
end
