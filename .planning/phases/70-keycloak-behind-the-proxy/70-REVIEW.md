---
phase: 70-keycloak-behind-the-proxy
reviewed: 2026-08-26T21:20:12Z
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
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 70: Code Review Report

**Reviewed:** 2026-08-26T21:20:12Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The optional Keycloak profile, Basic-auth admin boundary, and diagnostics harness were reviewed with the host mapping and artifact-retention paths traced into their called Ecto and shell helpers. Two blocker-level defects remain: reprovisioning does not verify that Sarah's existing external identity belongs to Sarah's LedgerLoop user, and an environment-controlled diagnostics destination can delete an unrelated directory.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Reprovisioning can retain an identity mapped to the wrong user

**File:** `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex:98-106`

**Classification:** BLOCKER

**Issue:** The unchanged shortcut treats any `SAMLIdentity` with Sarah's issuer and subject as valid; it never checks `identity.user_id`. `ensure_sarah_identity/4` also treats that existing row as success at lines 249-263. If the row is associated with a different LedgerLoop user (for example, after a bad prior mapping or data repair), an unchanged descriptor returns `{:ok, :unchanged}` and the connection remains enabled. A real Keycloak assertion for Sarah will then establish a receipt for the other user. This violates the phase's required Sarah identity mapping and is an authentication/account-assignment vulnerability.

**Fix:** Resolve the canonical Sarah user before the unchanged check and require the identity's `user_id` to match it; reject or repair a mismatched mapping inside the same audited transaction. Add a regression that seeds the same issuer/subject for another user and asserts provisioning does not return unchanged or enable the connection.

```elixir
user = Repo.get_by!(User, email: @sarah_email)

identity_matches? =
  Repo.exists?(
    from identity in SAMLIdentity,
      where:
        identity.subject == ^@sarah_email and
          identity.issuer == ^public_issuer(host) and
          identity.user_id == ^user.id
  )
```

### CR-02: Diagnostic cleanup accepts arbitrary directories and recursively deletes them

**File:** `scripts/test_keycloak_proxy_e2e.sh:9, 101-107, 215, 222-234`

**Classification:** BLOCKER

**Issue:** `KEYCLOAK_PROXY_ARTIFACT_DIR` is accepted as a full path. The only validation is that `basename` starts with `keycloak-proxy-diagnostics-`; it does not require the directory to be below `playwright-report` or another harness-owned root. On any failed run, `discard_diagnostics/2` and `promote_diagnostics/2` execute `rm -rf -- "$destination"`. Thus a value such as `/path/to/valuable/keycloak-proxy-diagnostics-backup` passes the guard and is deleted. This defeats the script's stated owned-artifact safety boundary and creates an avoidable data-loss path in CI or shell wrappers that forward environment variables.

**Fix:** Derive the destination from an immutable, repository-owned base directory and allow only a validated leaf name/project token. Canonicalize the parent and reject destinations whose canonical parent is not exactly that base before every deletion or move.

```bash
ARTIFACT_ROOT="$ROOT_DIR/playwright-report"
ARTIFACT_NAME="keycloak-proxy-diagnostics-${PROJECT_NAME}"
[[ "$ARTIFACT_NAME" =~ ^keycloak-proxy-diagnostics-[A-Za-z0-9_-]+$ ]] || exit 1
ARTIFACT_DIR="$ARTIFACT_ROOT/$ARTIFACT_NAME"

# In diagnostic_artifact_dir_is_safe:
[[ "$(dirname "$candidate")" == "$ARTIFACT_ROOT" ]] || return 1
```

---

_Reviewed: 2026-08-26T21:20:12Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
