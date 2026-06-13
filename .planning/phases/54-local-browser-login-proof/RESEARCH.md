# Phase 54: Local Browser Login Proof - Research

**Researched:** 2026-06-12 (Current)
**Domain:** Identity Provider Simulation & E2E Browser Testing
**Confidence:** HIGH

## Summary

The goal of this phase is to provide a local, offline demo proof that completes a strict SAML login through a browser-visible FakeIdP. This proves the full end-to-end Relyra Phoenix integration, including the security and assertion paths, without requiring an external IdP (like Okta or Google).

The codebase already contains a robust `Relyra.TestSupport.FakeIdP` which can generate protocol-correct XML, sign it with genuine Relyra test signing logic (`Relyra.TestSupport.XmldsigSigner`), and encrypt assertions if necessary. We need to expose a "Fake IdP" web route in `LedgerLoopWeb` that acts as an IdP, taking an inbound `SAMLRequest` (or just simulating an IdP-initiated login), generating a signed `SAMLResponse`, and emitting an auto-submitting HTML form to POST back to the SP's ACS URL (`/saml/:connection_id/acs`).

**Primary recommendation:** Introduce a `FakeIdPController` in `demo/ledger_loop/lib/ledger_loop_web/controllers/` (dev/test only) that uses `Relyra.TestSupport.FakeIdP.sign/2` to generate a valid `SAMLResponse` and renders a standard auto-POST form to the ACS endpoint. Hook this up via a "Start Fake Login" button on the `RouteAffordanceController`'s login page.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fake IdP Route | Frontend Server | — | Needs to handle HTTP GET/POST and render a browser-visible auto-submit form for SAML responses. |
| SAML Response Generation | Backend | — | Uses `Relyra.TestSupport.FakeIdP` to securely build and sign the XML assertion. |
| SAML Validation | Backend | — | The existing `Relyra.Phoenix.Router` (via `ACSController`) handles the inbound assertion validation. |
| End-User UX | Browser | — | The user sees a warning that it's a simulated FakeIdP and then gets redirected. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Relyra.TestSupport.FakeIdP` | Internal | Generate signed SAML Responses | Already built, proven in test suite, securely exercises the actual verification logic. |
| Phoenix Controllers | 1.8.7 | Handle IdP HTTP routes | Standard request/response cycle for simulating an IdP. |

## Package Legitimacy Audit
*No new external packages are required for this phase.*

## Architecture Patterns

### FakeIdP Controller Pattern

**What:** A dedicated Phoenix controller exposed only in non-prod environments to act as the IdP.
**When to use:** Local development, offline demos, and E2E browser tests without external dependencies.
**Example:**
```elixir
defmodule LedgerLoopWeb.FakeIdPController do
  use LedgerLoopWeb, :controller
  alias Relyra.TestSupport.FakeIdP
  alias Relyra.TestSupport.XmldsigSigner

  def idp_initiated(conn, %{"connection_id" => connection_id}) do
    # 1. Look up connection to get acs_url and sp_entity_id
    connection = LedgerLoop.Demo.Fixtures.relyra_connections() |> Enum.find(&(&1.connection_id == connection_id))

    # 2. Build signed response
    signed_response_b64 = FakeIdP.sign(
      subject: "testuser@example.com",
      audience: connection.sp_entity_id,
      destination: connection.acs_url,
      recipient: connection.acs_url
    )

    # 3. Render an auto-submit form or an interstitial warning page
    render(conn, :auto_post, 
      acs_url: connection.acs_url, 
      saml_response: signed_response_b64,
      relay_state: "local_test_proof"
    )
  end
end
```

### Anti-Patterns to Avoid
- **Bypassing the Security Seams:** Do not inject a fake user directly into the session or bypass `Relyra.start_login`. The point of Phase 54 is to exercise the **real** Relyra validation pipeline from the browser. The `FakeIdP` must produce real base64-encoded XML.
- **Leaking FakeIdP into Production:** Ensure `FakeIdPController` routes are guarded or completely excluded from `MIX_ENV=prod` compilations.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SAML XML Generation | String interpolation or custom XML builder | `Relyra.TestSupport.FakeIdP` | Ensures correct structure, C14N, and valid signatures that the strict SP will accept. |
| Key Generation | Generating keys on the fly | `Relyra.TestSupport.XmldsigSigner.keypair()` | Deterministic, known-good keys already trusted by the test suite. |

## Common Pitfalls

### Pitfall 1: Destination Mismatch
**What goes wrong:** Relyra rejects the assertion with `:destination_mismatch` or `:recipient_mismatch`.
**Why it happens:** The `FakeIdP` wasn't instructed with the exact `acs_url` and `sp_entity_id` configured for the `Connection`.
**How to avoid:** Always dynamically fetch the `connection` in the `FakeIdPController` and pass its properties to `FakeIdP.sign/2`.

### Pitfall 2: Accidental Production Exposure
**What goes wrong:** The FakeIdP route is available in production, allowing trivial auth bypasses.
**Why it happens:** The route was added to the main router without environment guards.
**How to avoid:** Use `if Mix.env() in [:dev, :test] do` blocks around the FakeIdP routes in `router.ex`.

## Code Examples

### Interstitial Warning and Auto-Submit Form
```heex
<!-- demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/auto_post.html.heex -->
<div class="fake-idp-warning">
  <h1>Local Test Support IdP</h1>
  <p>This is a simulated Identity Provider. It is not for production use.</p>
</div>

<form id="saml-post" method="post" action={@acs_url}>
  <input type="hidden" name="SAMLResponse" value={@saml_response} />
  <input type="hidden" name="RelayState" value={@relay_state} />
  <noscript>
    <button type="submit">Continue to App</button>
  </noscript>
</form>

<script>
  // Auto-submit after a brief delay so the user sees the warning
  setTimeout(() => document.getElementById('saml-post').submit(), 1500);
</script>
```

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Relyra SAML verification pipeline |
| V3 Session Management | yes | `Relyra.SessionAdapter` |
| V4 Access Control | yes | Ensure FakeIdP is dev/test only |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Authentication Bypass | Spoofing | Compile-time and router-level exclusion of FakeIdP from `prod` environments. |

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `FakeIdP` already exists and is mature.
- Architecture: HIGH - Phoenix controllers and auto-POST forms are standard SAML IdP implementations.
- Pitfalls: HIGH - Destination mismatch and prod exposure are the primary risks.

**Research date:** 2026-06-12
