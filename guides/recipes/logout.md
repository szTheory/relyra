# Logout Strategy And Operational Guidance

This guide is the operator-facing reference for SAML Single Logout (SLO). Use it
to understand the architectural realities of front-channel logout, configure
stateful sessions correctly, and establish reliable security boundaries when
cross-origin cookie deletion inevitably fails.

## Overview

SAML Single Logout (SLO) is structurally unreliable in modern browsers. The
protocol was designed in an era where cross-origin third-party cookies were
freely exchanged via hidden iframes and redirect chains. Today, browser privacy
protections block these mechanics by default.

Treat front-channel SLO as a best-effort user experience feature, not a
security boundary. If your compliance framework requires "guaranteed session
termination on IdP logout," you cannot satisfy it with SAML front-channel
SLO alone.

This guide provides the exact vocabulary to push back on rigid compliance
checklists and establishes the mandatory fallbacks required to actually secure
your application's sessions.

## Relyra owns / Host owns

## Relyra owns

- Processing incoming `LogoutRequest` and `LogoutResponse` payloads.
- Validating signatures on logout messages to prevent denial-of-service via
  unauthenticated session termination.
- Emitting the `SessionIndex` (if provided by the IdP) to your adapter.
- Providing the `Relyra.SessionAdapter` behaviour seam for your host app to
  manage session lifecycle.

## Host owns

- Choosing the session storage mechanism (must be stateful/durable).
- Mapping the SAML `SessionIndex` to the local durable session.
- Terminating the local session when Relyra signals a valid logout request.
- Enforcing absolute and idle session timeouts as the true security boundary.
- Explaining front-channel limitations to security auditors.

## 1. The Compliance Trap

Auditors often expect that clicking "Logout" in a central Identity Provider (IdP)
will synchronously and reliably terminate the user's session in all connected
Service Providers (SPs).

In SAML front-channel SLO, this works by the IdP embedding hidden iframes or
triggering redirect chains to the SP's logout endpoints. The SP receives the
request, reads its local session cookie, and deletes the session.

This fails in modern browsers because it relies on third-party cookies in a
cross-origin context:

- **Safari ITP (Intelligent Tracking Prevention):** Blocks third-party cookies
  by default. An iframe from the IdP cannot send the SP's session cookie to the
  SP's logout endpoint.
- **Firefox ETP (Enhanced Tracking Protection):** Blocks cross-site tracking
  cookies, frequently interfering with SLO redirect chains.
- **Chrome Privacy Sandbox:** Phases out third-party cookies, breaking
  cross-origin session termination iframes.

When these mechanisms block the cookie, the SP receives a valid `LogoutRequest`
but cannot identify *which* local session to terminate, because the browser
refused to attach the session cookie to the request. The logout silently fails,
and the SP session remains active.

Equip your developers with this vocabulary (ITP, ETP, Privacy Sandbox). Front-channel
SLO is fundamentally broken by modern browser privacy controls. It is not an
implementation flaw in Relyra or your application; it is a permanent architectural
reality of the web platform.

## 2. Mandatory Stateful Sessions

Because front-channel requests may arrive without a session cookie, you cannot
rely on cookie-deletion alone to terminate a session. You must be able to
terminate a session by its SAML `SessionIndex` from a server-side store.

**Stateless sessions (e.g., standard encrypted Plug cookies) cannot be revoked
reliably during SLO.** If the `LogoutRequest` arrives without the cookie, the
server has no way to invalidate the stateless token sitting in the user's browser.

If you enable SLO, you **must** use a stateful, durable session store (e.g.,
PostgreSQL via Ecto, or Redis). When a valid `LogoutRequest` arrives containing a
`SessionIndex`, your server must look up the corresponding local session in the
database and mark it as deleted or expired. The next time the user's browser
sends the (still present) cookie, the server-side check will fail, and the user
will be logged out.

## 3. Session Index Mapping

To connect SAML SLO to your stateful sessions, implement the `Relyra.SessionAdapter`
behaviour. Specifically, you must implement `index_session/4` and
`terminate_by_session_index/4`.

When a user logs in, the IdP may provide a `SessionIndex` in the `AuthnStatement`.
Relyra extracts this and passes it to your adapter.

```elixir
defmodule MyApp.Relyra.SessionAdapter do
  @behaviour Relyra.SessionAdapter

  alias MyApp.Accounts.SessionStore

  @impl true
  def index_session(connection, login_result, local_session_id, opts) do
    # Store the mapping between the SAML SessionIndex and your local session ID
    if session_index = login_result.principal.session_index do
      SessionStore.map_saml_index(
        connection.connection_id,
        session_index,
        local_session_id
      )
    end
    
    :ok
  end

  @impl true
  def terminate_by_session_index(connection, session_index, _name_id, _opts) do
    # The IdP has requested logout. Terminate the local session by the index.
    SessionStore.delete_by_saml_index(connection.connection_id, session_index)
    :ok
  end
end
```

By linking the `SessionIndex` to your durable session record, you bypass the
need for the browser to send the session cookie during the `LogoutRequest`. The
termination happens entirely server-side.

## 4. The Real Security Boundary

Because you cannot guarantee that an IdP logout will successfully reach your SP
(due to network failures, closed laptops, or browser cookie blocking), SLO
can never be your primary security boundary.

**Your primary security boundary must be absolute and idle session timeouts.**

- **Absolute Timeout (e.g., 8-12 hours):** The session must cryptographically or
  durably expire after a fixed duration, regardless of user activity. This forces
  a fresh authentication through the IdP daily.
- **Idle Timeout (e.g., 30 minutes):** The session should expire if the user has
  not interacted with the application recently.

Do not attempt to build "IdP polling" (where your SP periodically pings the IdP
to ask if the user is still active). This is inefficient, brittle, and introduces
unnecessary coupling.

Rely on your local timeouts. If the IdP terminates the session early and SLO
works, excellent. If SLO fails due to ITP/ETP, your absolute timeout guarantees
the session dies anyway. Document this dual-layer approach for your auditors:
SLO is the optimization; local timeouts are the guarantee.
