# LedgerLoop Demo App

A runnable reference app ships in this repository to show Relyra embedded in a real Phoenix
host application. It is **not part of the Hex package** — it lives only in the source repo and
runs as a path dependency.

> This is adoption evidence, not new capability. The demo uses the same strict defaults as any
> production Relyra install: every login ends in a cryptographically verified assertion receipt
> or a typed rejection. Nothing here relaxes a security invariant; it shows what Relyra does
> in context — and exactly where the host application takes over.

The Make-first Docker developer guide lives in the source checkout. It is the operational
route for the complete Solo/FakeIdP proof, followed by optional Fleet and Keycloak work:

**[Docker developer guide](https://github.com/szTheory/relyra/blob/main/guides/docker_dev_dx.md)**

The detailed evaluator guide — boot instructions, reset procedure, seeded credentials, key
routes, and all four SAML connection scenarios — is also source-only:

**[LedgerLoop Demo App README](https://github.com/szTheory/relyra/blob/main/demo/ledger_loop/README.md)**

These materials are not Hex package runtime surface. Start with the Make-first Docker guide,
then use the detailed README when you want the full evaluator walkthrough and the Local Mix
alternative.

---

For the hexdocs Day-1 install path, see [Getting Started](getting_started.md).
