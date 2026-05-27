# Getting Started

This is the canonical Day-1 onboarding path for Relyra.
Follow the sections in order:

1. Install
2. Scaffold
3. Prove local login with FakeIdP
4. Choose one provider runbook
5. Production follow-ons

If you need broader context, return to the [README](../README.md). Do not start
with optional admin or operations surfaces before the local proof works.

If you want the narrative explanation of what these steps are buying you, read
[Jobs To Be Done And User Flows](jtbd_user_flows.md) after you finish this
guide once.

## 1. Install

Add Relyra to your host application's dependencies:

```elixir
def deps do
  [
    {:relyra, "~> 1.4"}
  ]
end
```

Fetch dependencies:

```bash
mix deps.get
```

Why this comes first:

- It confirms the host can resolve and compile the package.
- It keeps the first receipt local and deterministic.
- It avoids mixing provider admin work into the install step.

Receipt: `mix deps.get` completes and `mix compile` succeeds in the host app.

## 2. Scaffold

Run the blessed scaffold command from the host application:

```bash
mix relyra.install --module MyApp --repo MyApp.Repo
```

The installer sets up the minimal host-side surface without pretending to finish
every app-specific decision for you. Review the generated instructions, wire the
router seams it asks for, and keep the host application's naming consistent with
your actual module and repo names.

At this stage you should have:

- The Relyra dependency installed.
- Generated starter files from `mix relyra.install`.
- The Phoenix router and ACS-related seams wired per the generated instructions.

Receipt: the installer runs cleanly, the generated files exist, and your host app
still boots after you apply the scaffold instructions.

## 3. Prove local login with FakeIdP

Before touching a real IdP, prove the local trust path with
`Relyra.TestSupport.FakeIdP`. This is the default first proof because it signs
real SAML responses with deterministic local fixtures.

Use `Relyra.TestSupport` helpers in a host-side test so you can verify the core
flow without provider admin work:

```elixir
metadata = Relyra.TestSupport.fake_idp_metadata()

response =
  []
  |> Relyra.TestSupport.build_saml_response()
  |> Relyra.TestSupport.sign_saml_response()
```

What this proof should establish:

- Your host app can consume Relyra's local test-support seam.
- The ACS flow succeeds against a deterministic SAML response.
- You can see the same trust-boundary behavior before involving a real provider.

If this step fails, fix it here. Do not move to a hosted IdP until the local
proof is stable.

Receipt: a host-side test or local smoke path succeeds with `FakeIdP`, and you
can point to the passing test or successful login result as your first SAML proof.

## 4. Choose one provider runbook

Choose exactly one first-class batteries-included provider and finish that
runbook before you return to production follow-ons:

- [Okta runbook](recipes/okta.md) at `guides/recipes/okta.md`
- [Microsoft Entra ID runbook](recipes/entra.md) at `guides/recipes/entra.md`
- [Google Workspace runbook](recipes/google_workspace.md) at `guides/recipes/google_workspace.md`

Use one branch only for Day-1. The goal is to finish one real provider path, not
to compare several admins in parallel.

Support taxonomy:

- **Batteries included:** Okta, Microsoft Entra ID, and Google Workspace only.
- **Custom SAML:** use the generic operator runbook at
  [guides/recipes/generic_saml.md](recipes/generic_saml.md) when you own the
  provider-specific mapping and verification work yourself.
- **ADFS special case:** use [guides/recipes/adfs.md](recipes/adfs.md) when signed
  AuthnRequests or ADFS-specific encoding behavior are part of the contract.
- **Not yet shipped:** any provider without a shipped preset module and verified
  repo-native runbook.

For custom SAML providers, adapt the same install -> scaffold -> local proof ->
real provider pattern, starting from `guides/recipes/generic_saml.md`, but do not
treat that path as first-class batteries included support.

Receipt: one provider runbook is completed and you have one real-provider login,
metadata import, or equivalent provider-specific success proof from that runbook.

## 5. Production follow-ons

Once one provider path works, move to the operator-owned follow-ons that make the
integration production-ready.

Recommended order:

1. Confirm your metadata and certificate lifecycle plan.
2. Wire audit and telemetry consumption in the host app.
3. Decide whether you want the optional LiveAdmin surface.
4. Configure scheduled refresh only after trust fingerprints and operator review
   are understood.
5. Add diagnostic bundle handling to your support workflow.

Important posture:

- LiveAdmin is optional and comes late.
- Day-2 operations should not block the first successful login.
- The host application still owns its domain routing, session model, and
  application-specific authorization seams.

Useful follow-on references:

- [guides/identity_mapping_and_provisioning.md](identity_mapping_and_provisioning.md)
  for the host-owned anchor, lookup, and JIT decisions that come after a
  working provider path.
- [Jobs To Be Done And User Flows](jtbd_user_flows.md)
- [`SECURITY.md`](../SECURITY.md)
- [`SECURITY_REVIEW.md`](../SECURITY_REVIEW.md)

Receipt: you have one working provider path plus a written production follow-on
plan for metadata, certificates, audit/telemetry, and any optional admin surface.
