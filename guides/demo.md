# LedgerLoop Demo App

A runnable reference app ships in this repository to show Relyra embedded in a real Phoenix
host application. It is **not part of the Hex package** — it lives only in the source repo and
runs as a path dependency.

> This is adoption evidence, not new capability. The demo uses the same strict defaults as any
> production Relyra install: every login ends in a cryptographically verified assertion receipt
> or a typed rejection. Nothing here relaxes a security invariant; it shows what Relyra does
> in context — and exactly where the host application takes over.

The full guide — boot instructions, reset procedure, seeded credentials, key routes, and all
four SAML connection scenarios — lives in the demo README in the repository:

**[LedgerLoop Demo App README](https://github.com/szTheory/relyra/blob/main/demo/ledger_loop/README.md)**

That file is the canonical evaluator entry point. Start there.

---

For the hexdocs Day-1 install path, see [Getting Started](getting_started.md).
