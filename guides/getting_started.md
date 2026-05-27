# Getting Started

This is the canonical Day-1 onboarding path for Relyra.
Follow the sections in order:

1. Install
2. Scaffold
3. Prove local login with TestSupport
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

## 3. Prove local login with TestSupport

Before touching a real IdP, prove the local trust path with
`use Relyra.TestSupport, endpoint: …`. FakeIdP signing is internal to the macro
helpers — you focus on wiring a stub ACS route and asserting the login receipt.

Prerequisites:

- A host ExUnit test module with Phoenix test deps (`Phoenix.ConnTest`, router).
- A minimal test router and ACS controller (not production `saml_routes()`).

Stub router and controller (adapt module names to your host app):

```elixir
defmodule MyAppWeb.TestRouter do
  use Phoenix.Router

  post("/:connection_id/acs", MyAppWeb.TestAcsController, :acs)
end

defmodule MyAppWeb.TestAcsController do
  use Phoenix.Controller, formats: [html: "Phoenix.HTML"]

  def acs(conn, _params) do
    conn
    |> Plug.Conn.assign(:current_user, %{email: "alice@example.com"})
    |> Phoenix.Controller.text("ok")
  end
end
```

Integration test using the TestSupport macro:

```elixir
defmodule MyAppWeb.SamlLoginTest do
  use ExUnit.Case, async: false
  use Relyra.TestSupport, endpoint: MyAppWeb.TestRouter

  test "local SAML login round-trip" do
    conn = Phoenix.ConnTest.build_conn() |> setup_saml_connection(connection_id: "demo")

    response = build_saml_response() |> sign_saml_response()
    conn = post_saml_response(conn, Base.decode64!(response, padding: false))

    assert_saml_login(conn, %{email: "alice@example.com"})
  end
end
```

Copy-paste source of truth: `test/test_support_demo_test.exs` in the Relyra repo
(also gated in `mix ci.docs`).

**Stub vs production ACS:** The §3 stub assigns `:current_user` directly for a
fast receipt. The §2 install scaffold wires `import Relyra.Phoenix.Router;
saml_routes()` to `Relyra.Phoenix.Controllers.ACSController` and
`consume_response/3` — use that for real integration after this proof.

If this step fails, fix it here. Do not move to a hosted IdP until the local
proof is stable.

Receipt: a host-side test passes with `assert_saml_login/2` (or `saml_login/1`
returns `{:ok, …}`) after `post_saml_response/2` dispatches to your stub ACS route.

## 4. Choose one provider runbook

Choose exactly one first-class batteries-included provider and finish that
runbook before you return to production follow-ons:

- [Okta runbook](recipes/okta.md) at `guides/recipes/okta.md`
- [Microsoft Entra ID runbook](recipes/entra.md) at `guides/recipes/entra.md`
- [Google Workspace runbook](recipes/google_workspace.md) at `guides/recipes/google_workspace.md`

Use one branch only for Day-1. The goal is to finish one real provider path, not
to compare several admins in parallel.

Support taxonomy:

- **Batteries included:** Okta, Microsoft Entra ID, Google Workspace, and ADFS — each has a shipped preset module and repo-native runbook (Okta, Entra, Google, [ADFS](recipes/adfs.md)).
- **Custom SAML:** use the generic operator runbook at
  [guides/recipes/generic_saml.md](recipes/generic_saml.md) when you own the
  provider-specific mapping and verification work yourself.
- **ADFS note:** prefer [guides/recipes/adfs.md](recipes/adfs.md) when signed
  AuthnRequests or ADFS-specific encoding are part of the contract.
- **Not yet shipped:** any provider without a shipped preset module and verified
  repo-native runbook.

For custom SAML providers, adapt the same install -> scaffold -> local proof ->
real provider pattern, starting from `guides/recipes/generic_saml.md`, but do not
treat that path as first-class batteries included support.

Receipt: one provider runbook is completed and you have one real-provider login,
metadata import, or equivalent provider-specific success proof from that runbook.

## 5. Production follow-ons

Once one provider path works, move to the operator-owned follow-ons that make the
integration production-ready. After your first provider login, follow the
[Production Ecto path](production_ecto_path.md) before scaling to multi-node production.

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

After your first successful login, bookmark the
[incident playbook](operations/incident_playbook.md) for on-call Diagnose workflows.

- [Production Ecto path](production_ecto_path.md) — migrate from install ETS defaults to
  cluster-safe ConnectionResolver and RequestStore/ReplayStore Ecto adapters.
- [Incident playbook](operations/incident_playbook.md) — evidence surfaces, `mix relyra.trace`,
  and scenario runbooks for Day-2 SAML incidents (login-trace LiveView at
  `/relyra/admin/connections/:connection_id/trace`).
- [guides/identity_mapping_and_provisioning.md](identity_mapping_and_provisioning.md)
  for the host-owned anchor, lookup, and JIT decisions that come after a
  working provider path.
- [Jobs To Be Done And User Flows](jtbd_user_flows.md)
- [`SECURITY.md`](../SECURITY.md)
- [`SECURITY_REVIEW.md`](../SECURITY_REVIEW.md)

Receipt: you have one working provider path plus a written production follow-on
plan for metadata, certificates, audit/telemetry, and any optional admin surface.

## Appendix: Advanced manual response construction

Power users may call FakeIdP builders directly when debugging signing or metadata
without ConnTest dispatch. This path skips router dispatch — prefer §3 for the
recommended round-trip.

```elixir
metadata = Relyra.TestSupport.fake_idp_metadata()

response =
  []
  |> Relyra.TestSupport.build_saml_response()
  |> Relyra.TestSupport.sign_saml_response()
```

`sign_saml_response/2` returns base64; decode before `post_saml_response/2` in
macro tests. See [§3. Prove local login with TestSupport](#3-prove-local-login-with-testsupport)
for the full integration path.
