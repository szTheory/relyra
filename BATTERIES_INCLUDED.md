# Batteries Included Proof

Generated from the shipped installer, test-support seam, provider registry, and focused proof commands in this repository.

## Rerun Commands

- `mix ci.docs`
- `mix relyra.batteries_included --check`
- `mix test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors`

## Supported Provider Scope

- First-class batteries-included providers: Okta, Microsoft Entra ID, Google Workspace, Active Directory Federation Services
- Runbooks: Okta (`guides/recipes/okta.md`); Microsoft Entra ID (`guides/recipes/entra.md`); Google Workspace (`guides/recipes/google_workspace.md`); Active Directory Federation Services (`guides/recipes/adfs.md`)

## Claim To Proof Map

| claim | executable state | seam | proof command | artifact |
| --- | --- | --- | --- | --- |
| install path is blessed and reproducible | `mix relyra.install` scaffolds the host integration surface and optional LiveAdmin contract | `Mix.Tasks.Relyra.Install.run/1` | `mix test test/mix/relyra_install_test.exs --warnings-as-errors` | `test/mix/relyra_install_test.exs` |
| local-first proof starts with FakeIdP | a tiny host-side ACS flow succeeds before any real IdP setup | `Relyra.TestSupport` + `Relyra.TestSupport.FakeIdP` | `mix test test/test_support_demo_test.exs --warnings-as-errors` | `test/test_support_demo_test.exs` |
| supported provider scope stays narrow | first-class scope is limited to Okta, Microsoft Entra ID, Google Workspace, Active Directory Federation Services | `Relyra.Provider.list/0` | `mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors` | `guides/recipes/okta.md`, `guides/recipes/entra.md`, `guides/recipes/google_workspace.md`, `guides/recipes/adfs.md` |
| provider runbooks stay tied to repo reality | Day-1 routing points to authoritative runbooks and no broader preset catalog | `guides/getting_started.md` + `Relyra.Provider.guide_url/1` | `mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors` | `guides/getting_started.md` |
| optional admin remains a later receipt | LiveAdmin is optional and the installer can scaffold its host-side scope contract | `Relyra.LiveAdmin.ScopeProvider` | `mix test test/mix/relyra_install_test.exs --warnings-as-errors` | `test/mix/relyra_install_test.exs` |
| metadata and certificate lifecycle stay observable | metadata refresh and certificate transitions have focused proof lanes and operator-facing docs | `Relyra.Metadata.AutoRefresh` + `Relyra.Ecto.CertificateInventory` | `mix test test/relyra/metadata/auto_refresh_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors` | `guides/case_studies/operator_managed_rollout.md` |
| audit and telemetry are explicit follow-ons | operator receipts include audit evidence and telemetry-facing proof seams | `Relyra.Ecto.AuditWriter` + `Relyra.Telemetry` | `mix test test/relyra/ecto/audit_hardening_test.exs test/relyra/telemetry_test.exs --warnings-as-errors` | `BATTERIES_INCLUDED.md` |
| scheduled refresh is not a marketing claim | background refresh remains backed by focused tests and explicit operator review posture | `Relyra.Metadata.AutoRefresh` + `Relyra.Workers.MetadataRefresh` | `mix test test/relyra/metadata/scheduler_test.exs test/relyra/workers/metadata_refresh_test.exs --warnings-as-errors` | `BATTERIES_INCLUDED.md` |
| diagnostic bundle support is real and bounded | diagnostic export exists as a library-owned surface with controller and allow-list coverage | `Relyra.Diagnostic` + `Relyra.Diagnostic.AllowList` | `mix test test/phoenix/diagnostic_controller_test.exs test/relyra/diagnostic_test.exs test/relyra/diagnostic/allow_list_test.exs --warnings-as-errors` | `BATTERIES_INCLUDED.md` |
