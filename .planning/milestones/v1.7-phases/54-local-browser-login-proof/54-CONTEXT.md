# Phase 54: Local Browser Login Proof - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 54 builds the default offline demo proof. It completes an in-browser SAML login through a dev/test-only FakeIdP route using genuine Relyra test signing. The FakeIdP proof is clearly labeled as local test support and produces actionable receipts, covering the setup checklist, LiveAdmin connection visibility, end-user login receipt, and support trace handoff. Failed local proof paths surface typed rejection evidence rather than silent compromise or raw protocol leakage.
</domain>

<decisions>
## Implementation Decisions

### FakeIdP Route & Controller
- **D-01:** Implement a simple `FakeIdPController` in `demo/ledger_loop` mapping to `/fake_idp/login` and `/fake_idp/sso`. This keeps the test IdP local to the demo but conceptually distinct from production IdP behavior.

### Visual Identity
- **D-02:** The FakeIdP UI must prominently display a banner such as "⚠️ Local Test Support / FakeIdP" to satisfy the requirement that it cannot be mistaken for a production IdP.

### Proof Paths
- **D-03:** Provide buttons to trigger successful logins (using `Relyra.TestSupport.FakeIdP` to generate valid, genuinely-signed `SAMLResponse`s) for both Admin and Standard User roles.
- **D-04:** Provide "Simulate Failure" buttons to generate invalid responses (e.g., expired assertions or bad signatures) to prove strict rejection and showcase the LiveAdmin trace capabilities.

### Integration
- **D-05:** Integrate with the Phase 53 `SetupLive` checklist. When the FakeIdP provider is selected, the "Test Login" button links directly to `/fake_idp/login?RelayState=...`.

### Claude's Discretion
None - all assumptions locked as decisions.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `demo/ledger_loop/lib/ledger_loop_web/router.ex`
- `demo/ledger_loop/lib/ledger_loop_web/live/setup_live.ex`
- `lib/relyra/test_support/fake_idp.ex`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.TestSupport.FakeIdP` provides the necessary cryptographic generators to build valid and invalid SAML artifacts.
- Deterministic demo users (`admin@northstar.example.com` and `user@northstar.example.com`) are already seeded.

### Established Patterns
- Relyra strictly requires cryptographically valid assertions, so the FakeIdP must correctly construct the `SignedInfo` structure.
</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope
</deferred>
