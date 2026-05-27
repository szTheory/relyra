<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- `Relyra.SessionAdapter` extended with `index_session/4` and `terminate_by_session_index/4`.
- SP-initiated and IdP-initiated logout flows reliably parse, generate, and process `LogoutRequest` and `LogoutResponse` for HTTP-Redirect and HTTP-POST bindings.
- All logout messages enforce strict XMLDSig signature verification before any session is terminated.
- Strict replay protection prevents the re-use of previously submitted logout messages.

### the agent's Discretion
- Public API shape for logout flows (`Relyra.start_logout/3`, `Relyra.consume_logout/3`).

### Deferred Ideas (OUT OF SCOPE)
None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SLO-01 | Full SLO (Single Logout) round-trip (SP-initiated + IdP-initiated) with `SessionIndex` correlation. | Verified needed fields (`SessionIndex`), strict signature verification (XMLDSig for POST, `:public_key` URL verification for Redirect), and replay protection via `ReplayStore`. |
</phase_requirements>

# Phase 38: Single Logout (SLO) Core & Security - Research

**Researched:** 2026-05-27
**Domain:** SAML 2.0 Single Logout Protocol, Session Revocation, Signature Verification
**Confidence:** HIGH

## Summary

Phase 38 implements the remaining core protocol bindings and security checks for Single Logout (SLO) required by `SLO-01`. While earlier phases introduced `LogoutRequest` building, full SLO requires end-to-end SP-initiated and IdP-initiated flows processing both `LogoutRequest` and `LogoutResponse` over HTTP-Redirect and HTTP-POST bindings. 

Crucially, Relyra's security invariants apply strictly here: the `SessionAdapter` behavior must decouple SAML `SessionIndex` tracking from the host app's session implementation (`index_session/4` and `terminate_by_session_index/4`); incoming XML payloads must parse exclusively via `PureBeam.parse_safely/2`; all logout messages must be signature-verified (XMLDSig for POST, Query signature for Redirect) BEFORE honoring any session termination; and `ReplayStore` must protect against replay attacks on the message `ID` to prevent denial-of-service via captured logout URLs.

**Primary recommendation:** Implement a strict `LogoutPipeline` that forces parse -> signature verification -> replay check -> execution. Create `verify_redirect_signature/4` in `Relyra.Security.Signature` that mimics `sign_redirect_query/3` to securely verify URL parameters.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SLO Protocol Binding | API / Backend | — | Library parses Base64/Deflate XML and verifies exact protocol schema shapes. |
| Signature Verification | API / Backend | — | Library must perform XMLDSig (HTTP-POST) or URL param verification (HTTP-Redirect). |
| Replay Protection | API / Backend | Database | Validating message IDs against `Relyra.ReplayStore` to prevent URL-capture DoS. |
| Session Termination | API / Backend | Frontend / SSR | `Relyra.SessionAdapter` delegates local session destruction to host application. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:public_key` | (OTP) | Crypto operations | Standard BEAM library for RSA/ECDSA signature verification. |

## Architecture Patterns

### Pattern 1: Validation Pipeline for Logout
**What:** Just as AuthnResponse has a locked validation order (`parse_safely` -> `signature_verify` -> `status` -> `time_conditions`), SLO requests/responses must follow a strict pipeline.
**When to use:** When consuming any `LogoutRequest` or `LogoutResponse`.
**Anti-Pattern:** Attempting to find the `<SessionIndex>` and invoking session termination before the signature is mathematically verified.

### Pattern 2: HTTP-Redirect Signature Verification
**What:** Unlike HTTP-POST which embeds `<ds:Signature>` via XMLDSig, the HTTP-Redirect binding signs the URL query string itself (`SAMLRequest=...&RelayState=...&SigAlg=...`).
**When to use:** When receiving a LogoutRequest or LogoutResponse via HTTP GET.
**Example:**
```elixir
# Must verify the raw octets exactly as received from the wire
:public_key.verify(raw_octets, digest_atom, signature_bytes, public_key)
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Redirect Signature Verification | Custom string concatenation logic | Pass the raw `conn.query_string` octets before parameter parsing | Framework-parsed parameters lose original octet ordering and URL encoding (e.g. `+` vs `%20`), failing signature verification. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | N/A |
| Live service config | None | N/A |
| OS-registered state | None | N/A |
| Secrets/env vars | None | N/A |
| Build artifacts | None | N/A |

## Common Pitfalls

### Pitfall 1: URL Parameter Re-serialization for Redirect Binding Verification
**What goes wrong:** The signature fails to verify because the SP extracts parameters from `Plug.Conn.params` and reconstructs the query string, which may use a different URL-encoding scheme than the IdP used (e.g., spaces as `+` vs `%20`).
**Why it happens:** Attempting to reconstruct the signed string instead of using the raw wire bytes.
**How to avoid:** The function verifying the redirect signature MUST be handed the raw query string segment precisely as received on the wire, extracting `SAMLRequest=X&RelayState=Y&SigAlg=Z` directly from it.

### Pitfall 2: Replay Attack on Logout (Denial of Service)
**What goes wrong:** An attacker captures a valid HTTP-Redirect `LogoutRequest` URL and hits it days later, repeatedly destroying the user's active session.
**Why it happens:** IdPs sign the LogoutRequest, so the signature remains valid. Without checking the message `ID`, the SP assumes it's a fresh logout.
**How to avoid:** `Relyra.ReplayStore.check_and_store(message_id, issue_instant, ...)` MUST be invoked for every consumed Logout message.

## Code Examples

### `Relyra.SessionAdapter` Extension
```elixir
@callback index_session(
            subject :: map(),
            session_index :: binary(),
            local_session_id :: term(),
            opts :: keyword()
          ) :: {:ok, term()} | {:error, Relyra.Error.t()}

@callback terminate_by_session_index(
            session_index :: binary(),
            issuer :: binary(),
            opts :: keyword()
          ) :: {:ok, term()} | {:error, Relyra.Error.t()}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `revoke_session/4` | `terminate_by_session_index/4` | Phase 38 | Properly decouple SAML `SessionIndex` from local Session IDs, avoiding the SP needing to search its local datastore blindly. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | [ASSUMED] `SessionAdapter.index_session/4` replaces or complements existing `revoke_session/4`. | Architecture | Potential backwards compatibility break if `revoke_session/4` is removed abruptly. |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test` |
| Full suite command | `mix ci.security` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SLO-01 | Parse and strictly verify LogoutRequest | unit | `mix test test/protocol/logout_pipeline_test.exs -x` | ❌ Wave 0 |
| SLO-01 | Replay protection on Logout messages | unit | `mix test test/protocol/logout_pipeline_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix ci.security`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/protocol/logout_pipeline_test.exs` — covers SLO-01 validation logic.
- [ ] `test/fixtures/security/slo_manifest.json` — golden bytes for SLO redirect validation.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | SLO terminates authenticated sessions |
| V3 Session Management | yes | `SessionAdapter.terminate_by_session_index/4` |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `PureBeam.parse_safely/2` |
| V6 Cryptography | yes | `Relyra.Security.Signature` `:public_key.verify` |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Signature Wrapping | Spoofing | Bind XML node selection to exactly what the signature verified. |
| Replay Attack | Denial of Service | `ReplayStore` check on message ID before session termination. |
| Malformed Redirect Octets | Tampering | Do not re-serialize HTTP-Redirect query string parameters before signature verification. |

## Sources

### Primary (HIGH confidence)
- `lib/relyra/session_adapter.ex` - Verified current `revoke_session/4` design.
- `lib/relyra/security/signature.ex` - Verified existence of `sign_redirect_query/3` and need for inverse `verify_redirect_signature/4`.

### Secondary (MEDIUM confidence)
- WebSearch/OASIS SAML 2.0 Bindings Spec - Verified HTTP-Redirect signature involves exact raw octets and HTTP-POST involves XMLDSig.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Relies strictly on already locked dependencies (`:public_key`).
- Architecture: HIGH - Fits symmetrically with Relyra's `ValidationPipeline` invariant.
- Pitfalls: HIGH - URL parameter re-serialization is a known CVE class in SAML libraries (e.g. `ruby-saml`, `passport-saml`).

**Research date:** 2026-05-27
**Valid until:** 2026-06-27