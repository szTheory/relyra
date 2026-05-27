# SAML Error Atom Decoder

This guide is the operator-facing decoder for every `:atom` `Relyra.Error`
emits. Use it to translate a typed rejection in your logs, telemetry, or
audit trail into the next concrete operator step.

## Overview

Every login ends in a verified trust path or a typed rejection — this guide
is the rejection vocabulary. Relyra returns `{:error, %Relyra.Error{type:
:atom, ...}}` at every gate of the SAML trust pipeline; the host application
catches the atom and decides how to respond. The atom is stable across
releases (rename is a SemVer-major event); the `message` and `details` fields
are explanatory and may evolve.

Atoms are grouped by the trust-pipeline seam that emits them — XML
hardening, signature and crypto, replay and request intent, metadata
lifecycle, network fetch, binding and protocol shape, and configuration
wiring. The grouping preserves the trust-boundary mental model: pre-parse
guards read next to their pre-parse siblings, not next to post-parse crypto
failures.

When an atom indicates an active incident (a signing certificate has rotated,
a replay storm is in flight, a metadata refresh is degraded), follow the
matching scenario runbook in
[`guides/operations/incident_playbook.md`](operations/incident_playbook.md).

## Relyra owns / Host owns

## Relyra owns

- Emitting typed rejections as `%Relyra.Error{type: :atom, message: ...,
  details: ...}` from every gate in the trust pipeline.
- Never relaxing the non-negotiable security invariants at runtime (signature
  source, one parse path, pre-parse guards, real crypto, audit co-commit,
  replay protection).
- Documenting the canonical atom set in this guide.
- Gating the guide against the codebase via the bidirectional drift test
  (`test/docs/troubleshooting_drift_test.exs`).

## Host owns

- Monitoring logs and telemetry for atoms and routing them to the operator
  on-call.
- Deciding whether `:trust_anchor_mismatch` is an IdP configuration error,
  staged certificate rollover, or an active attack.
- Mapping each atom to a runbook in
  [`guides/operations/incident_playbook.md`](operations/incident_playbook.md).
- Redacting log payloads downstream (Relyra's `Error.redact_details/1` is
  available — call it before persisting `details` outside the audit ledger).

## XML Hardening

These atoms fire BEFORE or DURING saxy parse — the request never reached the
trust core. They protect the auth boundary from malformed input, entity
expansion, and parser-differential attacks (one parse path; one canonical
parse tree).

### :doctype_forbidden

**Means:** The inbound XML payload declared a `<!DOCTYPE ...>`, which is
rejected before any parse runs.

**Likely root cause:** A misbehaving SAML proxy or IdP added a DOCTYPE
preamble; or an attacker is probing for XXE.

**Operator action:** Inspect the raw payload via `mix relyra.diagnostic`;
confirm the originating IdP does not legitimately emit DOCTYPE. If
legitimate, escalate to the IdP vendor — Relyra will not accept DOCTYPEs.

**Source:** `lib/relyra/metadata/parser.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :entity_expansion_forbidden

**Means:** The inbound XML contained an entity reference, which is rejected
on the raw bytes before parsing.

**Likely root cause:** XXE probe, billion-laughs attempt, or a non-standard
IdP that uses internal entities.

**Operator action:** Capture the payload via `mix relyra.diagnostic`. Treat
as a hostile probe unless the operator can prove benign IdP origin.

**Source:** `lib/relyra/metadata/parser.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :payload_too_large

**Means:** The inbound XML exceeded the configured pre-parse size limit,
rejected on the raw bytes before saxy is invoked.

**Likely root cause:** Decompression bomb, oversized assertion, or a
legitimate IdP whose payload genuinely exceeds the default cap.

**Operator action:** If hostile, drop. If a legitimate IdP routinely exceeds
the cap, raise the limit explicitly in configuration and review the audit
ledger entry — never widen the cap silently.

**Source:** `lib/relyra/metadata/parser.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :malformed_xml

**Means:** The payload is not well-formed XML — saxy refused it.

**Likely root cause:** Truncation in transit, base64 decode mismatch, or an
IdP emitting non-XML content (HTML error page, JSON, plain text).

**Operator action:** Capture the payload via `mix relyra.diagnostic`. Verify
the IdP endpoint is returning SAML, not an error page. Check the binding
(POST vs Redirect) matches what the connection record expects.

**Source:** `lib/relyra/metadata/parser.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :duplicate_xml_id

**Means:** Two elements in the parse tree carry the same `ID` attribute,
which would let an attacker steer signature verification away from the
intended node (signature wrapping).

**Likely root cause:** Active XSW (signature wrapping) probe, or — rarely —
a buggy IdP signer.

**Operator action:** Treat as hostile until proven otherwise. Capture the
payload, file a ticket, do NOT retry. Real XSW corpora gate every build via
`mix ci.security`.

**Source:** `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :ambiguous_signed_node

**Means:** More than one `ds:Signature` element matched a candidate signed
node, or the Reference URI did not bind to exactly one tree node.

**Likely root cause:** Signature-wrapping attack or a non-conformant IdP
signer emitting overlapping signatures.

**Operator action:** Treat as hostile. Capture the payload via `mix
relyra.diagnostic`; the assertion was rejected fail-closed.

**Source:** `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :ambiguous_assertion

**Means:** The Response carried both a cleartext `<Assertion>` and one or
more `<EncryptedAssertion>` elements, or carried more than one
`<EncryptedAssertion>`. Rejected BEFORE any decryption runs.

**Likely root cause:** CVE-2026-2092-class injection probe (Keycloak
cleartext-alongside-encrypted bypass), or a misconfigured IdP that emits
both modes simultaneously.

**Operator action:** Treat as hostile. Capture the payload; confirm the
IdP's signing/encryption configuration emits exactly one assertion shape per
response.

**Source:** `lib/relyra/protocol/validation_pipeline.ex`

### :invalid_parsed_doc

**Means:** The parsed document handle expected by a downstream gate did not
have the required structural shape (a logout request or logout response
arrived with no parse tree, etc.).

**Likely root cause:** Internal contract drift — usually a sign the request
took a path that bypassed `PureBeam.parse_safely/2`. Should never appear in
production.

**Operator action:** Capture the diagnostic bundle and file a Relyra issue —
this atom indicates an internal invariant violation, not an IdP
misconfiguration.

**Source:** `lib/relyra/protocol/logout_request.ex`, `lib/relyra/protocol/logout_response.ex`

### :canonicalization_failed

**Means:** Exclusive-C14N serialization of the referenced tree node failed,
or a transform URI outside the strict `{enveloped-signature, exc-c14n}`
allowlist was requested.

**Likely root cause:** A signer using an unsupported transform (inclusive
C14N, XPath, XSLT — none allowed), or an internal C14N engine error.

**Operator action:** Capture the diagnostic bundle. If the IdP signs with
inclusive C14N or XPath, the trust path cannot proceed — Relyra is strict by
design. Coordinate with the IdP to switch to the SAML-conformant
exclusive-C14N transform.

**Source:** `lib/relyra/security/xml/c14n.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :corpus_violation

**Means:** A request or metadata blob tripped the adversarial-corpus gate —
the payload matched a known attack fixture (signature wrapping, C14N
differential, XXE class).

**Likely root cause:** Active attack probe, or a regression test artifact
leaking into production input.

**Operator action:** Treat as hostile. Capture the diagnostic bundle and
file an incident. The adversarial corpus is a permanent gate via `mix
ci.security`.

**Source:** `lib/relyra/security/xml/corpus_gate.ex`

## Signature & Crypto

These atoms fire INSIDE the XMLDSig verify path — the structure was valid,
the math was not. They are the auth boundary's final word: configured certs
only, real cryptographic verification, no document-`KeyInfo` trust.

### :missing_signature

**Means:** A required `ds:Signature` element was absent from the Response,
Assertion, metadata root, or logout payload.

**Likely root cause:** The IdP is not signing what Relyra expects; or the
connection's `wants_assertions_signed` policy mismatches the IdP emission.

**Operator action:** Confirm the IdP's signing posture matches the
connection record (Response vs. Assertion signing). Capture the unsigned
payload via `mix relyra.diagnostic`.

**Source:** `lib/relyra/security/logout_validator.ex`, `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :invalid_signature

**Means:** The XMLDSig `SignatureValue`, verified against the canonicalized
`SignedInfo` using the configured IdP cert public key via
`:public_key.verify`, did not match.

**Likely root cause:** Wrong configured certificate, IdP key rotation that
has not yet been staged in Relyra, or an active forgery probe.

**Operator action:** Diagnose via `mix relyra.diagnostic`; cross-check the
IdP's currently-published metadata against the certificate inventory. Stage
the new IdP cert via the admin UI rather than swapping in place.

**Source:** `lib/relyra/security/logout_validator.ex`, `lib/relyra/security/signature.ex`

### :digest_mismatch

**Means:** The recomputed `DigestValue` over the canonicalized referenced
element did not match the value in `ds:Reference/ds:DigestValue` (constant-
time comparison via `:crypto.hash_equals`).

**Likely root cause:** Content tampering between IdP signing and SP receipt
(active attack), or — rarely — a canonicalization mismatch in a non-
conformant signer.

**Operator action:** Treat as hostile until proven otherwise. Capture the
payload via `mix relyra.diagnostic`. This atom is the load-bearing assertion
that protects against tampered-NameID and altered-attribute attacks.

**Source:** `lib/relyra/security/signature.ex`

### :unsupported_signature_algorithm

**Means:** The signature method URI on the Response, Assertion, or metadata
root is not on the allowed list (e.g. ECDSA, RSA-MD5, or an unrecognized
URI).

**Likely root cause:** An IdP signing with an algorithm Relyra does not
permit (ECDSA fail-closed reject) or a malformed `SignatureMethod` URI.

**Operator action:** Configure the IdP to use RSA-SHA256 (or an explicitly
allowlisted alternative). Relyra refuses to verify outside the allowlist —
this is the algorithm-policy fail-closed contract.

**Source:** `lib/relyra/security/signature.ex`

### :untrusted_certificate

**Means:** The certificate chain offered for signature verification could
not be parsed as a public key, did not match any pinned trust anchor, or
failed the configured chain-validation rules.

**Likely root cause:** Malformed PEM in the connection record, expired or
revoked IdP cert, or a swapped certificate that has not been operator-
approved.

**Operator action:** Inspect the connection's certificate inventory via
`/relyra/admin/connections/:connection_id/edit`. Compare against the IdP's
current published metadata. Stage replacements; never swap in place.

**Source:** `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`

### :trust_anchor_mismatch

**Means:** Metadata-root verification rejected the document because the
candidate signing certificate's DER-SHA-256 fingerprint did not match the
operator-pinned trust anchor.

**Likely root cause:** IdP rotated its metadata signing key without operator
staging, or — if unexpected — an active metadata-substitution probe.

**Operator action:** Verify the new fingerprint from a trusted out-of-band
channel; pin via `mix relyra.metadata.pin` or the admin UI. Never trust
document-asserted `KeyInfo`.

**Source:** `lib/relyra/metadata/trust_anchor.ex`

### :key_not_configured

**Means:** A signing or decryption operation needed a key that the SP did
not have configured (typically the SP encryption private key for
`<EncryptedAssertion>`, or the SP signing key for redirect-binding
AuthnRequests).

**Likely root cause:** Forgotten key material in app config, or a connection
asking for encrypted assertions before the SP has staged its decryption key.

**Operator action:** Confirm `:key_resolver` configuration in app config.
Private keys live in app config only — never in the database, never in the
diagnostic bundle.

**Source:** `lib/relyra/key_resolver/default.ex`, `lib/relyra/security/signature.ex`

### :deprecated_algorithm

**Means:** A signature, digest, or encryption algorithm URI is blocked by
the active `AlgorithmPolicy` (default-blocked SHA-1 / RSA-PKCS1v1.5 /
AES-CBC).

**Likely root cause:** A legacy IdP still signing with SHA-1, or an
encrypted assertion using deprecated transport.

**Operator action:** Coordinate with the IdP to upgrade. If a documented
compatibility window is required, configure a time-boxed
`legacy_algorithm_policy:` override with an audit reason — never bypass the
algorithm policy silently.

**Source:** `lib/relyra/security/algorithm_policy.ex`

### :legacy_algorithm_override_expired

**Means:** The `legacy_algorithm_policy` time-boxed override has expired
(`expires_at` is in the past) and SHA-1 / RSA-PKCS1v1.5 are once again
blocked by default.

**Likely root cause:** The compatibility window the operator authored to
unblock a legacy IdP has elapsed.

**Operator action:** Either (a) the IdP has been upgraded and the override
can be removed, or (b) the IdP still needs the window — re-authorize the
override with a fresh `expires_at` and a documented audit reason.

**Source:** `lib/relyra/security/algorithm_policy.ex`

### :decryption_failed

**Means:** Single opaque atom for every XMLEnc decryption-stage failure
(invalid CEK transport, malformed cipher value, wrong AES-GCM tag, KeyInfo
mismatch). One atom on purpose — distinct atoms here would open a padding
oracle.

**Likely root cause:** Wrong SP private key, expired CEK, corrupted cipher
value, or an active probe testing decryption gates.

**Operator action:** Inspect via `mix relyra.diagnostic`. Confirm the SP
encryption key in app config matches the cert published in SP metadata.
Never log raw cipher bytes.

**Source:** `lib/relyra/protocol/validation_pipeline.ex`

### :signature_failed

**Means:** A signing-side operation failed (Relyra's metadata-refresh
publisher could not sign an outbound payload, or the signer rejected an
input).

**Likely root cause:** Missing or malformed SP signing key, an internal
signer-state bug, or a degraded auto-refresh worker.

**Operator action:** Check the SP signing-key configuration, the audit
ledger for the originating mutation, and the auto-refresh telemetry.

**Source:** `lib/relyra/metadata/auto_refresh.ex`

## Replay & Request Intent

These atoms fire on intent/replay state checks — the request was
authentic but unwelcome. They protect against replayed assertions and
forged in-response-to chains.

### :replayed_assertion

**Means:** The assertion's `(InResponseTo, IssueInstant)` tuple has already
been seen and recorded in the replay store within the active window.

**Likely root cause:** Active replay attack, an IdP retransmitting an
already-consumed response, or — rarely — a clock-skew issue that re-windows
a legitimate retry.

**Operator action:** Capture the duplicate via `mix relyra.diagnostic`. The
replay store is the cluster-safe Ecto adapter in production; if running on
the ETS adapter, confirm that is intentional. Replays produce NO audit row
(they do not mutate trust state) — rely on the `[:relyra, :saml, :replay,
:check]` telemetry alone.

**Source:** `lib/relyra/replay_store/ecto.ex`, `lib/relyra/replay_store/ets.ex`

### :request_intent_consumed

**Means:** The opaque request intent (the SP-initiated request-id token)
has already been redeemed by an earlier response.

**Likely root cause:** Duplicate Response delivery, browser back-button
replay, or an active probe.

**Operator action:** Confirm the user's session establishment path; if a
benign duplicate, the user should re-initiate login. If suspicious, capture
the diagnostic bundle.

**Source:** `lib/relyra/request_store/ecto.ex`, `lib/relyra/request_store/ets.ex`

### :request_intent_expired

**Means:** The request intent associated with this Response was created
outside the configured TTL window (default 5 minutes).

**Likely root cause:** Slow user, mobile network delay, or excessive
clock-skew between SP and IdP.

**Operator action:** Confirm SP/IdP clock skew is within the configured
window. Have the user re-initiate login.

**Source:** `lib/relyra.ex`

### :request_intent_invalid

**Means:** The opaque request-intent token did not parse as a valid
identifier (wrong shape, wrong encoding, or tampered).

**Likely root cause:** Cookie / RelayState corruption, or a tampered
identifier.

**Operator action:** Have the user re-initiate login from a clean session.
If repeated, capture the diagnostic bundle.

**Source:** `lib/relyra.ex`

### :request_intent_not_found

**Means:** The request-intent token from the Response did not match any
record in the request store.

**Likely root cause:** Request store eviction (TTL expiry while the user
was idle), a request initiated against a different SP replica without a
shared store, or an IdP-initiated response without prior SP-initiated
intent.

**Operator action:** Confirm the request store is the cluster-safe Ecto
adapter in production. If IdP-initiated is intentional, enable it via the
connection record's `:idp_initiated_allowed` flag.

**Source:** `lib/relyra/request_store/ecto.ex`, `lib/relyra/request_store/ets.ex`

### :in_response_to_mismatch

**Means:** The Response's `InResponseTo` attribute did not match the
request-intent token recorded by the SP when the AuthnRequest was sent.

**Likely root cause:** Cross-session response delivery, an IdP cache that
re-delivered an old response, or an active substitution probe.

**Operator action:** Treat as hostile until proven otherwise. Capture the
diagnostic bundle.

**Source:** `lib/relyra/protocol/validation_pipeline.ex`

## Metadata Lifecycle

These atoms fire during metadata import, apply, or auto-refresh — trust
state either never mutated, or mutated under operator-staged quarantine.

### :metadata_missing_entity_id

**Means:** The parsed metadata had no `entityID` attribute on the root
element.

**Likely root cause:** Malformed IdP metadata XML, or a metadata source
that is not a proper `<EntityDescriptor>` document.

**Operator action:** Re-fetch the metadata from a trusted IdP source.
Inspect via `mix relyra.diagnostic` (the bundle includes the staged
metadata document).

**Source:** `lib/relyra/metadata/parser.ex`

### :metadata_missing_sso_service

**Means:** No `<SingleSignOnService>` element was found under the IdP
descriptor.

**Likely root cause:** The metadata blob is an SP metadata document (not
IdP), or the IdP has emitted incomplete metadata.

**Operator action:** Confirm with the IdP vendor that the metadata is for
the IdP role and includes at least one SSO service binding.

**Source:** `lib/relyra/metadata/parser.ex`

### :metadata_missing_certificate

**Means:** No `<KeyDescriptor>` certificate suitable for signing was found
in the IdP metadata.

**Likely root cause:** Metadata blob missing key material, or the IdP
emitting only encryption certs without signing.

**Operator action:** Coordinate with the IdP to publish a signing
`<KeyDescriptor>`. Relyra cannot verify signatures without a configured
cert.

**Source:** `lib/relyra/metadata/parser.ex`

### :metadata_wrong_root

**Means:** The metadata XML root was not `<EntityDescriptor>` or
`<EntitiesDescriptor>`.

**Likely root cause:** Wrong file type imported, or an HTML error page
returned by the metadata endpoint.

**Operator action:** Inspect the source URL. If the endpoint returns HTML,
re-derive the correct metadata URL with the IdP vendor.

**Source:** `lib/relyra/metadata/parser.ex`

### :metadata_fetch_failed

**Means:** The auto-refresh or manual refresh worker failed to retrieve
metadata from the configured URL — the request reached a network endpoint
but the response was not usable metadata.

**Likely root cause:** Metadata endpoint returning HTTP error, body not
matching SAML metadata shape, or transient upstream failure.

**Operator action:** Inspect `[:relyra, :saml, :metadata, :refresh]`
telemetry. Run `mix relyra.refresh_due` manually to reproduce.

**Source:** `lib/relyra/metadata/auto_refresh.ex`, `lib/relyra/metadata/refresh.ex`

### :metadata_source_not_found

**Means:** A metadata source identifier referenced in the connection
record had no corresponding row in the metadata-source registry.

**Likely root cause:** Misconfigured connection, or a metadata source
that was deleted while connections still pointed at it.

**Operator action:** Inspect the connection via
`/relyra/admin/connections/:connection_id/edit`. Re-link to a valid
metadata source or stage a new one via metadata import.

**Source:** `lib/relyra/metadata.ex`, `lib/relyra/metadata/refresh.ex`

### :metadata_drift_requires_review

**Means:** The auto-refresh worker observed a material change in the IdP
metadata (new signing cert, changed SSO endpoint) and staged it as `:next`
rather than applying it directly. Trust state did NOT shift implicitly.

**Likely root cause:** Legitimate IdP key rotation, endpoint migration, or
an active metadata-substitution probe (which `trust_anchor_mismatch` will
also reject).

**Operator action:** Review the staged change via
`/relyra/admin/connections/:connection_id/metadata`. Promote `:next` to
active only after out-of-band verification with the IdP. The auto-refresh
telemetry records the drift event; the audit ledger records the operator
promotion.

**Source:** `lib/relyra/metadata/auto_refresh.ex`

### :invalid_metadata_source

**Means:** A metadata-source registration was rejected for malformed
shape (e.g. missing URL, invalid kind, or contradictory fields).

**Likely root cause:** Operator typo at registration time, or a programmatic
caller passing the wrong struct shape.

**Operator action:** Capture the input record from the audit ledger; correct
and re-register via the admin UI.

**Source:** `lib/relyra/metadata.ex`

### :invalid_record_validity_warning_inputs

**Means:** A metadata `record-validity-warning` audit was attempted with
inputs that did not match the expected record-shape contract — a defensive
guard that fails the operation rather than emitting a malformed audit row.

**Likely root cause:** Internal contract drift in the metadata-apply
pipeline.

**Operator action:** Capture the diagnostic bundle. This atom indicates an
internal invariant violation; file a Relyra issue with the bundle attached.

**Source:** `lib/relyra/ecto/metadata_apply.ex`

### :invalid_resume_auto_refresh_inputs

**Means:** A `resume-auto-refresh` operation was invoked with inputs that
did not match the expected shape (typically attempting to resume a
connection that has no suspended source).

**Likely root cause:** Operator action against a connection whose
auto-refresh is not in `:suspended` state.

**Operator action:** Inspect the connection's auto-refresh status via
`/relyra/admin/connections/:connection_id/metadata` before invoking resume.

**Source:** `lib/relyra/ecto/metadata_apply.ex`

## Network / Fetch

These atoms fire on the outbound metadata fetch path — Relyra could not
reach the IdP metadata source. They classify the failure for operator
triage; the unified `:metadata_fetch_failed` is the rollup, while these are
the underlying classifications.

### :fetch_connection_refused

**Means:** The metadata fetch could not establish a TCP connection — the
upstream actively refused.

**Likely root cause:** IdP endpoint down, firewall rule, or wrong port.

**Operator action:** Verify the configured metadata URL is reachable from
the host (`curl` or equivalent from the same network). Check IdP status.

**Source:** `lib/relyra/metadata/auto_refresh.ex`

### :fetch_dns_failure

**Means:** DNS resolution for the metadata URL host failed.

**Likely root cause:** Stale DNS, internal resolver outage, or wrong
hostname.

**Operator action:** Verify resolver health and the configured URL.

**Source:** `lib/relyra/metadata/auto_refresh.ex`

### :fetch_http_4xx

**Means:** The metadata endpoint returned a 4xx HTTP status.

**Likely root cause:** Wrong URL (404), revoked credential (401/403), or
URL deprecated by the IdP.

**Operator action:** Re-confirm the metadata URL with the IdP. Check any
required credentials or IP allowlists.

**Source:** `lib/relyra/metadata/auto_refresh.ex`

### :fetch_http_5xx

**Means:** The metadata endpoint returned a 5xx HTTP status.

**Likely root cause:** Transient IdP outage, or an upstream proxy fault.

**Operator action:** Retry after backoff. If persistent, escalate to the
IdP vendor.

**Source:** `lib/relyra/metadata/auto_refresh.ex`

### :fetch_timeout

**Means:** The metadata fetch did not complete within the configured
timeout.

**Likely root cause:** Slow upstream, overloaded network path, or a
configured timeout that is too tight.

**Operator action:** Verify upstream health. If consistently slow,
raise the fetch timeout via configuration — but log the rationale.

**Source:** `lib/relyra/metadata/auto_refresh.ex`

### :fetch_tls_handshake

**Means:** TLS handshake to the metadata endpoint failed — cipher
mismatch, expired cert, or hostname mismatch.

**Likely root cause:** Upstream cert expiry, TLS misconfiguration, or
a deliberate MITM.

**Operator action:** Verify the upstream cert via an external tool
(`openssl s_client`). If unexpected MITM signs, escalate immediately.

**Source:** `lib/relyra/metadata/auto_refresh.ex`

## Binding & Protocol Shape

These atoms fire on protocol structural gates — the request shape, binding,
timing, audience, or issuer did not match the connection's contract. They
include the SLO (Single Logout) atoms; see the SLO subset callout at the
end of this section.

### :authn_request_invalid

**Means:** An outbound or inbound AuthnRequest failed structural validation
(missing required field, malformed binding, or invalid endpoint shape).

**Likely root cause:** Programmatic caller passed an incomplete request, or
a buggy IdP-initiated probe.

**Operator action:** Inspect the request via `mix relyra.diagnostic`.
Confirm the connection record's bindings and endpoints are populated.

**Source:** `lib/relyra/protocol/authn_request.ex`

### :invalid_binding

**Means:** A logout request or response arrived via a binding the
connection does not allow.

**Likely root cause:** IdP using a binding that Relyra has not been
configured to accept for that connection.

**Operator action:** Align the connection's permitted logout bindings with
the IdP. Coordinate via the admin UI.

**Source:** `lib/relyra/security/logout_validator.ex`

### :invalid_binding_payload

**Means:** The binding-level payload shape was wrong (e.g. POST-binding
body without a `SAMLResponse` field, or redirect-binding query without
required parameters).

**Likely root cause:** A misbehaving SAML proxy, or a request that did not
originate at the intended endpoint.

**Operator action:** Inspect the raw request via `mix relyra.diagnostic`.
Verify the IdP is targeting the correct binding endpoint.

**Source:** `lib/relyra/protocol/binding.ex`, `lib/relyra/security/logout_validator.ex`

### :invalid_redirect

**Means:** A redirect-binding request was malformed at the URL level
(missing required query parameters, malformed signature parameters, or
unrecognized parameter shape).

**Likely root cause:** Truncated URL, encoding error, or an IdP not
following the SAML redirect binding spec.

**Operator action:** Inspect the raw URL via `mix relyra.diagnostic`.

**Source:** `lib/relyra/security/redirect.ex`

### :invalid_idp_sso_url

**Means:** The connection record's IdP SSO URL is malformed or absent.

**Likely root cause:** Misconfigured connection, or a metadata import that
did not capture the SSO endpoint.

**Operator action:** Re-import the IdP metadata or correct the URL via
`/relyra/admin/connections/:connection_id/edit`.

**Source:** `lib/relyra.ex`

### :invalid_logout_payload

**Means:** A logout request or response payload failed shape validation
before reaching the binding/signature gates.

**Likely root cause:** Malformed logout request, partial delivery, or a
non-conformant IdP.

**Operator action:** Capture the payload; coordinate with the IdP if the
logout binding is in regular use.

**Source:** `lib/relyra.ex`

### :logout_request_invalid

**Means:** An inbound `<LogoutRequest>` failed structural validation — the
parsed document was well-formed XML but did not match the SAML SLO request
contract.

**Likely root cause:** Non-conformant IdP, or a probe.

**Operator action:** Inspect the request via `mix relyra.diagnostic`.

**Source:** `lib/relyra/protocol/logout_request.ex`

### :logout_response_invalid

**Means:** An inbound `<LogoutResponse>` failed structural validation —
missing required fields, wrong status code shape, or absent issuer.

**Likely root cause:** IdP error or incomplete SLO chain.

**Operator action:** Capture the response; the host may need to handle SLO
as best-effort per
[`guides/recipes/logout.md`](recipes/logout.md).

**Source:** `lib/relyra/protocol/logout_response.ex`

### :relay_state_mismatch

**Means:** The Response's `RelayState` did not match the opaque value
Relyra issued at the AuthnRequest.

**Likely root cause:** Cross-session response delivery, or a substitution
probe.

**Operator action:** Treat as suspicious; capture the diagnostic bundle and
have the user re-initiate login from a clean session.

**Source:** `lib/relyra.ex`

### :relay_state_missing

**Means:** A Response that requires RelayState (because Relyra issued one
on the outbound AuthnRequest) arrived without one.

**Likely root cause:** Buggy IdP that drops RelayState, or proxy
interference.

**Operator action:** Confirm the IdP is round-tripping RelayState. The
default policy requires RelayState binding.

**Source:** `lib/relyra.ex`

### :relay_state_rejected

**Means:** The supplied RelayState was a raw URL (not an opaque
SP-issued token), and Relyra refuses to redirect to caller-controlled
URLs.

**Likely root cause:** Legacy IdP integration that uses RelayState as a
redirect URL, or an open-redirect probe.

**Operator action:** Switch to opaque RelayState (the default). Never
accept caller-controlled redirect URLs at the trust boundary.

**Source:** `lib/relyra/security/relay_state.ex`

### :missing_protocol_field

**Means:** A required SAML protocol field was absent from the parsed
document (the field name is in the error `details`).

**Likely root cause:** Non-conformant IdP, truncated payload, or a probe.

**Operator action:** Inspect the payload via `mix relyra.diagnostic`; the
field name in `details` identifies the missing element.

**Source:** `lib/relyra/security/logout_validator.ex`

### :destination_mismatch

**Means:** The Response's `Destination` attribute did not match the SP's
configured ACS URL for this binding.

**Likely root cause:** Response intended for a different SP replica, an
IdP misconfiguration, or a substitution probe.

**Operator action:** Verify the SP `acs_url` matches what is published in
SP metadata and configured in the IdP.

**Source:** `lib/relyra/protocol/response.ex`

### :recipient_mismatch

**Means:** The Assertion's `SubjectConfirmationData/@Recipient` did not
match the SP's configured ACS URL.

**Likely root cause:** Assertion intended for a different SP, or a probe.

**Operator action:** Confirm the IdP is issuing assertions targeted at
this SP. Capture the diagnostic bundle.

**Source:** `lib/relyra/protocol/assertion.ex`

### :assertion_expired

**Means:** The Assertion's `Conditions/@NotOnOrAfter` timestamp is in the
past relative to the SP's clock (within the configured skew tolerance).

**Likely root cause:** Slow user (e.g. paused at MFA challenge), excessive
SP/IdP clock skew, or a replayed-from-archive probe.

**Operator action:** Verify NTP sync on the SP host. If a legitimate
slow-user path, the user should retry.

**Source:** `lib/relyra/protocol/assertion.ex`

### :assertion_not_yet_valid

**Means:** The Assertion's `Conditions/@NotBefore` timestamp is in the
future relative to the SP's clock.

**Likely root cause:** SP clock running behind, or IdP issuing
post-dated assertions.

**Operator action:** Verify NTP sync on the SP host. Coordinate with
IdP if their assertions are systematically post-dated.

**Source:** `lib/relyra/protocol/assertion.ex`

### :subject_confirmation_expired

**Means:** The `SubjectConfirmationData/@NotOnOrAfter` timestamp on the
bearer subject confirmation is in the past.

**Likely root cause:** Same family as `:assertion_expired` — but
specifically scoped to the subject-confirmation window, which is typically
tighter.

**Operator action:** Same as `:assertion_expired` — verify clocks; user
retry.

**Source:** `lib/relyra/protocol/assertion.ex`

### :clock_skew_exceeded

**Means:** The Assertion timing checks failed even after applying the
configured skew tolerance — the gap between SP and IdP clocks is too
wide.

**Likely root cause:** Severe NTP drift on either side.

**Operator action:** Fix NTP. Do NOT silently widen the skew tolerance to
mask drift — that loosens the assertion validity window.

**Source:** `lib/relyra/protocol/assertion.ex`

### :invalid_audience

**Means:** The Assertion's `Conditions/AudienceRestriction/Audience` does
not match the SP's configured `sp_entity_id`.

**Likely root cause:** Assertion intended for a different SP, an
IdP-side audience misconfiguration, or a substitution probe.

**Operator action:** Verify the SP `entity_id` matches both SP metadata
and the IdP-side relying-party configuration.

**Source:** `lib/relyra/protocol/assertion.ex`

### :connection_binding_mismatch

**Means:** The Response arrived on a binding that the connection record
does not permit (e.g. HTTP-Redirect Response when only POST is allowed).

**Likely root cause:** IdP using an unconfigured binding.

**Operator action:** Align the connection's allowed bindings with what
the IdP emits, or instruct the IdP to use the configured binding.

**Source:** `lib/relyra/protocol/response.ex`

### :issuer_mismatch

**Means:** The Response, Assertion, or LogoutRequest `<Issuer>` did not
match the connection's configured IdP entity ID.

**Likely root cause:** Cross-connection response delivery (wrong tenant),
IdP misconfiguration, or a substitution probe.

**Operator action:** Confirm the tenant resolution wired up the right
connection. If the IdP entity ID changed, stage the new value via the
admin UI.

**Source:** `lib/relyra/protocol/response.ex`, `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra/security/logout_validator.ex`

### :unsupported_status

**Means:** The Response's top-level `<StatusCode>` was an unrecognized URI
or a known failure code (e.g. `urn:oasis:names:tc:SAML:2.0:status:Responder`).

**Likely root cause:** IdP reported a failed authentication, an unknown
SAML status, or — for a known-failure code — the user did not complete
the IdP flow.

**Operator action:** Inspect the status detail via `mix
relyra.diagnostic`. For known IdP-side failure codes (Responder /
Requester / AuthnFailed), the user must re-authenticate.

**Source:** `lib/relyra/protocol/response.ex`

### :idp_initiated_not_allowed

**Means:** An IdP-initiated Response arrived but the connection's
`idp_initiated_allowed` flag is `false` (the default).

**Likely root cause:** IdP dashboard tile pointing at this SP, or an
unsanctioned IdP-initiated probe.

**Operator action:** If IdP-initiated is intentional for this tenant,
flip the connection flag via
`/relyra/admin/connections/:connection_id/edit`. Otherwise reject —
IdP-initiated SSO has a strict trust posture (RelayState anti-replay,
opaque tokens) and is off by default.

**Source:** `lib/relyra/protocol/validation_pipeline.ex`

### :internal_protocol_error

**Means:** Catch-all for "should never happen" internal contract
violations — an Ecto transaction returned an unexpected shape, a
non-conformant resolver result, or a programmatic invariant tripped.

**Likely root cause:** Internal Relyra defect, dependency upgrade
incompatibility, or contract drift between a behaviour and its caller.

**Operator action:** Capture the diagnostic bundle and file a Relyra
issue. This atom indicates a Relyra-side defect, not an IdP
misconfiguration.

**Source:** `lib/relyra.ex`, `lib/relyra/ecto/certificate_inventory.ex`, `lib/relyra/ecto/connections.ex`, `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/ecto/metadata_apply.ex`, `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra/replay_store/ecto.ex`, `lib/relyra/request_store/ecto.ex`

**SLO subset.** The Single Logout flow shares its protocol-shape gates with
the rest of this section but emits three SLO-specific atoms that operators
will look for by name: `:logout_request_invalid`, `:logout_response_invalid`,
and `:invalid_logout_payload`. These appear above with their canonical
micro-blocks. The structural validators in
`lib/relyra/security/logout_validator.ex` also reuse the cross-cutting
`:invalid_binding`, `:invalid_binding_payload`, `:issuer_mismatch`,
`:missing_protocol_field`, `:invalid_signature`, and `:missing_signature`
atoms documented above (and in Signature & Crypto for the latter two). For
the operational story of when to use front-channel SLO vs stateful
fallback timeouts, see
[`guides/recipes/logout.md`](recipes/logout.md).

## Configuration & Adapter Wiring

These atoms fire when an adapter, resolver, or connection record is missing
or malformed — Relyra never had a working seam to verify against. They are
the configuration-time and adapter-wiring failure class.

### :adapter_not_configured

**Means:** A required adapter (replay store, request store, session
adapter, user mapper, key resolver, or connection resolver) was not
configured for the active env.

**Likely root cause:** Incomplete app config, or a programmatic caller
running before `Relyra.Application` started.

**Operator action:** Confirm the relevant adapter module is wired in app
config. See `mix help relyra.install` for the canonical scaffold.

**Source:** `lib/mix/tasks/relyra.install.ex`, `lib/relyra/ecto/connections.ex`, `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/ecto/metadata_apply.ex`, `lib/relyra/key_resolver.ex`, `lib/relyra/live_admin/query.ex`, `lib/relyra/metadata.ex`, `lib/relyra/metadata/refresh.ex`, `lib/relyra/metadata/source_registry.ex`, `lib/relyra/replay_store.ex`, `lib/relyra/replay_store/default.ex`, `lib/relyra/request_store.ex`, `lib/relyra/request_store/default.ex`, `lib/relyra/session_adapter.ex`, `lib/relyra/session_adapter/default.ex`, `lib/relyra/user_mapper.ex`

### :optional_dependency_missing

**Means:** A code path required an optional Hex dependency (Ecto, Oban,
Postgrex) that was not present in the host app.

**Likely root cause:** Calling an Ecto-backed adapter without `:ecto` in
the host app's deps, or scheduling auto-refresh without `:oban`.

**Operator action:** Add the missing optional dependency to the host
`mix.exs` and re-run `mix deps.get`. Relyra's optional deps are declared
explicitly so the dependency graph stays minimal for hosts that do not
need them.

**Source:** `lib/relyra/ecto/audit_writer.ex`, `lib/relyra/ecto/certificate_inventory.ex`, `lib/relyra/ecto/connections.ex`, `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/ecto/metadata_apply.ex`, `lib/relyra/metadata/refresh.ex`, `lib/relyra/metadata/scheduler.ex`, `lib/relyra/metadata/source_registry.ex`, `lib/relyra/optional_deps/oban.ex`, `lib/relyra/replay_store/ecto.ex`, `lib/relyra/request_store/ecto.ex`, `lib/relyra/security/certificate_expiry.ex`

### :unsupported_default_adapter

**Means:** The default request-store or replay-store adapter was requested
in an environment where it is unsafe (e.g. ETS adapter in production
without explicit opt-in).

**Likely root cause:** Production deployment that did not configure the
cluster-safe Ecto adapter.

**Operator action:** Configure the Ecto-backed adapter in production. ETS
is a single-node development convenience; using it in production is a
silent-bypass class.

**Source:** `lib/relyra/replay_store/default.ex`, `lib/relyra/request_store/default.ex`

### :resolver_failed

**Means:** The connection resolver returned an error tuple at runtime —
the resolver itself ran but did not produce a connection record.

**Likely root cause:** Resolver callback raised, returned an
unexpected shape, or timed out talking to its backing store.

**Operator action:** Inspect the resolver telemetry. Confirm the resolver
implementation matches the `Relyra.ConnectionResolver` behaviour.

**Source:** `lib/relyra/connection_resolver.ex`, `lib/relyra/ecto/connection_snapshot.ex`

### :resolver_misconfigured

**Means:** The connection resolver is missing required configuration or
points at an invalid backing store.

**Likely root cause:** Incomplete resolver config in app config, or the
resolver pointing at an Ecto repo that is not started.

**Operator action:** Verify the resolver configuration. The
`Relyra.ConnectionResolver.Ecto` adapter requires a started repo and the
connection schema migrations applied.

**Source:** `lib/relyra/connection_resolver.ex`, `lib/relyra/connection_resolver/default.ex`, `lib/relyra/connection_resolver/ecto.ex`, `lib/relyra/ecto/certificate_inventory.ex`, `lib/relyra/ecto/connection_loader.ex`, `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/ecto/metadata_apply.ex`

### :connection_invalid

**Means:** A persisted connection record failed snapshot validation when
hydrating into the runtime `%Relyra.Connection{}` value struct.

**Likely root cause:** A connection row that was migrated from an older
schema, or one with missing required fields.

**Operator action:** Inspect the connection row via the admin UI. Edit to
populate the missing fields, or stage a fresh import.

**Source:** `lib/relyra/ecto/connection_snapshot.ex`

### :connection_not_found

**Means:** A lookup by `connection_id` returned no row in the connection
store.

**Likely root cause:** Connection deleted while still referenced in
config, a tenant resolver yielding an unknown ID, or a typo.

**Operator action:** Confirm via `/relyra/admin` that the connection
exists. Audit who deleted it and when via the audit ledger.

**Source:** `lib/relyra/ecto/certificate_inventory.ex`, `lib/relyra/ecto/connections.ex`, `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/ecto/metadata_apply.ex`, `lib/relyra/live_admin/query.ex`, `lib/relyra/metadata.ex`, `lib/relyra/metadata/auto_refresh.ex`, `lib/relyra/metadata/refresh.ex`, `lib/relyra/metadata/source_registry.ex`

### :connection_not_runtime_ready

**Means:** The connection record exists but is not in a state suitable
for serving production logins (e.g. no active IdP cert, no SSO URL, or
explicitly disabled).

**Likely root cause:** Connection imported but not yet operator-enabled,
or temporarily disabled during a staged rollover.

**Operator action:** Promote the connection via the admin UI after
verifying the staged state.

**Source:** `lib/relyra/ecto/connection.ex`

### :connection_unavailable

**Means:** The connection store could not be reached to load the
connection (typically a database outage or a resolver returning an
empty pool).

**Likely root cause:** Database outage or repo not started.

**Operator action:** Verify database health and that the host app's repo
is started.

**Source:** `lib/relyra/connection_resolver/ecto.ex`, `lib/relyra/ecto/connection_loader.ex`

### :invalid_connection_record

**Means:** A mutation against a connection record was rejected because
the input did not match the schema contract (changeset validation failed
at the audit-co-commit boundary).

**Likely root cause:** Programmatic caller passed a malformed connection
struct, or an admin UI form submission with corrupted fields.

**Operator action:** Inspect the audit ledger for the attempted mutation;
the rejection includes the failing field. Re-submit a valid record.

**Source:** `lib/relyra/ecto/audit_writer.ex`, `lib/relyra/ecto/certificate_facts.ex`, `lib/relyra/ecto/certificate_inventory.ex`, `lib/relyra/ecto/connections.ex`, `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/ecto/metadata_apply.ex`, `lib/relyra/live_admin/connections_live.ex`, `lib/relyra/metadata.ex`, `lib/relyra/metadata/import.ex`, `lib/relyra/metadata/refresh.ex`, `lib/relyra/metadata/source_registry.ex`

### :diagnostic_bundle_failed

**Means:** `mix relyra.diagnostic` could not produce a redacted bundle
(filesystem error, denied output path, or an internal contract violation
on the allow-list).

**Likely root cause:** Wrong output path permissions, or an internal
defect.

**Operator action:** Check the bundle output path is writable. If
persistent, file a Relyra issue with the inner error.

**Source:** `lib/relyra/diagnostic.ex`

## Next steps

Once you have decoded the atom, follow the matching scenario runbook in
[`guides/operations/incident_playbook.md`](operations/incident_playbook.md).
The playbook stitches Relyra telemetry, the audit ledger, the LiveView
admin UI, and the Mix-task hand-tools into a single Triage → Diagnose →
Recover narrative for each common incident class.

When in doubt — or when you need a complete redacted evidence bundle for an
incident review — run `mix relyra.diagnostic`. Every login resolves to a
verified trust path or a typed rejection; when in doubt, the diagnostic
bundle is the trace.
