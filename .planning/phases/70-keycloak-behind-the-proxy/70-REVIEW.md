---
phase: 70-keycloak-behind-the-proxy
reviewed: 2026-08-26T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - demo/ledger_loop/config/runtime.exs
  - demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex
  - demo/ledger_loop/lib/ledger_loop_web/plugs/demo_admin_auth.ex
  - demo/ledger_loop/lib/ledger_loop_web/router.ex
  - demo/ledger_loop/lib/mix/tasks/ledger_loop.provision_keycloak.ex
  - demo/ledger_loop/test/browser/keycloak.spec.ts
  - demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs
  - demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs
  - demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs
  - demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs
  - docker/keycloak/realm-demo-app.json
  - scripts/test_keycloak_proxy_e2e.sh
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 70: Code Review Report

**Reviewed:** 2026-08-26T00:00:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The review found two ship-blocking boundary failures: descriptor-provided SSO endpoints are trusted without enforcing the locked public Keycloak endpoint, and the diagnostics override can recursively delete an arbitrary matching directory. The provisioner also omits the phase's specified stable internal connection UUID.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Descriptor SSO endpoint is accepted without public-host validation

**Classification:** BLOCKER

**File:** `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex:68`

**Issue:** `descriptor_candidate/3` checks only `candidate.idp_entity_id`. `MetadataApply.apply_revision/4` subsequently applies `candidate.idp_sso_url`, so a descriptor with the expected entity ID but `SingleSignOnService Location` on an attacker-controlled host is accepted and makes the stable login route redirect users there. This violates the phase's fixed public issuer/SSO contract and expands the descriptor trust boundary beyond the configured Keycloak public identity.

**Fix:** Require the selected SSO URL to equal the expected public endpoint before any mutation, and add a failing descriptor test.

```elixir
expected_sso_url = "#{public_issuer(host)}/protocol/saml"

with {:ok, parsed} <- parser.(descriptor),
     candidate <- Import.build_candidate(parsed),
     true <- candidate.idp_entity_id == public_issuer(host),
     true <- candidate.idp_sso_url == expected_sso_url do
  {:ok, candidate}
else
  false -> {:error, {:parse, :unexpected_public_descriptor_endpoint}}
  {:error, reason} -> {:error, {:parse, reason}}
end
```

### CR-02: Diagnostics destination validation permits arbitrary recursive deletion

**Classification:** BLOCKER

**File:** `scripts/test_keycloak_proxy_e2e.sh:117`

**Issue:** `KEYCLOAK_PROXY_ARTIFACT_DIR` is accepted when its basename merely starts with `keycloak-proxy-diagnostics-`; it may be an absolute path or contain traversal components. Both `promote_diagnostics` and `discard_diagnostics` then execute `rm -rf -- "$destination"` (lines 188 and 195). A typo or externally supplied environment can therefore erase an existing arbitrary directory such as `/important/keycloak-proxy-diagnostics-old`.

**Fix:** Constrain the resolved artifact destination to a dedicated, repository-owned parent directory (or an explicitly created temporary parent), reject absolute/traversal paths and symlinks, and delete only a directory created and ownership-marked by this invocation.

## Warnings

### WR-01: Provisioned connection does not use the required stable record UUID

**Classification:** WARNING

**File:** `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex:130`

**Issue:** The phase contract specifies stable connection record UUID `abababab-7070-4700-8700-ababababab70`, but the creation attributes contain only the public `connection_id`. `Relyra.Ecto.Connection` auto-generates its binary primary key, so each clean provisioning receives a random internal record ID instead of the required stable one. This makes the declared deterministic connection identity and audit reference contract untrue.

**Fix:** Pass the specified `:id` in the create attributes (and add an assertion for it in the provisioning test), assuming the schema permits caller-supplied binary IDs:

```elixir
attrs = %{
  id: "abababab-7070-4700-8700-ababababab70",
  connection_id: @connection_id,
  # ...
}
```

---

_Reviewed: 2026-08-26T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
