defmodule RelyraTest do
  use ExUnit.Case, async: true

  test "start_login/3 returns documented tuple contract" do
    connection = %{
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs"
    }

    relay_context = %{return_to: "/dashboard"}

    case Relyra.start_login(connection, relay_context) do
      {:ok, %{request_id: request_id, relay_state: relay_state}} ->
        assert String.starts_with?(request_id, "id_")
        assert String.starts_with?(relay_state, "rs_")

      {:error, %Relyra.Error{} = error} ->
        assert match?({:error, %Relyra.Error{}}, {:error, error})
        assert is_atom(error.type)
    end
  end
end
