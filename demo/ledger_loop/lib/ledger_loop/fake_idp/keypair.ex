defmodule LedgerLoop.FakeIdP.Keypair do
  @moduledoc """
  Loads the committed demo IdP keypair from `priv/fake_idp/`.

  This module is demo-only: the keypair is a committed demo secret with no
  real-world trust. It MUST NOT reference `Relyra.TestSupport.*` — those
  modules are stripped from relyra's `:prod` compiled path-dep build.

  The private key is cached in `:persistent_term` after first decode to avoid
  repeated disk I/O and PEM parsing on every signing call.
  """

  @key_path "fake_idp/idp_key.pem"
  @cert_path "fake_idp/idp_cert.pem"
  @cache_key {__MODULE__, :private_key}

  @doc """
  Returns the decoded RSA private key as an `{:RSAPrivateKey, ...}` tuple.

  Loaded from `priv/fake_idp/idp_key.pem` and cached in `:persistent_term`
  so repeated calls pay only a lookup cost.
  """
  @spec private_key() :: tuple()
  def private_key do
    case :persistent_term.get(@cache_key, nil) do
      nil ->
        key = load_private_key()
        :persistent_term.put(@cache_key, key)
        key

      cached ->
        cached
    end
  end

  @doc """
  Returns the literal PEM string for the demo IdP self-signed certificate.

  This is the value that must be stored in the enabled connection's fixture
  `relyra_certificates/0` `:pem` field so that Relyra's verifier trusts
  assertions signed by the demo IdP.
  """
  @spec cert_pem() :: String.t()
  def cert_pem do
    Application.app_dir(:ledger_loop, "priv/" <> @cert_path)
    |> File.read!()
  end

  # ---------------------------------------------------------------------------
  # Internal
  # ---------------------------------------------------------------------------

  defp load_private_key do
    pem_bin =
      Application.app_dir(:ledger_loop, "priv/" <> @key_path)
      |> File.read!()

    [entry] = :public_key.pem_decode(pem_bin)
    :public_key.pem_entry_decode(entry)
  end
end
