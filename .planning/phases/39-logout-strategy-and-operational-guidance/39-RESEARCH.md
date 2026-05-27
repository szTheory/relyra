<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Actively demote front-channel SLO. Treat as a best-effort legacy protocol, not a secure boundary.
- **D-02:** Document exactly why it fails (ITP, ETP, 3rd-party cookie blocking). Developers need this specific vocabulary to push back on rigid enterprise compliance checklists. 
- **D-03:** Mandate **Ecto-backed (server-side) sessions** if SLO is enabled.
- **D-04:** Explicitly warn that stateless Plug cookies cannot be revoked reliably via back-channel or cookie-stripped front-channel SLO.
- **D-05:** Emphasize using `Relyra.SessionAdapter.index_session/4` and `terminate_by_session_index/4` to map the SAML `SessionIndex` to a Postgres session record.
- **D-06:** Establish **absolute session timeouts** (e.g., 8-12 hours) and idle timeouts (e.g., 30 mins) as the true security boundary against orphaned sessions.
- **D-07:** Discourage reliance on background heartbeats or IdP polling due to SAML's lack of a standard `/userinfo` endpoint.

### the agent's Discretion
None explicitly listed.

### Deferred Ideas (OUT OF SCOPE)
None explicitly listed.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-04 | Publish `guides/recipes/logout.md` detailing when to enable SLO, session-model implications, 3rd-party cookie caveats, and absolute-timeout fallbacks. | Explains why front-channel and back-channel SLO both require Ecto-backed sessions due to ITP/ETP and provides operational configuration boundaries (timeouts). |
</phase_requirements>

# Phase 39: Logout Strategy & Operational Guidance - Research

**Researched:** 2026-05-27
**Domain:** SAML Single Logout (SLO), Session Management, Web Privacy (ITP/ETP)
**Confidence:** HIGH

## Summary
SAML Single Logout (SLO) is often mandated by enterprise compliance checklists, but in modern browsers, front-channel SLO is structurally unreliable. Apple's Intelligent Tracking Prevention (ITP), Firefox's Enhanced Tracking Protection (ETP), and Google's Privacy Sandbox actively block the third-party cookies required to terminate a user's session when logout is initiated by the Identity Provider (IdP) or another Service Provider (SP). Because the browser drops the session cookie during cross-origin iframes or redirects, a standard stateless `Plug.Session` cannot identify which user to log out. 

To support SLO in any capacity, Relyra mandates stateful, server-backed sessions (e.g., Ecto/Postgres). The host application must map the SAML `SessionIndex` to a durable server-side session using `Relyra.SessionAdapter.index_session/4`. This allows back-channel SLO (server-to-server) to terminate the correct session. Even with stateful sessions, SLO remains a best-effort cleanup mechanism. The true security boundary against orphaned sessions must be absolute session timeouts (e.g., 8-12 hours) and idle timeouts (e.g., 30 mins).

**Primary recommendation:** Draft `guides/recipes/logout.md` focusing on absolute timeouts as the primary boundary and Ecto-backed sessions as the mandatory prerequisite for SLO, demoting front-channel SLO as a legacy best-effort mechanism.

## Architectural Responsibility Map
| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stateless Cookie Tracking | Browser / Client | Frontend Server (SSR) | Cannot be revoked remotely due to ITP/ETP. Unsuitable for SLO. |
| Session Expiry & Timeouts | API / Backend | Database / Storage | Absolute boundaries must be enforced on the server to mitigate orphaned sessions when SLO fails. |
| SAML SessionIndex Mapping | Database / Storage | API / Backend | Required to connect an IdP `SessionIndex` string to a specific server-side session record. |
| Back-Channel SLO | API / Backend | Database / Storage | Server-to-server HTTP request bypasses browser tracking protections. |

## Standard Stack
### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix Plug.Session | Any | Core session abstraction | Built into Phoenix |
| Ecto / Postgres | Any | Server-side session storage | Required for mapping `SessionIndex` to allow remote revocation |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Ecto | ETS | Faster, but volatile and cluster-unsafe without external sync (e.g., Redis). ETS is okay for single-node but bad for multi-node deployments. |
| Ecto | Stateless Cookies | The default for Plug, but fundamentally incompatible with reliable SLO since back-channel calls cannot instruct the browser to drop the cookie. |

## Architecture Patterns
### System Architecture Diagram

```
[User Browser] --(Front-Channel SLO Redirect)--> [IdP] --(Cross-origin iframe/redirect)--> [SP (Relyra)]
   ^                                                                                       |
   |                                                                                       |
   +-- (SP cannot read session cookie due to ITP/ETP) <------------------------------------+

[IdP Server] --(Back-Channel SLO POST)--> [SP Server (Relyra)]
                                                |
                                                v
                                  [Relyra.SessionAdapter]
                                                |
                                                v
                          [Lookup by SAML SessionIndex in Postgres/Ecto]
                                                |
                                                v
                          [Invalidate server-side session record]
```

### Pattern 1: Session Index Mapping
**What:** Mapping the SAML `SessionIndex` to a backend session during login.
**When to use:** Whenever SLO is configured.
**Example:**
```elixir
defmodule MyApp.Auth.SessionAdapter do
  @behaviour Relyra.SessionAdapter

  def index_session(session_index, _issuer, context, _opts) do
    # Map the session_index to your Ecto session record
    MyApp.Auth.update_session_index(context.session_id, session_index)
    {:ok, :indexed}
  end

  def terminate_by_session_index(session_index, _issuer, _context, _opts) do
    # Revoke the session by looking up the session_index
    MyApp.Auth.delete_session_by_index(session_index)
    {:ok, :terminated}
  end
end
```

### Anti-Patterns to Avoid
- **Stateless Cookies with SLO:** Using `Plug.Session.COOKIE` alongside SLO. Back-channel SLO cannot manipulate the browser cookie, and front-channel SLO will fail due to partitioned storage or 3rd-party cookie blocking.
- **Relying on SLO for Security:** Treating SLO as a guaranteed mechanism. It is brittle. Use absolute timeouts instead.
- **IdP Polling:** Periodically checking if the user is still active at the IdP. SAML lacks a standardized `/userinfo` endpoint like OIDC, making this non-viable.

## Don't Hand-Roll
| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SLO Resiliency | Custom IdP Polling | Absolute Timeouts | SAML does not define a standard status endpoint. Hand-rolling heartbeats is fragile and IdP-specific. |
| Cookie Syncing | 1st-Party Bounces | Server-side Sessions | Trying to bounce the user to a first-party context to bypass ITP/ETP is a cat-and-mouse game with browser vendors. Server-side sessions solve the root issue. |

## Common Pitfalls
### Pitfall 1: The "Compliance Checklist" Trap
**What goes wrong:** Enterprise customers demand front-channel SLO to satisfy a security audit, but it fails silently in production.
**Why it happens:** The auditor's checklist is based on 2014-era web architecture, ignoring modern ITP/ETP which blocks the 3rd-party cookies required for cross-origin logouts.
**How to avoid:** Educate customers using the exact vocabulary ("ITP", "ETP", "Privacy Sandbox"). Offer absolute timeouts + back-channel SLO as the modern, secure alternative.
**Warning signs:** Logouts work in Chrome Incognito but fail in Safari or Firefox.

### Pitfall 2: Back-Channel Logout with Stateless Sessions
**What goes wrong:** The IdP sends a valid back-channel SLO request, Relyra parses it successfully, but the user remains logged in.
**Why it happens:** The host application uses stateless, signed Plug cookies. The server receives the SLO request but has no database record to invalidate, and it cannot reach into the user's browser to delete the cookie.
**How to avoid:** Mandate `Relyra.SessionAdapter` with a database-backed session store (e.g., Postgres) when enabling SLO.

## State of the Art
| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Front-Channel HTTP-Redirect | Back-Channel SOAP/POST | ~2020 (ITP/ETP rollout) | Front-channel logouts in iframes became unreliable due to partitioned storage. |
| Stateless signed cookies | Server-side sessions (Ecto/Redis) | Modern SLO era | Server-side state is required for back-channel invalidation. |
| Infinite sessions + SLO | Absolute timeouts (8-12h) | Continuous | Security boundary shifted from "explicit logout" to "time-bounded access". |

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Mix (bash script checks) |
| Config file | mix.exs |
| Quick run command | `mix ci.docs` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-04 | Markdown parses and is tracked in project config | unit | `mix format --check-formatted guides/recipes/logout.md` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix format --check-formatted guides/recipes/logout.md`
- **Per wave merge:** `mix ci.docs`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `mix.exs` — Need to append `"guides/recipes/logout.md"` to the `docs` function's `extras` list
- [ ] `mix.exs` — Need to append `"cmd test -f guides/recipes/logout.md"` to the `ci.docs` alias

## Sources
### Primary (HIGH confidence)
- `39-CONTEXT.md` - Explicit decisions and locked constraints.
- `lib/relyra/session_adapter.ex` - Verified behaviour API (`index_session/4`, `terminate_by_session_index/4`).
- Web Security documentation (MDN, WebKit Tracking Prevention Policy) - Confirming ITP/ETP behavior against third-party cookies.

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - Dictated by Context and Phoenix ecosystem realities.
- Architecture: HIGH - Verified via Context requirements and `lib/relyra/session_adapter.ex`.
- Pitfalls: HIGH - Well-documented browser security mechanics (ITP/ETP) matching `39-CONTEXT.md` directives.

**Research date:** 2026-05-27
**Valid until:** 2027-05-27 (Until next major browser storage architecture change)