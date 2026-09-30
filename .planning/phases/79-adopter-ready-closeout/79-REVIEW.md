---
phase: 79-adopter-ready-closeout
reviewed: 2026-09-30T02:49:07Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - scripts/collect_phase79_inventory.py
  - test/governance/milestone_scope_test.exs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 79: Code Review Report

**Reviewed:** 2026-09-30T02:49:07Z  
**Depth:** standard  
**Files Reviewed:** 2  
**Status:** issues_found

## Summary

The inventory collector is read-only and filters remote fields, but its lane classifier can treat evidence as belonging to a mandatory lane without proving that the evidence came from that lane's declared workflow. It can also label a non-GitHub origin as a GitHub repository and claim complete status collection after reading only one page. The fixture suite does not exercise these boundaries.

## Critical Issues

### CR-01: Unowned or aggregate workflow evidence can mark mandatory lanes passed

**File:** `scripts/collect_phase79_inventory.py:353-364`
**Issue:** `classify_lane` accepts any check run or commit status with the expected display name and SHA, without tying it to the lane's `owners`. If no such record exists, it accepts any completed run from an owner workflow path and classifies that workflow-level result as the lane result. Consequently, a same-named check from a different workflow can satisfy a mandatory lane, and one successful `security-gates.yml` run can stand in for every absent lane even when an individual lane was skipped or did not emit evidence. `build_receipt` then allows these results to support a complete green inventory. The fixture at `test/governance/milestone_scope_test.exs:3106-3109` gives every lane a successful same-named check with no owner provenance, so it codifies rather than detects this gap.
**Fix:** Only classify a lane as passed when its individual check is linked to a run of the declared owner workflow and the check itself completed successfully. Preserve workflow ID/run ID or check-suite linkage in the collected evidence and verify that relationship. Remove the workflow-level fallback unless it can establish that the particular lane ran. Add fixtures with a colliding successful check from a non-owner workflow, and with a successful aggregate workflow run where the target lane is absent/skipped; both must leave the lane unknown or absent.

## Warnings

### WR-01: A non-GitHub origin is silently treated as a GitHub repository

**File:** `scripts/collect_phase79_inventory.py:269-277, 508-514`
**Issue:** `repository_from_remote` extracts only the path from HTTPS remotes and accepts any SSH host. `build_receipt` validates only the resulting `owner/repo` shape before querying `gh api`, so an origin such as `https://gitlab.example/szTheory/relyra.git` is recorded as `szTheory/relyra` and paired with GitHub's data for that name. A closeout receipt can therefore claim evidence for a repository other than the configured origin.
**Fix:** Parse and validate the remote host together with the repository path. Accept only configured GitHub hosts (including an explicit enterprise-host allowlist if needed); otherwise stop with an identity error. Add fixtures for a non-GitHub HTTPS remote and an unapproved SSH host.

### WR-02: Commit statuses are marked complete without following pagination

**File:** `scripts/collect_phase79_inventory.py:308-310, 531-535`
**Issue:** The statuses source uses `raw_single`, which discards the `has_next` value returned by `gh_read`, and unconditionally records one page with `completeness: complete`. If GitHub returns a continuation link, the receipt omits later status records while asserting that source collection is complete. This makes the source-provenance completeness claim unreliable and can hide additional status observations relevant to the closeout.
**Fix:** Collect status pages through the same bounded pagination path as the other list endpoints, preserving and validating each page and total count. If the endpoint cannot be paginated, mark the source incomplete whenever a continuation link is present. Add a fixture with a later statuses page and assert both its evidence and page provenance are retained.

---

_Reviewed: 2026-09-30T02:49:07Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
