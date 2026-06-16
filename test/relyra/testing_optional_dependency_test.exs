defmodule Relyra.TestingOptionalDependencyTest do
  use ExUnit.Case, async: true

  @core_files [
    "lib/relyra/testing.ex",
    "lib/relyra/testing/fixture.ex",
    "lib/relyra/testing/signer.ex",
    "lib/relyra/testing/adapters.ex"
  ]

  @support_files [
    "lib/relyra/error.ex",
    "lib/relyra/connection.ex",
    "lib/relyra/telemetry.ex",
    "lib/relyra/request_store.ex",
    "lib/relyra/replay_store.ex",
    "lib/relyra/connection_resolver.ex",
    "lib/relyra/security/xml/attribute_escape.ex",
    "lib/relyra/security/xml/saxy_tree.ex",
    "lib/relyra/security/xml/c14n.ex",
    "lib/relyra/security/xml/pure_beam.ex"
  ]

  @compiled_core_modules [
    Relyra.Testing.Fixture,
    Relyra.Testing.Adapters.RequestStore,
    Relyra.Testing.Adapters.ReplayStore,
    Relyra.Testing.Adapters.ConnectionResolver,
    Relyra.Testing.Signer,
    Relyra.Testing
  ]

  test "core public testing files contain no Phoenix or Plug.Conn references" do
    for path <- @core_files do
      source = File.read!(path)

      refute source =~ "Phoenix", "#{path} must not reference Phoenix"
      refute source =~ "Phoenix.ConnTest", "#{path} must not reference Phoenix.ConnTest"
      refute source =~ "Plug.Conn", "#{path} must not reference Plug.Conn"
      refute source =~ "use Phoenix", "#{path} must not use Phoenix"
      refute source =~ "import Phoenix", "#{path} must not import Phoenix"
      refute source =~ "alias Phoenix", "#{path} must not alias Phoenix"
    end
  end

  test "only the optional Phoenix testing layer references Phoenix.ConnTest" do
    testing_files =
      Path.wildcard("lib/relyra/testing*.ex") ++ Path.wildcard("lib/relyra/testing/*.ex")

    offenders =
      testing_files
      |> Enum.filter(&(File.read!(&1) =~ "Phoenix.ConnTest"))
      |> Enum.reject(&(&1 == "lib/relyra/testing/phoenix.ex"))

    assert offenders == []
  end

  test "core public testing modules compile and load without Phoenix ebins" do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "relyra-testing-optional-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    files = @support_files ++ @core_files
    copy_sources!(files, tmp_dir)

    probe_path = Path.join(tmp_dir, "probe.exs")
    File.write!(probe_path, probe_script(files, dependency_ebins_without_phoenix()))

    {output, status} = System.cmd("elixir", [probe_path], cd: tmp_dir, stderr_to_stdout: true)

    assert status == 0, output
    assert output =~ "compiled core Relyra.Testing modules without Phoenix"
  end

  defp copy_sources!(files, tmp_dir) do
    for path <- files do
      target = Path.join(tmp_dir, path)
      File.mkdir_p!(Path.dirname(target))
      File.cp!(path, target)
    end
  end

  defp dependency_ebins_without_phoenix do
    "_build/test/lib/*/ebin"
    |> Path.wildcard()
    |> Enum.map(&Path.expand/1)
    |> Enum.reject(&String.contains?(&1, "phoenix"))
    |> Enum.sort()
  end

  defp probe_script(files, ebin_paths) do
    """
    ebin_paths = #{inspect(ebin_paths)}
    Enum.each(ebin_paths, &:code.add_patha(String.to_charlist(&1)))

    if Enum.any?(:code.get_path(), &(to_string(&1) =~ "phoenix")) do
      raise "Phoenix ebin path leaked into subprocess"
    end

    if Code.ensure_loaded?(Phoenix) do
      raise "Phoenix unexpectedly loaded in subprocess"
    end

    if Code.ensure_loaded?(Phoenix.ConnTest) do
      raise "Phoenix.ConnTest unexpectedly loaded in subprocess"
    end

    files = #{inspect(files)}
    Enum.each(files, &Code.compile_file/1)

    modules = #{inspect(@compiled_core_modules)}

    for module <- modules do
      unless Code.ensure_loaded?(module) do
        raise "Expected \#{inspect(module)} to load"
      end
    end

    IO.puts("compiled core Relyra.Testing modules without Phoenix")
    """
  end
end
