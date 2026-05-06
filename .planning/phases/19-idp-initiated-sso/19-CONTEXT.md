# Phase 19: IdP-Initiated SSO

**Milestone:** v0.4 — IdP-initiated SSO
**Goal:** Implement IdP-initiated SSO and opaque RelayState handling securely without compromising Relyra's strict-by-default posture.

## Architectural Decisions & Recommendations

Based on a deep architectural research pass of the Elixir/Phoenix ecosystem, lessons learned from other languages (like `passport-saml`, `ruby-saml`), and Relyra's foundational "fail-closed" security posture, the following decisions form the architecture for Phase 19.

### 1. Connection Resolution: Path-Based Routing
**Decision:** Require the host application to provide an explicit endpoint (e.g., `POST /sso/acs/:connection_id`) and pass the resolved connection context to Relyra. Relyra will **not** parse unverified XML to extract the `<Issuer>` for connection lookup.

**Rationale:**
*   **Highly Secure:** We avoid parsing unverified, unsigned XML payloads to determine the validation context (a classic XML Signature Wrapping vector). The validation context is determined deterministically by the transport layer (HTTP path).
*   **Deterministic:** Solves the multi-tenant "shared IdP" problem where multiple connections might use the exact same `idp_entity_id`.
*   **Idiomatic:** Keeps `Relyra.ConnectionResolver` simple and unchanged. Modern IdPs (Entra, Okta, Google Workspace) handle dynamic ACS URLs effortlessly.

### 2. Strictness: Connection-Level Opt-In (`allow_idp_initiated`)
**Decision:** Add a new boolean field `allow_idp_initiated` (default: `false`) to the `Relyra.Connection` schema. IdP-initiated flows (responses without `InResponseTo`) will be rejected by default.

**Rationale:**
*   **Fail-Closed Posture:** IdP-initiated flows inherently lack CSRF protection (Login CSRF). They must be a deliberate, explicit choice by the adopter for a specific connection.
*   **Great DX:** If an IdP-initiated flow fails because the flag is off, Relyra will return a clear `Relyra.Error` indicating that the flow was rejected and that `allow_idp_initiated: true` must be set.

### 3. RelayState Handling: Safe Exfiltration, No Automatic Redirects
**Decision:** Relyra will extract the opaque `RelayState` and pass it back to the host application on the `Relyra.LoginResult` struct. Relyra will **not** perform HTTP redirects itself, but will ship a utility function (`Relyra.Security.safe_local_redirect/2`) to help developers safely validate RelayState paths.

**Rationale:**
*   **Mitigates Open Redirects:** RelayState comes from the IdP (outside the signed XML) and is trivial for an attacker to tamper with.
*   **Separation of Concerns:** The host application is responsible for the routing and session management. Relyra is a protocol library.
*   **DX:** Supplying a `safe_local_redirect` utility (which ensures paths start with `/` but not `//`) gives developers a paved path to doing it securely.

## Scope of Work (TBD for Planning)
*   Add `allow_idp_initiated: boolean()` to `Relyra.Connection` and Ecto schema.
*   Update `Relyra.consume_response` to conditionally bypass `InResponseTo` validation if `allow_idp_initiated` is true and `request_intent_or_opts` is explicitly `nil` or lacks an intent.
*   Extract `RelayState` from `consume_response` opts (passed by host app from POST body) and attach to `Relyra.LoginResult`.
*   Implement `Relyra.Security.safe_local_redirect/2`.
*   Update telemetry, documentation, and `Relyra.Provider` default logic if necessary.
