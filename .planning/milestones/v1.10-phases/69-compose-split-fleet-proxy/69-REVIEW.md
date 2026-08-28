---
phase: 69-compose-split-fleet-proxy
reviewed: 2026-08-26T14:16:59Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - docker-compose.yml
  - docker-compose.override.yml
  - docker-compose.proxy.yml
  - docker/traefik/compose.yml
  - demo/ledger_loop/config/runtime.exs
  - demo/ledger_loop/config/dev.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 69: Code Review Report

**Reviewed:** 2026-08-26T14:16:59Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The solo and explicit fleet Compose graphs render with the intended port and network boundaries: PostgreSQL has no host binding, the solo app binding is loopback-only, and fleet mode attaches only `demo_app` to the external proxy network. The fleet hostname override does not update Phoenix's allowed WebSocket origins, however, so its documented override path breaks LiveView connections.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: `RELYRA_HOST` override is rejected by the LiveView origin policy

**File:** `/Users/jon/projects/relyra/docker-compose.proxy.yml:7`
**Issue:** `RELYRA_HOST` controls both `PHX_HOST` and the Traefik router rule, but the default `DEMO_CHECK_ORIGINS` value remains hard-coded to `relyra.localhost`. For example, rendering with `RELYRA_HOST=alternate.localhost` routes `Host(\`alternate.localhost\`)` and configures `PHX_HOST=alternate.localhost`, while passing only `//localhost,//relyra.localhost,//*.relyra.localhost` to Phoenix. The browser's `Origin: http://alternate.localhost` then fails `check_origin`, so the LiveView WebSocket cannot connect. This makes the documented `RELYRA_HOST` override hook non-functional in fleet mode.

**Fix:** Build the proxy default origin list from the same override used by the route, while retaining an explicit operator override. For example:

```yaml
DEMO_CHECK_ORIGINS: ${DEMO_CHECK_ORIGINS:-//localhost,//${RELYRA_HOST:-relyra.localhost},//*.relyra.localhost}
```

Then add a rendered-Compose/runtime assertion with a non-default `RELYRA_HOST` that verifies the resulting `check_origin` list includes that hostname.

---

_Reviewed: 2026-08-26T14:16:59Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
