# Docker demo: one verified local login, then Fleet proofs

This guide is for an evaluator or maintainer who wants one complete Docker-backed
Relyra login without first assembling a local SSO environment. Its job is concrete:
start the LedgerLoop demo, complete the deterministic local IdP sign-in, and leave with
evidence you can inspect. Relyra remains a library; LedgerLoop is the host application
that maps the user, records its session-establishment receipt, and owns authorization.

## Gameplan

1. **Solo (required):** run one deterministic local-IdP login on loopback and inspect
   its validation trace plus LedgerLoop receipt.
2. **Fleet (follow-on):** after the Solo receipt, use the shared proxy to run this
   demo alongside sibling demos.
3. **Keycloak (optional follow-on):** after Fleet, use a real-IdP proof without
   replacing the deterministic Solo journey.

The repo-root `Makefile` is the public Docker interface. `scripts/demo` remains a
compatibility entry point, but it is not a second workflow.

## Mental model

Solo is a complete proof on its own. It publishes LedgerLoop at a loopback URL and
uses the demo-local identity provider, so you do not need Traefik, Fleet, or Keycloak to finish
the first journey. Relyra verifies the cryptographic assertion against configured
IdP certificates: configured IdP certificates are the trust source, never document
key material. LedgerLoop then performs host-owned user mapping and stores its own
session-establishment evidence.

## Solo: prove one local login

### Prerequisites

Install Docker with Compose v2, then work from the repository root. You do not need
to copy `.env.example` for the default Solo route.

Run the launcher check first:

```bash
make doctor
```

If it reports a problem, follow the exact `Next:` remediation printed for that
problem before continuing. For example, free or override port 4000 when doctor says
it is occupied; do not guess at an alternate Compose command.

### Start the deterministic demo

Build and launch the Solo stack:

```bash
make up-build
```

Open [http://localhost:4000/login/test](http://localhost:4000/login/test). Choose
the enabled connection, then select **Simulate Login via FakeIdP**. Complete the
deterministic sign-in offered by FakeIdP.

### Inspect the proof

Return to LedgerLoop after the assertion consumer service completes. Inspect the
operator validation trace at [http://localhost:4000/relyra/admin](http://localhost:4000/relyra/admin),
then inspect the resulting `LoginReceipt` in the workspace evidence.

Relyra verifies the cryptographic assertion and produces the validation trace.
LedgerLoop owns user mapping, owns the persisted session-establishment receipt, and
owns authorization. The receipt is not a claim that Relyra creates a browser cookie
or makes an authorization decision.

**Receipt:** Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt.

## What comes after Solo

Only after recording the Solo receipt should you move to Fleet or optional Keycloak.
They are follow-on proofs, not prerequisites for the deterministic FakeIdP path.

- **Fleet:** the shared proxy route begins with `make proxy` and uses
  `http://relyra.localhost`.
- **Optional Keycloak:** a separately configured real-IdP proof; it never replaces
  FakeIdP as the first journey.
