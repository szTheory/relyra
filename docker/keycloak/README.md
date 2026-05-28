# Keycloak adoption lane (maintainers only)

Local IdP for `@tag :external_idp` journey tests.

## Start

```bash
docker compose -f docker/keycloak/docker-compose.yml up
```

Wait until the realm is ready:

```bash
curl -sf http://localhost:8080/realms/relyra-adoption/.well-known/openid-configuration
```

## Run the external IdP test

```bash
export KEYCLOAK_BASE_URL=http://localhost:8080
mix test test/adoption/keycloak --only external_idp --warnings-as-errors
```

## Realm defaults

| Item | Value |
|------|-------|
| Realm | `relyra-adoption` |
| SAML client / SP entity ID | `relyra-adoption-sp` |
| ACS URL | `http://demo-host.test/keycloak/acs` |
| Test user | `adoption` / `adoption-test-pass` |

These values are mirrored in `test/adoption/keycloak/fixtures/connection.json` and the realm import JSON.
