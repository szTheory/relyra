defmodule Mix.Tasks.Relyra.Metadata.PinTest do
  @moduledoc """
  Wave 5 (`21-07`) production tests for `Mix.Tasks.Relyra.Metadata.Pin`.

  Verifies argument-validation flow:
  - connection_id (positional) is required
  - at least one `--fingerprint` is required (D-17 trust anchor invariant)
  - `--repo` is required (T-21-31 mitigation — `String.to_existing_atom/1`
    rejects unknown atoms)

  The happy path is exercised via `:integration`-tagged scenarios — these
  require a configured host repo + Connection/MetadataSource fixtures
  and so are deferred to manual validation per `21-VALIDATION.md`.
  """
  use ExUnit.Case, async: false

  alias Mix.Tasks.Relyra.Metadata.Pin

  describe "run/1 — argument validation" do
    test "raises when connection_id positional arg is missing" do
      assert_raise Mix.Error, ~r/connection_id is required/, fn ->
        Pin.run(["--fingerprint", "abc", "--repo", "MyApp.Repo"])
      end
    end

    test "raises when --fingerprint is missing" do
      assert_raise Mix.Error, ~r/--fingerprint is required/, fn ->
        Pin.run(["conn-1", "--repo", "MyApp.Repo"])
      end
    end

    test "raises when --repo is missing" do
      assert_raise Mix.Error, ~r/--repo is required/, fn ->
        Pin.run(["conn-1", "--fingerprint", "abc"])
      end
    end

    test "raises when the named repo is not a loaded atom" do
      assert_raise Mix.Error, ~r/is not loaded/, fn ->
        Pin.run([
          "conn-1",
          "--fingerprint",
          "abc",
          "--repo",
          "ThisRepoDoesNotExist.Repo"
        ])
      end
    end
  end
end
