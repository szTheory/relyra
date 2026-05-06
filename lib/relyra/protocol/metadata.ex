defmodule Relyra.Protocol.Metadata do
  @moduledoc false

  @spec build_sp_metadata(map(), keyword()) :: binary()
  def build_sp_metadata(connection, _opts \\ []) do
    issuer = Map.get(connection, :sp_entity_id) || Map.get(connection, :issuer)
    acs_url = Map.get(connection, :acs_url)

    # Minimal SP metadata XML
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="#{issuer}">
      <md:SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="#{acs_url}" index="1" isDefault="true"/>
      </md:SPSSODescriptor>
    </md:EntityDescriptor>
    """
    |> String.trim()
  end
end
