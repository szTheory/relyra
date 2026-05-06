# Phase 17: Certificate Inventory & Staged Rollover UI Research Report

## 1. LiveView Presentation & Expiry

**The Gray Area:** How to visually represent Active, Next, and Retired certificate states along with expiry warnings in a way that is immediately understandable and actionable for an operator.

### Research, Tradeoffs, and Lessons Learned
*   **Generic List vs. Semantic Slots:** A standard data table of certificates sorted by expiry is easy to build but cognitively heavy. The operator must parse dates and statuses to infer which certificate is currently signing requests. Semantic slots (e.g., visually grouping by "Active", "Next/Staged", "Retired") directly map to the operator's mental model.
*   **Lessons from Okta/Entra:** Microsoft Entra and Okta explicitly separate the "Active" certificate from "Inactive" or "Staged" certificates. Entra notoriously flashes warnings 30 days before expiry. A major footgun in older SAML systems is burying the certificate status deep in a settings menu, causing unexpected Monday morning outages when a certificate silently expires.
*   **Idiomatic Phoenix/Brand Alignment:** Relyra's brand book emphasizes specific visual cues for this domain: "Certificate Gold" (#C08A2B) for accents, Amber/Warning (#B45309) for time-bound risks like expiry, and tabular numerals for dates and fingerprints. 

### The Perfect Recommendation
**Implement a Semantic "Slot-Based" Timeline UI.**
Do not render a generic data table. Instead, render a fixed-layout timeline containing three distinct sections: **Next (Staged)**, **Active**, and **Retired**.
*   **Visuals:** Use tabular numerals for certificate fingerprints and dates. Use a clock icon coupled with the "Warning" amber color for any certificate expiring in less than 30 days.
*   **Empty States:** If there is no "Next" certificate, display a dashed placeholder slot prompting the user to "Import replacement from metadata or upload". 
*   **Clarity:** The UI must scream which certificate is actively trusting signatures at this exact moment, minimizing the cognitive load during high-stress production incidents.

---

## 2. Optimistic Locking Conflict Handling in LiveView

**The Gray Area:** How to safely handle Ecto optimistic lock (`Ecto.StaleEntryError`) errors during promote/retire actions, surfacing conflicts gracefully to the operator without crashing the LiveView process.

### Research, Tradeoffs, and Lessons Learned
*   **Crash vs. Rescue:** By default, Elixir encourages "let it crash" for invariant violations. However, Phoenix LiveView best practices dictate that "expected user-facing failures should be rendered as state/errors." In an admin dashboard where multiple IT staff might configure a connection simultaneously, a concurrent edit is a plausible, expected domain event, not an invariant violation.
*   **Blind Overwrites vs. Locking:** If Admin A opens the page, Admin B rotates the certificate, and Admin A subsequently clicks "Retire", allowing Admin A's action to proceed based on stale state could instantly break enterprise SSO. Ecto's `optimistic_lock` perfectly prevents this by raising `Ecto.StaleEntryError`.
*   **Idiomatic Phoenix:** Trapping the error locally in the specific `handle_event` rather than letting the LiveView crash and remount ensures the operator doesn't lose their place or UI state. 

### The Perfect Recommendation
**Rescue `StaleEntryError` locally and force a declarative state refresh.**
Use Ecto's `optimistic_lock` on the Connection aggregate. When processing the `phx-submit` for a promote/retire action, wrap the mutation logic:
```elixir
try do
  # Ecto mutation (Promote / Retire)
rescue
  Ecto.StaleEntryError ->
    socket
    |> put_flash(:error, "The connection was modified by another operator. Please review the updated trust state.")
    |> assign(:connection, reloaded_connection) # Reload from DB to show truth
end
```
This adheres to the principle of least surprise: the operator is blocked from making a destructive change based on old data, they are told exactly why, and the UI immediately updates to reflect the new, true state of the database without a disruptive page crash.

---

## 3. Safe Rollover UX Interaction Design

**The Gray Area:** The UX flow for promoting or retiring a certificate to prevent operators from inadvertently breaking trust (e.g., warning them that the Relying Party must be updated).

### Research, Tradeoffs, and Lessons Learned
*   **1-Click Rotation vs. Typed Confirmation:** A single-click rotation is convenient but disastrous for SAML. If the Identity Provider (IdP) hasn't updated their Service Provider (SP) configuration to expect the new certificate, SSO breaks instantly upon promotion.
*   **The "Grace Period" Footgun:** The most resilient systems (like AWS SAML integrations or Auth0) support a "grace period" (staged rollover) where *both* the old and new certificates are temporarily trusted for signature validation. This allows asynchronous coordination between organizations.
*   **Idiomatic Phoenix:** Use LiveView modals triggered by a `phx-click` to intercept the destructive action, requesting a typed validation string (e.g., typing the action name or fingerprint) via a form before executing the backend mutation.

### The Perfect Recommendation
**Enforce a 3-Step Staged Rollover with Typed Verification.**
Never allow an immediate, unconfirmed swap of an active certificate. The UX must guide the operator through a safe protocol:
1.  **Stage:** Operator uploads or imports the new certificate. It lands in the "Next (Staged)" slot. It is inactive.
2.  **Promote to Grace Period:** When promoting, intercept with a LiveView modal. Warn the user explicitly: *"Ensure the Relying Party has this new certificate before proceeding."* Require the operator to type the first 6 characters of the new certificate's fingerprint (using tabular numerals) into an input field to enable the "Promote" button. Behind the scenes, the system enters a "Rollover Mode" where *both* the old and new certificates are active.
3.  **Retire:** Once the operator verifies SSO is working with the new certificate, they click "Retire" on the old certificate. This triggers a standard confirmation modal (no typing required, as the destructive risk was mitigated in step 2) that drops the old certificate, leaving only the new one Active. 

This workflow mechanically prevents the most common SAML outage—an out-of-sync certificate swap—by forcing the operator to acknowledge the distributed nature of the trust change.