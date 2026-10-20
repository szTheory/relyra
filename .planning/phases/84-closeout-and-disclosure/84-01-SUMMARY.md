---
phase: 84-closeout-and-disclosure
plan: 01
status: published-cve-assignment-pending
requirements: [DISC-01]
commit: TBD
---

# Phase 84 Summary: Close-out and scripted disclosure

## Disclosure update — 2026-10-20

The user approved disclosure after Hex 1.10.2 shipped. GitHub advisory
[GHSA-5rj3-pwg2-fr8x](https://github.com/szTheory/relyra/security/advisories/GHSA-5rj3-pwg2-fr8x)
was published at `2026-10-20T20:04:53Z`. Its CVE request returned HTTP 202
Accepted; `cve_id` remains null. Confirmed affected range: `>= 1.2.0, < 1.10.2`;
first patched: `1.10.2`; CVSS 9.1; CWE-347 and CWE-287. The repository advisory,
findings ledger, and milestone evidence now carry the GHSA and pending request
status. A final assigned-CVE backfill remains open.

Milestone archive readiness is recorded in `.planning/v1.12-MILESTONE-AUDIT.md`.
The earlier local-only summary below is historical and superseded by this update.

**Local close-out complete; remote disclosure held for explicit approval.**

## Done (local)

- `.planning/milestones/v1.12-HARDENING.md` — the single milestone evidence file:
  the full seam inventory (S1–S20) mapped to fixed-in commits (`2782344`,
  `32ae5e6`), the Phase 82 property rounds (~4,800 cases, no code defect; two
  oracle-model corrections), the Phase 83 mutation-score trend (79.4% → 81.1% →
  82.8% on `algorithm_policy.ex`, plateau), and the recorded residual risk. One
  evidence contract, no new receipt chains.
- `docs/advisories/2026-002-signed-node-not-bound-to-consumed-node.md` — advisory
  draft in the RELYRA-2026-001 shape. Class: XML Signature Wrapping (the
  signature verified, but not over the consumed node). Affected `>= 1.2.0, <
  1.10.2` (first-patched confirmed at release-please merge); CWE-347 primary,
  CWE-287 companion; CVSS 9.1. GHSA/CVE ids left `<pending>` for backfill at
  publication.
- `docs/security_findings.md` — RELYRA-2026-002 row added (Critical, resolved on
  `docs/v1.12-start`, regression proof = `trust_binding` + `adversarial_property`).

Verification: `mix qa`, `mix ci.security`, `mix format --check-formatted` exit 0;
the four doc-sensitive suites (markdown link smoke, evidence contract, milestone
scope, external canary — 175 tests) pass with the new docs in place.

## Held for explicit approval (remote / irreversible)

Per the user's instruction (option A), these are NOT performed in this session:

1. Push `docs/v1.12-start` and open the `fix(...)` PR(s) to `main` (merge
   commits); release-please cuts the patch release.
2. Request the GHSA + CVE via the repository-advisory REST API; backfill the ids
   and the first-patched version into the advisory and the ledger.

The milestone is complete locally. `/gsd-complete-milestone` and the disclosure
run proceed once the user approves the remote actions.
