# API Coverage — GitHub read-only closeout inventory

> Full coverage by default within the Phase 79 inventory need. Opt-outs are explicit, reasoned decisions. This matrix covers the repository's GitHub REST/`gh api` observation surface; it does not claim coverage of the entire GitHub API.

The collector in `79-01-PLAN.md` must read only allowlisted metadata, follow every page for list endpoints, bind check and run observations to the captured protected `main` SHA, and expose access or completeness failures. `79-02-PLAN.md` may use those observations to draft a separate exact mutation proposal; this matrix grants no write authority.

| capability | decision | reason |
|---|---|---|
| Repository identity and authenticated read target | INTEGRATE | |
| Current `main` ref and commit SHA | INTEGRATE | |
| Pull request inventory with number, state, base/head refs, and URL | INTEGRATE | |
| Issue inventory excluding pull-request-shaped issue records | INTEGRATE | |
| Remote branch inventory and protected state | INTEGRATE | |
| Workflow catalog `state` field, normalized as active or disabled | INTEGRATE | |
| Workflow run inventory with event, status, conclusion, ref, SHA, time, and URL | INTEGRATE | |
| Current-main check-run names, status, conclusion, and head SHA | INTEGRATE | |
| Current-main commit-status contexts and combined status | INTEGRATE | |
| `main` branch-protection read and required check contexts | INTEGRATE | |
| List-endpoint pagination and completeness accounting | INTEGRATE | |
| Read-denied, missing-resource, rate-limit, and other API error states | INTEGRATE | |
| Pull request review bodies, comments, files, and diffs | OPT-OUT | The closeout needs collaboration state and identifiers; review content and diffs add sensitive data without informing this inventory. |
| Pull request merge, close, label, or comment operations | OPT-OUT | D-01 and REPO-03 require a separately approved exact batch before any remote mutation. |
| Issue bodies, comments, assignees, and full label metadata | OPT-OUT | Issue identifiers, state, and bounded labels suffice to identify current work; full content is outside the inventory's redaction budget. |
| Issue create, close, label, or comment operations | OPT-OUT | A new exact plan and explicit approval are required for each proposed remote change. |
| Branch creation, force update, or deletion | OPT-OUT | Branch inventory is read-only; ref mutation would cross the explicit remote approval boundary. |
| Workflow dispatch, cancellation, rerun, enable, or disable | OPT-OUT | Workflow health is observed only; running or changing workflows requires its own authorization and can change shared state. |
| Workflow logs, artifacts, job steps, and annotations | OPT-OUT | Run status and bounded URLs are enough for the closeout; detailed logs may contain secrets or unrelated payloads. |
| Branch-protection update and ruleset administration | OPT-OUT | The collector compares live protection with the repository-owned expected-state printer; applying changes requires a separate exact approved batch. |
| Repository secrets, variables, collaborators, and permissions administration | OPT-OUT | These administration surfaces are outside the Phase 79 inventory and may expose sensitive governance data. |
| Release, package, and tag publishing endpoints | OPT-OUT | Phase 79 is a repository closeout; release publishing follows existing automation, and AGENTS.md prohibits manual Hex publishing. |

## Evidence and ownership

`79-INVENTORY.json` records the endpoint/source, UTC time, repository, ref, observed main SHA, page completeness, and access state for every integrated read. `test/governance/milestone_scope_test.exs` supplies deterministic fixtures in the mandatory `mix ci.evidence` lane. Live GitHub values are refreshed during Phase 79 execution; historical Phase 73 values are leads only. A proposed remote write remains inert until an exact plan receives explicit approval, immediate same-target preflight, and automated read-back.
