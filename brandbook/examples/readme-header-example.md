<p align="center">
  <img src="brandbook/assets/logo-primary.svg" alt="Relyra" width="320" />
</p>

<p align="center"><em>Enterprise SAML, calmly verified.</em></p>

<p align="center">
  <a href="https://hex.pm/packages/relyra"><img src="https://img.shields.io/hexpm/v/relyra.svg" alt="Hex version" /></a>
  <a href="https://hexdocs.pm/relyra"><img src="https://img.shields.io/badge/docs-hexdocs-8A2BE2.svg" alt="Docs" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/hexpm/l/relyra.svg" alt="License" /></a>
  <a href="https://github.com/szTheory/relyra/actions"><img src="https://img.shields.io/github/actions/workflow/status/szTheory/relyra/ci.yml?branch=main" alt="CI" /></a>
</p>

---

Relyra is a strict-by-default SAML 2.0 service-provider library for Elixir and Phoenix. Every login ends in a cryptographically verified assertion or a typed rejection — signatures are checked against the certificates you configure, never the ones a document carries.

## Quick look

```elixir
# Apply vetted defaults for a known IdP, then verify a response.
connection = Relyra.apply_defaults(:okta, entity_id: "https://idp.example.com/saml")

case Relyra.consume_response(conn, raw_response, connection: connection) do
  {:ok, %Relyra.Assertion{subject: subject}} ->
    {:ok, subject}

  {:error, %Relyra.Rejection{reason: reason}} ->
    # A typed rejection — never a silent compromise.
    {:error, reason}
end
```
