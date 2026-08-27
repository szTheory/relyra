---
phase: 72-documentation
reviewed: 2026-08-27T18:06:14Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - Makefile
  - README.md
  - demo/ledger_loop/README.md
  - guides/demo.md
  - guides/docker_dev_dx.md
  - test/docs/demo_guide_drift_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 72: Code Review Report

**Reviewed:** 2026-08-27T18:06:14Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The Docker-evaluation routing and ownership language are broadly consistent, and the focused docs and Markdown-link suites pass. However, the advertised `PORT` recovery path is internally inconsistent: Compose honors the override while `doctor` and the primary instructions continue to inspect and direct readers to port 4000. The test helper also cannot correctly verify ordered repeated text, so its drift checks can produce false failures as the documentation evolves.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `PORT` override is diagnosed and documented as the wrong port

**File:** `/Users/jon/projects/relyra/Makefile:194-215` (also `/Users/jon/projects/relyra/guides/docker_dev_dx.md:44-55` and `/Users/jon/projects/relyra/demo/ledger_loop/README.md:49`)

**Issue:** The Solo Compose overlay maps `127.0.0.1:${PORT:-4000}:4000`, so `PORT=4101 make up-build` correctly starts the demo at 4101. But `make doctor PORT=4101` still probes literal `4000` (`check_port 4000`) and its recovery message advertises the override that it cannot validate. A busy 4000 therefore leaves `doctor` failing after the documented recovery has been applied; it also reports an overridden busy demo port as port 8080 because its classification is hard-coded. Both guides then instruct readers to open `http://localhost:4000`, not the selected port. This breaks the documented port-conflict recovery and can send a user to an unrelated listener.

**Fix:** Pass the exported `PORT` to the port check and classify the checks by role rather than by a literal. Cover the override in the launcher fixture, then have the guides tell overridden users to run `make url` (with the same `PORT`) and use its emitted loopback URL. For example:

```make
# doctor recipe
check_port "$${PORT}" demo
check_port 5432 postgres
check_port 8080 proxy
```

Have `check_port` print `WARN port %s occupied ... set PORT=<free-port>` for the `demo` role, and keep the proxy-specific remediation only for the `proxy` role. Add a fixture assertion that `PORT=4101 make doctor` probes 4101 and never probes 4000.

## Warnings

### WR-01: Ordered-text assertion always searches from the beginning

**File:** `/Users/jon/projects/relyra/test/docs/demo_guide_drift_test.exs:838-850`

**Issue:** `assert_in_order/2` calls `:binary.match(text, token)` without a search offset for every token. When a later required token appears once before the prior token and again in the intended location, the helper only sees the first occurrence and fails even though the documented order is correct. The new guide assertions rely on this helper for repeated operational words and headings, making the documentation gate brittle as valid prose is expanded.

**Fix:** Search each token within the suffix beginning immediately after the previous match, and carry the end offset forward. For example, call `:binary.match/3` with `scope: {offset, byte_size(text) - offset}`, then set `offset` to `index + matched_length`. Add a unit case with a repeated token before and after the preceding token to prove the helper selects the later valid occurrence.

---

_Reviewed: 2026-08-27T18:06:14Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
