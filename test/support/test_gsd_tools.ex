defmodule Relyra.TestGsdTools do
  @moduledoc false

  # Mirrors resolve_gsd_tools/2 in scripts/verify_phase79_plan_contract.py.
  @search_order ["GSD_TOOLS", "CLAUDE_CONFIG_DIR", "HOME/.claude", "HOME/.codex", "repository"]
  @relative "gsd-core/bin/gsd-tools.cjs"
  @unavailable_prefix "gsd_tools_unavailable: gsd-tools not found; set GSD_TOOLS to an installed gsd-tools.cjs or install GSD"

  def search_order, do: @search_order

  def resolve do
    env = System.get_env()
    home = env_value(env, "HOME") || System.user_home!()
    resolve(env, home, File.cwd!())
  end

  def resolve(env, home, root) do
    case env_value(env, "GSD_TOOLS") do
      nil ->
        candidates = candidates(env, home, root)

        case Enum.find(candidates, fn {_label, path} -> File.regular?(path) end) do
          {_label, path} ->
            {:ok, path}

          nil ->
            searched = Enum.map_join(candidates, ", ", fn {_label, path} -> path end)
            {:error, {:gsd_tools_unavailable, "#{@unavailable_prefix}; searched: #{searched}"}}
        end

      override ->
        if File.regular?(override) do
          {:ok, override}
        else
          {:error,
           {:gsd_tools_unavailable,
            "#{@unavailable_prefix}; GSD_TOOLS=#{override} is not a regular file " <>
              "(an explicit override never falls back)"}}
        end
    end
  end

  def candidates(env, home, root) do
    config =
      case env_value(env, "CLAUDE_CONFIG_DIR") do
        nil -> []
        directory -> [{"CLAUDE_CONFIG_DIR", Path.join(directory, @relative)}]
      end

    config ++
      [
        {"HOME/.claude", Path.join([home, ".claude", @relative])},
        {"HOME/.codex", Path.join([home, ".codex", @relative])},
        {"repository", Path.join(root, @relative)}
      ]
  end

  def test_tags do
    case resolve() do
      {:ok, _path} -> [requires_gsd_tools: true]
      {:error, {:gsd_tools_unavailable, message}} -> [requires_gsd_tools: true, skip: message]
    end
  end

  defp env_value(env, name) do
    case Map.get(env, name) do
      value when is_binary(value) and value != "" -> value
      _other -> nil
    end
  end
end
