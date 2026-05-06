# Relyra in the Auth Stack

Notes on how Relyra positions relative to its sibling libs (Sigra, Lockspire). Source material for future Relyra guides — keep this aligned with the canonical ecosystem overview shipped in Sigra at `guides/introduction/ecosystem-overview.md`.

## The three-role model

| Role | Direction | Library |
|------|-----------|---------|
| End-user accounts, sessions, MFA, passkeys, social login | Inbound (local) | **Sigra** |
| Enterprise SAML SSO from customers' IdPs | Inbound (federated) | **Relyra** |
| OAuth/OIDC authorization server for third-party API clients | Outbound | **Lockspire** |

Relyra is **inbound, federated**. It terminates SAML, validates the assertion, and hands the host app verified attributes. It does **not** own users, sessions, or token issuance.

## Where Relyra hands off

Relyra's responsibility ends at "here is a verified assertion with these attributes." From there:

```text
SAML IdP ──► Relyra ACS endpoint ──► verified assertion
                                          │
                                          ▼
                              host glue (small, host-owned)
                                          │
                                          ├─► find or create user in Sigra
                                          │     (Sigra.Identity / Accounts context)
                                          │
                                          └─► start Sigra session
                                                (Sigra.Session.get_or_create/4)
                                                      │
                                                      ▼
                                              normal Phoenix request flow
                                              (current_scope assigned by Sigra)
```

After the session exists, **Relyra is no longer in the picture for that request.** Lockspire (if present) reads the same Sigra session via its `AccountResolver` and treats the SAML-originated user identically to a password-originated user.

## Boundaries (non-goals)

Relyra does **not**:

- Own users, sessions, or password/MFA infrastructure (Sigra does)
- Issue OAuth or OIDC tokens (Lockspire does)
- Run as a SAML IdP — Relyra is SP-only by design (see PROJECT.md)
- Manage account lifecycle, deletion, or audit beyond SAML-trust-config audit
- Provide a hosted broker runtime ("zero hosted infra" is a product constraint)

Relyra **does**:

- Validate XML/signatures/protocol with strict defaults (see CONVENTIONS.md)
- Resolve per-tenant SAML connections via the `ConnectionResolver` behaviour
- Manage durable trust config (connection records, certificate inventory, attribute mappings) with audit trail
- Provide a small `SessionAdapter` seam so the host can integrate with whichever session lib it uses (Sigra is the expected default)

## The host-glue pattern

Relyra's `SessionAdapter` behaviour is the SP analog to Lockspire's `AccountResolver`. The host implements it as a thin module that:

1. Receives a verified assertion from Relyra
2. Maps assertion attributes (typically `email`, `name`, group claims) to a host user representation
3. Creates the host session

For a Sigra-backed host, the implementation is roughly:

```elixir
defmodule MyApp.Relyra.SessionImpl do
  @behaviour Relyra.SessionAdapter

  def establish_session(conn, %Relyra.Assertion{} = assertion, _opts) do
    config = MyApp.Sigra.config()

    with {:ok, user} <- find_or_create_user(assertion),
         {:ok, session} <- Sigra.Auth.create_session(config, user, %{auth_method: :saml}) do
      {:ok, Plug.Conn.put_session(conn, :user_token, session.token)}
    end
  end

  defp find_or_create_user(assertion) do
    # Use (provider, provider_uid) from assertion as the link;
    # email is the secondary lookup. Both live in Sigra's user_identities table.
    MyApp.Accounts.upsert_from_saml(assertion.attributes, assertion.connection_id)
  end
end
```

This module is **host-owned** and **host-generated**. The intended generator command (when scaffolding lands) is `mix relyra.install --sigra-host` — mirroring the convention Lockspire uses (`mix lockspire.install --sigra-host`). The generator lives on the *Relyra* side because Relyra owns the `SessionAdapter` contract.

## Why generators live on the *consumer* side

Both Lockspire and Relyra consume Sigra's session. The integration codegen lives on each consumer's side rather than on Sigra's because:

- The consumer owns the behaviour contract being satisfied
- Sigra's `current_scope` shape is stable; consumers know what to read from it
- Sigra stays clean of integration knowledge for every possible companion
- Adopters of Lockspire or Relyra get a one-stop install command in the lib they're adding

This is consistent with the design captured in Sigra's `guides/recipes/companion-oauth-provider.md` and Lockspire's `docs/sigra-companion-host.md`.

## Coexistence with Lockspire

Relyra and Lockspire never talk to each other directly. They both talk to Sigra's session layer. A user who logs in via Relyra and later authorizes a third-party app via Lockspire goes through:

1. Browser → Relyra ACS → host glue → Sigra session created
2. Browser → Lockspire `/authorize` → Lockspire's `AccountResolver` reads `current_scope` from the same Sigra session → claims built → tokens issued

The third-party app receives an OAuth/OIDC token whose `sub` is the Sigra user's stable id, regardless of how that user originally authenticated. SAML-vs-password is invisible to the OAuth client by design.

## Future doc work

When Relyra's docs/guides mature, this material should be split into:

- A short "Where Relyra fits" intro doc (mirroring Sigra's `ecosystem-overview.md`)
- A practical SAML→Sigra recipe (mirroring Sigra's `recipes/companion-oauth-provider.md`)
- A `mix relyra.install --sigra-host` reference doc (when the generator ships)

Until then, this file is the source-of-truth for the positioning story.
