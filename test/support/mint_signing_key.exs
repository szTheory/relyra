defmodule Relyra.TestSupport.MintSigningKey do
  @moduledoc false

  @spec mint!(Path.t()) :: %{path: Path.t(), sha256: String.t(), byte_count: non_neg_integer()}
  def mint!(path) when is_binary(path) do
    key = :public_key.generate_key({:rsa, 2048, 65_537})
    entry = :public_key.pem_entry_encode(:RSAPrivateKey, key)
    pem = :public_key.pem_encode([entry])

    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, pem)

    %{
      path: path,
      sha256: Base.encode16(:crypto.hash(:sha256, pem), case: :lower),
      byte_count: byte_size(pem)
    }
  end
end
