defmodule Mix.Tasks.Verify.ReleaseParity do
  @moduledoc """
  Verifies that the file list inside the published Hex tarball for `X.Y.Z`
  matches the file list at git tag `vX.Y.Z` over Relyra's full `package.files`
  scope (lib/, priv/, docs/, guides/, and root artifacts).

  ## Usage

      mix verify.release_parity 1.4.0
      mix verify.release_parity 1.4.0 --json

  ## Exit codes

    * `0` — parity (no drift)
    * `2` — drift detected or `test_support` path in published tarball
    * `1` — runtime error (network failure, missing tag, tarball fetch failure)

  ## Retry behavior

  `RELYRA_RELEASE_VERIFY_ATTEMPTS` (default 10) and
  `RELYRA_RELEASE_VERIFY_SLEEP_MS` (default 15_000) allow CDN propagation
  retries after a freshly-cut release.

  ## Implementation notes

  Path-set equality is the primary gate — outer `.tar` SHA256 may differ while
  extracted contents match. Any published path containing `test_support` fails
  closed before the path-set diff (TD-02 defense-in-depth).
  """

  @shortdoc "Compare Hex tarball paths to git tag for a released version"

  use Mix.Task

  @default_attempts 10
  @default_sleep_ms 15_000

  @version_regex ~r/^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$/

  @dir_prefixes ~w(lib/ priv/ docs/ guides/)

  @root_files ~w(
    .formatter.exs
    mix.exs
    README.md
    CONFORMANCE.md
    CHANGELOG.md
    LICENSE
    SECURITY.md
    SECURITY_REVIEW.md
    SECURITY_REVIEW_EVIDENCE.md
    BATTERIES_INCLUDED.md
  )

  @hex_metadata_file "hex_metadata.config"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, _invalid} = OptionParser.parse(args, strict: [json: :boolean])
    version = parse_version!(argv)

    attempts = env_integer("RELYRA_RELEASE_VERIFY_ATTEMPTS", @default_attempts)
    sleep_ms = env_integer("RELYRA_RELEASE_VERIFY_SLEEP_MS", @default_sleep_ms)

    tmp_root = unique_tmp_dir!()

    try do
      hex_paths_raw = fetch_hex_paths!(version, tmp_root, attempts, sleep_ms)
      assert_no_test_support!(hex_paths_raw)
      hex_paths = drop_hex_metadata(hex_paths_raw)

      git_paths = fetch_git_paths!(version)

      case compute(git_paths, hex_paths) do
        :parity ->
          emit_parity!(version, opts)
          :ok

        {:drift, only_in_git, only_in_hex} ->
          emit_drift_and_halt!(version, only_in_git, only_in_hex, opts)
      end
    after
      File.rm_rf(tmp_root)
    end
  end

  @doc """
  Pure path-set comparison. Returns `:parity` when the two MapSets are equal,
  otherwise `{:drift, only_in_git_sorted, only_in_hex_sorted}`.
  """
  @spec compute(MapSet.t(String.t()), MapSet.t(String.t())) ::
          :parity | {:drift, [String.t()], [String.t()]}
  def compute(%MapSet{} = git_paths, %MapSet{} = hex_paths) do
    only_in_git =
      git_paths |> MapSet.difference(hex_paths) |> MapSet.to_list() |> Enum.sort()

    only_in_hex =
      hex_paths |> MapSet.difference(git_paths) |> MapSet.to_list() |> Enum.sort()

    case {only_in_git, only_in_hex} do
      {[], []} -> :parity
      {og, oh} -> {:drift, og, oh}
    end
  end

  @doc """
  Renders the `--json` output envelope. Parity renders as `"ok"`.
  """
  @spec render_json(String.t(), :parity | :drift, [String.t()], [String.t()]) ::
          String.t()
  def render_json(version, status, only_in_git, only_in_hex)
      when status in [:parity, :drift] do
    status_str = if status == :parity, do: "ok", else: "drift"

    Jason.encode!(%{
      "version" => version,
      "status" => status_str,
      "only_in_git" => Enum.sort(only_in_git),
      "only_in_hex" => Enum.sort(only_in_hex)
    })
  end

  @doc """
  Retry loop with env-configurable attempts and sleep between transient failures.
  """
  @spec retry_until!(String.t(), pos_integer(), non_neg_integer(), (-> :ok | {:error, term()})) ::
          :ok | no_return()
  def retry_until!(label, attempts, sleep_ms, fun) do
    Enum.reduce_while(1..attempts, nil, fn attempt, _acc ->
      Mix.shell().info("==> #{label} (attempt #{attempt}/#{attempts})")

      case fun.() do
        :ok ->
          {:halt, :ok}

        {:error, reason} when attempt < attempts ->
          Mix.shell().info(to_string(reason))
          Process.sleep(sleep_ms)
          {:cont, nil}

        {:error, reason} ->
          Mix.raise("#{label} failed after #{attempts} attempts\n\n#{reason}")
      end
    end)
  end

  @doc """
  Validates the version argument against canonical semver before any subprocess.
  """
  @spec parse_version!([String.t()]) :: String.t() | no_return()
  def parse_version!([version]) when is_binary(version) and version != "" do
    if Regex.match?(@version_regex, version) do
      version
    else
      Mix.raise(
        "verify.release_parity expects a semver version (e.g. 1.4.0 or 1.0.0-rc.1), got: #{inspect(version)}"
      )
    end
  end

  def parse_version!(_argv) do
    Mix.raise(
      "verify.release_parity expects exactly one version argument, e.g. mix verify.release_parity 1.4.0"
    )
  end

  @doc """
  Returns sorted path prefixes and root files matching `mix.exs` `package.files`.
  """
  @spec expected_relative_paths() :: [String.t()]
  def expected_relative_paths do
    (@dir_prefixes ++ @root_files) |> Enum.sort()
  end

  @doc """
  Filters relative paths to the `package.files` scope and excludes `test_support`.
  """
  @spec filter_package_paths([String.t()]) :: [String.t()]
  def filter_package_paths(paths) when is_list(paths) do
    paths
    |> Enum.reject(&test_support_path?/1)
    |> Enum.filter(&package_path?/1)
    |> Enum.sort()
  end

  @doc """
  Returns true when any path contains `test_support`.
  """
  @spec paths_contain_test_support?([String.t()]) :: boolean()
  def paths_contain_test_support?(paths) when is_list(paths) do
    Enum.any?(paths, &test_support_path?/1)
  end

  defp test_support_path?(path) when is_binary(path) do
    String.contains?(path, "test_support")
  end

  @doc """
  Hard-fails with exit 2 when published paths include `test_support`.
  """
  @spec assert_no_test_support!([String.t()]) :: :ok | no_return()
  def assert_no_test_support!(paths) when is_list(paths) do
    if paths_contain_test_support?(paths) do
      offenders =
        paths
        |> Enum.filter(&String.contains?(&1, "test_support"))
        |> Enum.sort()

      Mix.shell().error("""
      Published tarball contains test_support paths (TD-02 violation):
      #{Enum.map_join(offenders, "\n", &"  #{&1}")}
      """)

      System.halt(2)
    else
      :ok
    end
  end

  defp fetch_hex_paths!(version, tmp_root, attempts, sleep_ms) do
    retry_until!("hex.package fetch relyra #{version}", attempts, sleep_ms, fn ->
      do_fetch_hex(version, tmp_root)
    end)

    list_regular_files_recursive(tmp_root)
    |> Enum.map(&Path.relative_to(&1, tmp_root))
    |> filter_package_paths()
  end

  defp list_regular_files_recursive(root) do
    case File.ls(root) do
      {:ok, entries} ->
        Enum.flat_map(entries, fn entry ->
          path = Path.join(root, entry)

          cond do
            File.regular?(path) -> [path]
            File.dir?(path) -> list_regular_files_recursive(path)
            true -> []
          end
        end)

      {:error, _} ->
        []
    end
  end

  defp do_fetch_hex(version, tmp_root) do
    {output, exit_status} =
      System.cmd(
        "mix",
        ["hex.package", "fetch", "relyra", version, "--unpack", "-o", tmp_root],
        stderr_to_stdout: true
      )

    case exit_status do
      0 ->
        if File.exists?(Path.join(tmp_root, "mix.exs")) do
          :ok
        else
          {:error,
           "hex.package fetch succeeded but tmp_dir lacks mix.exs (empty tarball?):\n\n#{output}"}
        end

      _ ->
        {:error, "mix hex.package fetch failed:\n\n#{output}"}
    end
  end

  defp fetch_git_paths!(version) do
    tag = "v#{version}"

    {output, exit_status} =
      System.cmd("git", ["ls-tree", "-r", "--name-only", tag], stderr_to_stdout: true)

    case exit_status do
      0 ->
        paths =
          output
          |> String.split("\n", trim: true)
          |> filter_package_paths()
          |> MapSet.new()

        if MapSet.size(paths) == 0 do
          Mix.raise(
            "git ls-tree for tag #{tag} returned no package paths. Does the tag exist?\n\nRun: git fetch --tags"
          )
        end

        paths

      _ ->
        Mix.raise("git ls-tree failed for tag #{tag}:\n\n#{output}")
    end
  end

  defp drop_hex_metadata(paths) do
    paths
    |> Enum.reject(&(&1 == @hex_metadata_file))
    |> MapSet.new()
  end

  defp package_path?(path) do
    Enum.any?(@dir_prefixes, &String.starts_with?(path, &1)) or path in @root_files
  end

  defp emit_parity!(version, opts) do
    output =
      if opts[:json] do
        render_json(version, :parity, [], [])
      else
        "Release parity OK for relyra #{version}: tag v#{version} and Hex tarball agree on package.files scope."
      end

    Mix.shell().info(output)
  end

  @spec emit_drift_and_halt!(String.t(), [String.t()], [String.t()], keyword()) :: no_return()
  defp emit_drift_and_halt!(version, only_in_git, only_in_hex, opts) do
    output =
      if opts[:json] do
        render_json(version, :drift, only_in_git, only_in_hex)
      else
        human_diff(version, only_in_git, only_in_hex)
      end

    Mix.shell().info(output)
    System.halt(2)
  end

  defp human_diff(version, only_in_git, only_in_hex) do
    """
    Release parity drift detected for relyra #{version}:
      #{length(only_in_git)} files only in git tag (missing from Hex tarball)
      #{length(only_in_hex)} files only in Hex tarball (not in git tag)

    Only in git tag (missing from Hex tarball):
    #{format_paths(only_in_git)}

    Only in Hex tarball (not in git tag):
    #{format_paths(only_in_hex)}
    """
  end

  defp format_paths([]), do: "  (none)"

  defp format_paths(paths) do
    Enum.map_join(paths, "\n", &"  #{&1}")
  end

  defp unique_tmp_dir! do
    path =
      Path.join(
        System.tmp_dir!(),
        "relyra-release-parity-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end

  defp env_integer(name, default) do
    case System.get_env(name) do
      nil ->
        default

      value ->
        case Integer.parse(value) do
          {parsed, ""} when parsed > 0 -> parsed
          _ -> Mix.raise("#{name} must be a positive integer, got: #{inspect(value)}")
        end
    end
  end
end
