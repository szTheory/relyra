# Phase 24: Single Logout (SLO) Architectural Research

Based on the architectural goals of Relyra, idiomatic Elixir/Plug patterns, and lessons learned from the broader SAML ecosystem, here are the finalized architectural decisions for Phase 24.

## 1. Session Revocation (IdP-Initiated Logout)

**Decision:** Add a `revoke_session(subject, session_index, context, opts)` callback to the `Relyra.SessionAdapter` behaviour.

When an IdP initiates a logout (either via front-channel redirect or back-channel SOAP/HTTP-Artifact), the Relyra library must instruct the host application to destroy the user's session.

### Rationale & Tradeoffs
* **Why not Telemetry?** In Elixir, `telemetry` is designed strictly for observability (metrics, tracing, logging). Using a fire-and-forget event for a **security-critical control flow** is a severe anti-pattern. If the host app fails to attach the handler or it crashes, the session remains active silently.
* **Cohesion:** `Relyra.SessionAdapter` already defines `establish_session/3`. Adding `revoke_session/4` creates a perfectly symmetrical, type-safe contract that explicitly forces the developer to handle session destruction.
* **The Stateless Cookie Caveat:** You must heavily document a core tradeoff: **If a host application uses SLO, it must use a stateful, server-side session store** (e.g., ETS, Redis, Ecto). Stateless `Plug.Session.COOKIE` cannot be revoked by a back-channel IdP request because the user's browser isn't present to receive the `Set-Cookie` deletion header.

## 2. Logout State Correlation (SP-Initiated Logout)

**Decision:** Reuse the existing `Relyra.RequestStore`.

When Relyra sends an SP-initiated `<LogoutRequest>`, it generates an ID. When the IdP responds with a `<LogoutResponse>`, it includes an `InResponseTo` attribute. We must prove we actually sent the request being responded to.

### Rationale & Tradeoffs
* **Why not the `ReplayStore`?** The `Relyra.ReplayStore` serves a fundamentally different purpose. It ensures "we have never seen this ID before". State correlation requires proving "we explicitly generated and sent this ID, and are waiting for it."
* **Developer Ergonomics (DX):** Creating a dedicated `LogoutStore` forces developers to implement yet another behaviour. By reusing `RequestStore`, you respect the developer's time and minimize the library's API surface area.
* **Implementation Detail:** Modify the `intent` map stored in the `RequestStore` to include a `type: :authn | :logout` field. This ensures a maliciously crafted LogoutResponse cannot be used to consume an AuthnRequest ID.

## 3. Logout Bindings Support

**Decision:** Support parsing both **HTTP-Redirect** and **HTTP-POST** for incoming messages, but default to **HTTP-Redirect** for sending outgoing `<LogoutRequest>` and `<LogoutResponse>` messages.

### Rationale & Tradeoffs
* **Payload Size:** Logout messages are tiny (usually just a `<NameID>` and a `<SessionIndex>`). They easily fit within standard URL length limits.
* **User Experience (UX):** HTTP-Redirect is vastly superior for SLO. HTTP-POST requires the server to render an intermediate HTML page containing a `<form>` and a JavaScript payload, which causes a visual flicker and is increasingly blocked by aggressive browser tracking protections (like Safari's ITP).
* **Flexibility:** While HTTP-Redirect is the best default, Relyra *must* support verifying incoming HTTP-POST logouts for enterprise IdPs that strictly enforce HTTP-POST for all SAML traffic.

## Action Items for Execution
1. **Extend `Relyra.SessionAdapter`** with `@callback revoke_session(subject, session_index, context, opts)` and update `Relyra.SessionAdapter.Default`.
2. **Update `Relyra.RequestStore`** to inject a `:type` identifier into the intent payload.
3. **Implement SLO Binding Parsers** capable of decoding both HTTP-Redirect and HTTP-POST messages.
