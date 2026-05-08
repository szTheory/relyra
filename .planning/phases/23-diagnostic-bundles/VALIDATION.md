# Phase 23 Validation: Diagnostic Bundles

## 1. Observable Truths
*These must be true from the user/operator perspective:*
- Operator can trigger the creation of a `.zip` bundle containing relevant system state.
- The generated bundle redacts all sensitive fields (PII, private keys, secrets) using a strict allow-list schema.
- Bundle includes bounded slice (last 1000) of audit logs with hashed correlation IDs.
- Bundle includes `store_metrics.json` with counts for RequestStore and ReplayStore.
- Operator can generate bundle via mix task and save to disk.
- Operator can download bundle from LiveAdmin UI.

## 2. Required Artifacts
*These files must exist and provide specific capabilities:*
- `lib/relyra/diagnostic/allow_list.ex` - Provides explicit fail-safe redaction map logic.
- `lib/relyra/diagnostic.ex` - Provides Ecto orchestration and Erlang `:zip` memory compilation.
- `lib/mix/tasks/relyra.diagnostic.ex` - Provides CLI bundle trigger.
- `lib/relyra/phoenix/controllers/diagnostic_controller.ex` - Provides HTTP download endpoint for the diagnostic zip.
- `lib/relyra/live_admin/connections_live.ex` - Provides Download button in the connections list UI.

## 3. Key Links (Wiring)
*These critical connections must be present for the system to function:*
- `lib/relyra/diagnostic.ex` -> `lib/relyra/diagnostic/allow_list.ex`: Calls explicit map functions for serialization (Pattern: `AllowList\.export_`).
- `lib/mix/tasks/relyra.diagnostic.ex` -> `lib/relyra/diagnostic.ex`: Calls create_bundle and writes to file (Pattern: `Relyra\.Diagnostic\.create_bundle`).
- `lib/relyra/phoenix/controllers/diagnostic_controller.ex` -> `lib/relyra/diagnostic.ex`: Calls create_bundle and sends zip over HTTP (Pattern: `send_download\(.*:binary`).
