# LedgerLoop FakeIdP Demo Flow

LedgerLoop includes a demo-local FakeIdP browser flow so evaluators can see the
full Relyra trust path without configuring an external identity provider. It is
local test support for the `demo/ledger_loop` Phoenix app only. It is not a
production IdP, not a hosted SSO broker, and not part of the Hex package.

The flow proves the same boundary Relyra enforces in host applications: Relyra
verifies the SAML response, and LedgerLoop owns user mapping, session creation,
and authorization. The FakeIdP signs with the committed demo RSA keypair, while
Relyra still verifies against the configured demo IdP certificate. The verifier
does not trust document `KeyInfo`, skip digest recomputation, or bypass replay
and audience checks for this demo.

## Access Path

Start the LedgerLoop demo at `http://localhost:4000` through `scripts/demo up`
or the local Mix workflow in `demo/ledger_loop/README.md`.

Use the route-affordance login path:

1. Visit `http://localhost:4000/login/test`.
2. Click **Simulate Login via FakeIdP**.
3. The app starts an SP-initiated login at `/saml/<connection-id>/login`.
4. The enabled connection redirects the browser to `/fake_idp/login`.
5. The FakeIdP form posts to `/fake_idp/sso`.
6. `/fake_idp/sso` renders a self-submitting form back to the Relyra ACS route.

You can visit `/fake_idp/login` directly to inspect the form, but the meaningful
proof starts from `/login/test` because that path provides the SP-generated
`SAMLRequest`, `RelayState`, and `InResponseTo` correlation.

## Success Behavior

The default **Valid Login (sarah@northstar.example.com)** radio option emits a
fresh signed SAML response through `LedgerLoop.FakeIdP.Signer`. The ACS receives
the response, Relyra verifies the signature and referenced digest, validates the
recipient, audience, expiry, replay state, and request correlation, then returns
the verified assertion to LedgerLoop's host-owned mapper/session adapter.

Expected result: the browser lands back on the LedgerLoop workspace and a login
receipt exists for the mapped demo user. This is a real cryptographic success
path using the same verifier seams as production Relyra integrations.

## Tamper Behavior

Select **Invalid Login (Tampered Signature)** before submitting the FakeIdP form
to exercise the rejection path. The signer first creates a valid signed response
and then mutates the assertion after signing.

Expected result: the ACS rejects the response with a typed SAML authentication
error containing `digest_mismatch`, returns HTTP 400, and never reaches the
authenticated workspace. This is intentional evidence that the demo fails closed
instead of silently accepting post-signing content changes.

## Automated Check

The root command for the dedicated browser proof is:

```bash
npm run demo:fake-idp
```

That command uses `playwright.fake-idp.config.mjs`, boots `demo/ledger_loop`, and
runs `demo/ledger_loop/test/browser/fake_idp.spec.ts`. The current audit found a
port-4000 coupling: the seeded enabled connection points at
`http://localhost:4000/fake_idp/login`, so the browser lane is green only when
the demo owns port 4000 or the seed/config is made port-aware. Setting `PORT` and
`BASE_URL` alone can still redirect through the hard-coded port-4000 FakeIdP URL.

## Limits

- FakeIdP is a local demo/test harness, not a supported IdP implementation.
- It exists to prove Relyra acceptance and typed rejection in LedgerLoop.
- It is repo-local adoption evidence and is excluded from the Hex package.
- It should not be copied into production hosts as an identity provider.
- Optional Keycloak coverage remains the external-IdP proof; FakeIdP is the
  lightweight local browser proof.
