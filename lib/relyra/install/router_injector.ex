defmodule Relyra.Install.RouterInjector do
  @moduledoc false

  @marker "# --- Relyra SAML routes ---"
  @inject_snippet """
  # --- Relyra SAML routes ---
  import Relyra.Phoenix.Router
  saml_routes()
  """

  @router_use ~r/^\s*use\s+(\w+\.)?Router/

  def detect_routers(root \\ File.cwd!()) do
    root
    |> Path.join("lib/**/*router.ex")
    |> Path.wildcard()
    |> Enum.filter(&router_file?/1)
    |> Enum.sort()
  end

  def inject(contents) when is_binary(contents) do
    cond do
      already_injected?(contents) ->
        {:already_injected, contents}

      true ->
        lines = String.split(contents, "\n", parts: :infinity)

        case Enum.find_index(lines, &router_use_line?/1) do
          nil ->
            :ambiguous

          index ->
            snippet_lines =
              @inject_snippet
              |> String.trim_trailing()
              |> String.split("\n")

            new_lines =
              lines
              |> Enum.with_index()
              |> Enum.flat_map(fn
                {line, ^index} -> [line | snippet_lines]
                {line, _} -> [line]
              end)

            {:ok, Enum.join(new_lines, "\n")}
        end
    end
  end

  defp router_file?(path) do
    case File.read(path) do
      {:ok, contents} -> Regex.match?(~r/use\s+(\w+\.)?Router/, contents)
      _ -> false
    end
  end

  defp router_use_line?(line), do: Regex.match?(@router_use, line)

  defp already_injected?(contents) do
    String.contains?(contents, @marker) or String.contains?(contents, "saml_routes()")
  end
end
