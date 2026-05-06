defmodule Relyra.Ecto.RuntimeReadinessTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.Certificate
  alias Relyra.Ecto.Connection

  test "runtime_ready accepts enabled connections with complete runtime fields" do
    connection = %Connection{
      status: :enabled,
      connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y5",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      certificates: [
        %Certificate{
          fingerprint_sha256: "abc123",
          pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
          source: "manual",
          lifecycle_state: :active,
          role: :signing
        }
      ]
    }

    assert :ok = Connection.runtime_ready(connection)
  end

  test "runtime_ready rejects disabled connections" do
    connection = %Connection{
      status: :disabled,
      connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y5",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      certificates: [
        %Certificate{
          fingerprint_sha256: "abc123",
          pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
          source: "manual",
          lifecycle_state: :active,
          role: :signing
        }
      ]
    }

    assert {:error, %Relyra.Error{type: :connection_not_runtime_ready}} =
             Connection.runtime_ready(connection)
  end

  test "runtime_ready ignores staged certificates when determining trust readiness" do
    connection = %Connection{
      status: :enabled,
      connection_id: "01JT6Z2R8QG2QK9S8JQ8RQW7Y6",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      certificates: [
        %Certificate{
          fingerprint_sha256: "next-only",
          pem: "-----BEGIN CERTIFICATE-----\nNEXT\n-----END CERTIFICATE-----",
          source: "metadata",
          lifecycle_state: :next,
          role: :signing
        }
      ]
    }

    assert {:error, %Relyra.Error{type: :connection_not_runtime_ready, details: details}} =
             Connection.runtime_ready(connection)

    assert details.reason == :missing_certificates
  end
end
