# Relyra

Relyra is a strict-by-default **SAML 2.0 Service Provider library for Elixir/Phoenix**.
It is for teams that need enterprise SSO without becoming SAML experts.

## What v0.1 includes

- SP-initiated login + ACS validation.
- Hardened XML / signature / protocol checks.
- Provider presets for Okta, Microsoft Entra ID, and Google Workspace.
- `Relyra.TestSupport` and `Relyra.TestSupport.FakeIdP` for local tests.
- `mix relyra.install` for minimal host-app scaffolding.

## What v0.1 does not include

- OIDC/OAuth.
- Hosted broker runtime.
- SCIM ownership.
- Ecto schemas / metadata import-export / rollover (v0.2+).

## Install

```elixir
def deps do
  [
    {:relyra, "~> 0.1.0"}
  ]
end
```

Then scaffold the host app:

```bash
mix relyra.install --module MyApp --repo my-app
```

## Quick start

1. Pick a provider preset with `Relyra.Provider.apply_defaults/2`.
2. Wire the Phoenix router and ACS endpoint.
3. Use `Relyra.TestSupport` in tests.

## Guides

- [Getting Started](guides/getting_started.md)
- [Okta recipe](guides/recipes/okta.md)
- [Microsoft Entra ID recipe](guides/recipes/entra.md)
- [Google Workspace recipe](guides/recipes/google_workspace.md)
- [Security policy](SECURITY.md)

## Security

Relyra follows a fail-closed trust path. See [`SECURITY.md`](SECURITY.md) for
supported algorithms, threat model, and private disclosure workflow.
