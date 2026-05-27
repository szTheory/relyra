# Phase 39: Logout Strategy & Operational Guidance - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish `guides/recipes/logout.md` detailing when to enable SAML Single Logout (SLO), session-model implications, 3rd-party cookie caveats, and absolute-timeout fallbacks. The document should equip Elixir developers with the hard truths about modern browser storage partitioning (Safari ITP, Firefox ETP, Chrome Privacy Sandbox) so they can push back on misinformed compliance demands, while providing a bulletproof, server-side fallback architecture (Ecto-backed sessions + short timeouts) for when SLO must be enabled.

**Requirements:** DOCS-04.

**In scope:** A comprehensive, authoritative markdown guide (`guides/recipes/logout.md`).
**NOT in scope:** Code changes to the SLO implementation itself (completed in Phase 38).
</domain>

<decisions>
## Implementation Decisions

### Tone & Posture
- **D-01:** Actively demote front-channel SLO. Treat as a best-effort legacy protocol, not a secure boundary.
- **D-02:** Document exactly why it fails (ITP, ETP, 3rd-party cookie blocking). Developers need this specific vocabulary to push back on rigid enterprise compliance checklists. 

### Session Storage
- **D-03:** Mandate **Ecto-backed (server-side) sessions** if SLO is enabled.
- **D-04:** Explicitly warn that stateless Plug cookies cannot be revoked reliably via back-channel or cookie-stripped front-channel SLO.
- **D-05:** Emphasize using `Relyra.SessionAdapter.index_session/4` and `terminate_by_session_index/4` to map the SAML `SessionIndex` to a Postgres session record.

### Failure Fallbacks
- **D-06:** Establish **absolute session timeouts** (e.g., 8-12 hours) and idle timeouts (e.g., 30 mins) as the true security boundary against orphaned sessions.
- **D-07:** Discourage reliance on background heartbeats or IdP polling due to SAML's lack of a standard `/userinfo` endpoint.
</decisions>

<canonical_refs>
## Canonical References
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` (System Design Best Practices - "Durable truth in Postgres")
- `prompts/elixir-saml-lib-deep-research.md` (SAML Ecosystem Best Practices)
</canonical_refs>
