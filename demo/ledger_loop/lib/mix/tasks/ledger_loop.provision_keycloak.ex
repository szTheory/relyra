defmodule Mix.Tasks.LedgerLoop.ProvisionKeycloak do
  use Mix.Task

  @shortdoc "Installs the optional Keycloak demo connection"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    case LedgerLoop.Demo.KeycloakProvisioner.provision!(
           relyra_host: System.get_env("RELYRA_HOST", "relyra.localhost"),
           descriptor_url:
             System.get_env(
               "KEYCLOAK_DESCRIPTOR_URL",
               "http://keycloak:8080/realms/demo-app/protocol/saml/descriptor"
             )
         ) do
      {:ok, _connection} ->
        :ok

      {:error, reason} ->
        Mix.raise("Keycloak provisioning failed at audited trust bootstrap: #{inspect(reason)}")
    end
  end
end
