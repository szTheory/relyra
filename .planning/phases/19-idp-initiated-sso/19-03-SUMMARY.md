---
phase: 19-idp-initiated-sso
plan: 03
status: complete
verified: 2026-05-06T20:30:00Z
---

## 19-03 Summary: ACS Pipeline Update

I finalized the core implementation for IdP-initiated SSO support, including security guardrails and result normalization.

### Key Changes
- Updated `Relyra.Protocol.ValidationPipeline` to handle missing request intents and selectively bypass `InResponseTo` checks when `allow_idp_initiated` is enabled.
- Modified `Relyra.Security.XML.PureBeam` to make the `InResponseTo` attribute optional in SAML Responses.
- Updated the `Relyra` facade to return a fully populated `%Relyra.LoginResult{}` struct instead of a raw map.
- Ensured `RelayState` propagation and `Principal` population in the final login result.
- Fixed regressions in existing protocol test fixtures to align with new validation error types.

### Verification Results
- `mix test test/protocol/idp_initiated_test.exs` passed.
- `mix test test/relyra_test.exs` passed.
- `mix test test/protocol/consume_response_pipeline_test.exs` passed.
