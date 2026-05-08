# Batteries Included

This is the first-class proof journey for Relyra's batteries-included claim.
Follow it in order and treat each stage as incomplete until its receipt is
visible.

## 1. Install and scaffold

Start with the blessed host-app entry point:

```bash
mix relyra.install --module MyApp --repo MyApp.Repo
```

Receipt:

- The scaffold command completes cleanly.
- The generated host files exist.
- If you need the optional admin surface, the installer can also scaffold the
  LiveAdmin scope contract.

## 2. Prove the local path with FakeIdP

Before any hosted IdP work, prove the local path with `FakeIdP`:

- Use `Relyra.TestSupport`
- Use `Relyra.TestSupport.FakeIdP`
- Run the tiny host-style round trip already covered by the focused proof test

Receipt:

- The local ACS flow succeeds in a host-style test without touching a real IdP.

## 3. Choose one first-class provider path

The first-class provider set is limited to:

- Okta
- Microsoft Entra ID
- Google Workspace

Pick exactly one provider runbook for Day-1, finish it, and do not broaden the
claim beyond those three presets.

Receipt:

- One provider login works after the local `FakeIdP` proof already passed.

## 4. Return to operator follow-ons

After the first provider path works, move through the operator-owned follow-ons
in order:

- optional LiveAdmin surface
- metadata and certificate lifecycle
- audit and telemetry receipts
- scheduled refresh review
- diagnostic bundle support

Receipt:

- The host team can point to one explicit proof command or artifact for each
  follow-on, not just narrative docs.

## 5. Verify the repo-native proof artifact

The claim-to-proof map lives in [BATTERIES_INCLUDED.md](../BATTERIES_INCLUDED.md).
That file is generated and drift-checked from repo state.

Receipt:

- `mix ci.docs` passes
- `mix relyra.batteries_included --check` passes
- The generated artifact still names the supported provider scope and the
  operator follow-on seams honestly
