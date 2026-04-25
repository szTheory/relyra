Ultimate SAML 2.0 Service Provider Library for Elixir/Phoenix

Research snapshot: April 24, 2026. Scope: a modern, security-first, Phoenix-native SAML 2.0 Service Provider library for B2B SaaS teams selling into enterprise customers.

Executive summary

The biggest opportunity is not merely “write a SAML library.” It is to become the trusted default for Elixir/Phoenix teams that need enterprise SSO without becoming SAML experts.

The Elixir ecosystem still has a trust gap. samly is a Plug/Phoenix SAML SP library and Hex shows it has meaningful usage, but its latest Hex release is v1.4.0 from January 29, 2024. It depends on esaml, and a 2026 NVD entry reports an XXE vulnerability in esaml and forks that can read local files or perform SSRF before signature verification on Erlang/OTP versions before 27. That makes “maintenance and security posture” a first-class product requirement, not an afterthought.  ￼

There is also a new ex_saml package on Hex, v1.0.2, published April 16, 2026, that positions itself as a Samly-derived successor with SP-initiated and IdP-initiated SSO, SLO, metadata generation, multi-IdP support, pluggable assertion storage, relay-state anti-replay, and hardened XML defaults. Hex currently shows very low adoption signals, and the GitHub repo is small, so the opportunity remains: either outperform it, collaborate, or learn from it as an early successor attempt.  ￼

The “ultimate” Phoenix SAML library should be:

1. Secure by default: strict validation, no unsigned assertions, no unsafe XML parsing, no SHA-1 by default, replay cache required, IdP-initiated SSO behind explicit controls.
2. Phoenix-native: router macro, Plug pipeline, generators, LiveView admin UI, Ecto schemas, telemetry, logs, test helpers.
3. Operationally mature: certificate expiry alerts, metadata refresh, audit events, clear error taxonomy, support tooling.
4. Multi-tenant first: per-organization SAML connections, dynamic IdP resolution, group/attribute mapping, JIT provisioning hooks.
5. Designed for supportability: provider presets for Okta, Microsoft Entra ID, Google Workspace, Ping, OneLogin, ADFS, Shibboleth, Keycloak.
6. Sustainable OSS: visible security policy, CI matrix, adversarial test corpus, release automation, changelog discipline, documented compatibility.

⸻

Product thesis

A great Phoenix SAML library should feel less like a protocol toolkit and more like an enterprise SSO subsystem.

The user-facing promise:

“Add secure, observable, multi-tenant SAML SSO to a Phoenix SaaS app in one afternoon; operate it safely for years.”

The maintainer-facing promise:

“A protocol core with enough isolation, tests, and fuzz/adversarial fixtures that security fixes do not become panic rewrites.”

The buyer/customer-admin promise:

“My IT team can configure SSO without a month of ticket ping-pong.”

⸻

Market and ecosystem position

Elixir/Phoenix state

samly did several important things right. It targeted Plug/Phoenix directly, supported multiple IdPs, documented use with Okta, Ping Identity, OneLogin, ADFS, Shibboleth, and SimpleSAMLphp, and exposed a pluggable state-store concept. That is the shape of the problem: Elixir teams want framework integration, not a raw XML toolkit.  ￼

The current gap is confidence. A SAML library is part of the authentication boundary, so “mostly works” is not enough. A SAML SP package needs reliable ownership, security response, explicit compatibility, and adversarial tests. The esaml XXE issue is especially instructive because it happened before signature verification: even invalid SAML can be dangerous if XML parsing is unsafe.  ￼

ex_saml is worth tracking. It already implements several obvious successor ideas: path/subdomain IdP resolution, pluggable storage, relay-state anti-replay, XML entity disabling, SHA-1 rejection, and migration guidance from Samly. But its adoption footprint is early, and it appears to remain close to the Samly/esaml lineage.  ￼

Other ecosystems

Ruby’s omniauth-saml demonstrates the value of a thin, idiomatic framework strategy over a lower-level SAML engine. It is a generic OmniAuth strategy, has a documented SemVer/security-upgrade policy, supports Rails-style middleware usage, and had a recent v2.2.5 release in February 2026.  ￼

Ruby also demonstrates the danger. ruby-saml has had repeated critical vulnerabilities, including CVE-2024-45409, where an attacker with any signed SAML document from the IdP could forge a SAML Response/Assertion and log in as an arbitrary user. Later 2025 issues involved parser differentials between REXML and Nokogiri, where different XML parsers interpreted the same document differently during signature verification.  ￼

Node’s @node-saml/passport-saml shows useful architecture lessons: split core protocol support from the Passport integration, support MultiSamlStrategy for multi-provider apps, and enforce security invariants such as requiring either the response or assertion to be signed. The Node ecosystem also shows fork pressure as a signal: the Suomi.fi fork existed to add hardening, then migrated back upstream once upstream added the missing capabilities.  ￼

Python’s OneLogin-backed python3-saml shows the value of explicit security modes and strong changelog warnings. Its README documents strict mode becoming default, SHA-256 defaults, XXE/XPath protections, signature-validation fixes, and signature-wrapping history.  ￼

Spring Security and Sustainsys show what “framework-native” looks like: model the relationship between the relying party/SP and asserting party/IdP as a registration/configuration object; parse and publish metadata; support refreshable metadata repositories; and integrate with the host framework’s authentication machinery.  ￼

Go’s crewjam/saml shows another useful split: core SAML package, SP middleware package, and rudimentary IdP for testing. Its maintainers also discussed modularizing request tracking, session handling, and error handling because users needed extension points without forking.  ￼

⸻

Personas and jobs-to-be-done

1. Phoenix SaaS engineer

Job: “An enterprise customer requires SAML before signing. I need it working safely this week.”

Needs:

* Phoenix router macro and Plug integration.
* Clear generated migrations.
* Provider presets.
* Copy-pasteable Okta/Entra/Google setup docs.
* Local dev IdP.
* Clear error messages.
* Safe defaults that do not require knowing the SAML spec.

Success looks like:

# router.ex
scope "/sso", MyAppWeb do
  pipe_through [:browser]
  saml_routes MyApp.SSO,
    connection_resolver: MyApp.SSO.ConnectionResolver,
    session_adapter: MyAppWeb.SAMLSession
end

2. Platform/auth team

Job: “We need a maintainable multi-tenant enterprise SSO subsystem.”

Needs:

* Dynamic per-tenant IdP resolution.
* Multiple active certificates during rollover.
* Ecto-backed connection config.
* Replay cache that works across a cluster.
* Group and attribute mapping.
* JIT provisioning hooks.
* Admin audit logs.
* Versioned config changes.

3. Customer IT admin

Job: “I need to configure my company’s IdP without back-and-forth with vendor support.”

Needs:

* Self-service admin UI.
* Downloadable SP metadata.
* Visible ACS URL, Entity ID, SLO URL.
* Metadata upload or metadata URL import.
* Test connection button.
* Attribute preview.
* Certificate expiry warning.
* Provider-specific instructions.

Okta’s own SAML planning guide specifically calls out that ISVs should expose a self-service administrator page, accept IdP metadata, and generate SP metadata for the IdP.  ￼

4. Security engineer

Job: “Prove this implementation does not accept forged, replayed, expired, or misdirected assertions.”

Needs:

* Strict validation checklist.
* Security.md and disclosure process.
* Threat model.
* Test vectors for known SAML CVEs.
* Algorithm policy.
* Redacted logs.
* Audit events.
* No unsafe “just make it pass” flags.

5. SRE/DevOps

Job: “Keep SSO reliable and diagnosable after launch.”

Needs:

* Telemetry events.
* Metrics by connection/provider.
* Health checks for metadata freshness and certificate expiry.
* Structured error taxonomy.
* Non-PII debugging.
* Runbooks.
* Dashboards.
* Alertable certificate and metadata conditions.

6. OSS maintainer

Job: “Sustain a security-sensitive library without burning out.”

Needs:

* Small protocol core.
* Stable public API.
* CI matrix.
* Fuzz/adversarial tests.
* Release automation.
* Dependabot/Renovate.
* Documented support window.
* Security advisory workflow.
* Clear boundaries for what is and is not supported.

⸻

Domain language

SAML is a domain with its own overloaded vocabulary. The library should make the right words visible in code, docs, telemetry, errors, and UI. OASIS describes SAML as an XML-based framework for exchanging security information between parties, with assertions, protocol messages, bindings, profiles, and metadata as core concepts.  ￼

Actors and trust parties

Term	Meaning in this library	Preferred module/struct language
Principal	The human or subject being authenticated.	Elicit.SAML.Principal
Subject	The SAML assertion’s representation of the principal.	Subject, NameID, SubjectConfirmation
Identity Provider / IdP / Asserting Party	The customer’s system that authenticates users and issues assertions.	IdentityProvider, AssertingParty
Service Provider / SP / Relying Party	The Phoenix app consuming assertions and creating local sessions.	ServiceProvider, RelyingParty
Tenant / Organization / Customer Account	The SaaS customer that owns a SAML connection.	Organization, Tenant, Account
SAML Connection	The configured trust relationship between one tenant and one IdP.	SAML.Connection
User Mapper	App callback that maps a SAML principal to a local user.	UserMapper behaviour
Provisioner	App callback that creates/updates local users from SAML data.	Provisioner behaviour
Session Adapter	App callback that signs a user into Phoenix after assertion validation.	SessionAdapter behaviour
Connection Resolver	Resolves which tenant/IdP config applies to a request.	ConnectionResolver behaviour

OASIS terminology includes asserting party, relying party, requester/responder, IdP, SP, principal, and trust relationships; those should be reflected in docs, but app-facing Phoenix code should use the friendlier “SAML connection” abstraction.  ￼

Protocol documents and parameters

Term	Meaning	Notes
AuthnRequest	SP-created authentication request sent to IdP.	Should include unique ID, issuer, ACS URL, binding, optional NameIDPolicy, optional RequestedAuthnContext.
SAMLResponse	Browser-posted base64 response from IdP to ACS.	Contains status and one or more assertions or encrypted assertions.
Assertion	Signed statement about the subject/principal.	The security-bearing token.
EncryptedAssertion	Assertion encrypted for the SP.	Requires SP decryption key.
SubjectConfirmation	Proof that the assertion is intended for this SP/use.	Validate bearer method, Recipient, InResponseTo, NotOnOrAfter.
Conditions	Validity constraints.	Validate NotBefore, NotOnOrAfter, AudienceRestriction.
AudienceRestriction	Limits assertion to intended SP entity ID.	Mandatory validation.
AttributeStatement	User attributes such as email, name, groups.	Input to mapping/provisioning, not trust by itself.
AuthnStatement	Authentication event details.	Includes AuthnInstant, SessionIndex, AuthnContext.
LogoutRequest / LogoutResponse	SLO protocol messages.	Hard to support perfectly; expose carefully.
RelayState	Opaque state round-tripped through IdP.	Must not be an arbitrary open redirect.
MetadataDocument	XML describing endpoints, bindings, entity IDs, keys.	Used for import/export and rollover.

A typical SAML response includes ID, InResponseTo, Version, IssueInstant, Destination, Issuer, signed assertion, SubjectConfirmationData, conditions, audience, and authn statement fields. These names should appear in validation errors because they are what IdP admins and support teams need to debug.  ￼

Security and validation concepts

Term	Meaning	Library behavior
Signature	XMLDSig over response or assertion.	Verify against configured IdP certs only.
Signed node	Exact XML node covered by the verified signature.	Only consume the verified node.
Canonicalization	XML normalization used before signature/digest verification.	Treat as security-critical.
DigestValue	Hash of signed referenced node.	Validate as part of XMLDSig.
Issuer	Entity that issued response/assertion.	Must match configured IdP.
Audience	Intended SP entity ID.	Must match configured SP.
Destination	ACS endpoint receiving response.	Must match current ACS URL.
Recipient	Subject confirmation recipient.	Must match ACS URL.
InResponseTo	Links response/assertion to SP AuthnRequest.	Required for SP-initiated flows.
Request ID Store	Stores pending AuthnRequest IDs.	Cluster-safe in production.
Replay Cache	Tracks consumed assertion/response IDs.	Required in production.
Clock Skew	Allowed time drift.	Small configurable tolerance.
Algorithm Policy	Allowed signing/digest algorithms.	SHA-256+ default; SHA-1 rejected by default.
Certificate Rollover	Period with old and new IdP certs valid.	Support multiple certs and metadata refresh.
Unsafe Compatibility Mode	Explicit opt-in for legacy IdPs.	Must be loud, auditable, time-boxed.

OWASP’s SAML guidance emphasizes local schema validation, ignoring untrusted KeyInfo, avoiding signature-wrapping attacks, validating protocol processing rules, preventing replay, short response lifetimes, and allowlisting RelayState URLs for IdP-initiated flows.  ￼

Product/application concepts

Term	Meaning	Suggested schema or module
SAMLConnection	Tenant’s configured IdP relationship.	saml_connections
ConnectionStatus	Draft, testing, enabled, disabled, error.	enum
ProviderPreset	Okta, Entra, Google, Ping, OneLogin, ADFS, Shibboleth, Keycloak.	config module
AttributeMapping	Maps SAML attributes to local fields.	saml_attribute_mappings
GroupMapping	Maps SAML groups to roles/permissions.	saml_group_mappings
JITProvisioningPolicy	Whether/how to create/update users at login.	embedded schema
LoginAttempt	Record of SAML flow outcome.	saml_login_attempts
AuditEvent	Admin/config/security change event.	saml_audit_events
CertificateInventory	Active/backup/expired IdP and SP certs.	saml_certificates
MetadataRefreshJob	Fetches and validates IdP metadata.	Oban job optional
ConnectionTest	Synthetic login/config validation.	LiveView workflow

Core verbs and commands

Use these verbs in public API names, internal modules, docs, and event names:

Verb	Meaning
configure_connection	Create or update tenant SAML config.
import_metadata	Parse IdP metadata XML/URL into connection config.
generate_sp_metadata	Produce SP metadata for tenant/connection.
start_login	Begin SP-initiated SSO.
build_authn_request	Create AuthnRequest XML.
store_request_id	Persist pending AuthnRequest ID and relay state.
redirect_to_idp	Send browser to IdP via Redirect or POST binding.
consume_response	ACS entry point for SAMLResponse.
decode_response	Base64/inflate/form decoding.
parse_xml_safely	Hardened XML parse with no entities/network.
validate_signature	Verify XMLDSig with configured keys.
select_signed_assertion	Bind validation to exact signed assertion.
validate_conditions	Check time conditions and audience.
validate_subject_confirmation	Check bearer recipient, InResponseTo, expiry.
reject_replay	Atomically reject reused response/assertion IDs.
map_attributes	Convert SAML attributes to app identity.
provision_user	Create/update local user if policy allows.
establish_session	Sign user into Phoenix app.
finish_relay	Redirect to safe post-login destination.
start_logout	Begin SP-initiated logout.
consume_logout_request	Handle IdP-initiated logout.
refresh_metadata	Update IdP certs/endpoints from metadata URL.
rotate_certificate	Add/promote/retire IdP or SP certs.
test_connection	Run config checks or synthetic flow.
disable_connection	Turn off SAML for tenant.

Domain events

Use a consistent event vocabulary for telemetry, audit logs, and tests.

saml.connection.created
saml.connection.updated
saml.connection.enabled
saml.connection.disabled
saml.metadata.imported
saml.metadata.refresh.started
saml.metadata.refresh.succeeded
saml.metadata.refresh.failed
saml.certificate.added
saml.certificate.expiring
saml.certificate.expired
saml.certificate.rotated
saml.login.started
saml.authn_request.created
saml.authn_request.stored
saml.response.received
saml.response.decoded
saml.response.rejected
saml.assertion.validated
saml.assertion.rejected
saml.replay.detected
saml.relay_state.rejected
saml.user.mapped
saml.user.provisioned
saml.user.provisioning_rejected
saml.session.established
saml.logout.started
saml.logout.completed
saml.logout.failed
saml.unsafe_option.enabled

Error taxonomy

Errors should be stable, machine-readable atoms plus human-readable messages. Do not expose raw XML or PII by default.

Category	Error atoms
Decode/input	:missing_saml_response, :malformed_base64, :inflated_payload_too_large, :malformed_xml, :unsupported_binding
XML safety	:doctype_forbidden, :entity_expansion_forbidden, :external_reference_forbidden, :schema_invalid
Trust/signature	:unknown_idp, :missing_signature, :invalid_signature, :untrusted_certificate, :deprecated_algorithm, :signature_wrapping_suspected, :duplicate_xml_id
Protocol	:unsupported_status, :issuer_mismatch, :destination_mismatch, :recipient_mismatch, :in_response_to_missing, :in_response_to_mismatch
Conditions	:assertion_expired, :assertion_not_yet_valid, :invalid_audience, :clock_skew_exceeded, :replayed_assertion
Mapping	:missing_name_id, :missing_required_attribute, :ambiguous_user, :domain_not_allowed, :group_mapping_failed
Provisioning	:jit_disabled, :user_blocked, :user_create_failed, :user_update_failed
Operational	:metadata_fetch_failed, :metadata_signature_invalid, :certificate_expired, :request_store_unavailable, :replay_store_unavailable

⸻

Bounded contexts

1. Protocol Core

Pure SAML concerns. No Phoenix, Plug, Ecto, LiveView, or app sessions.

Responsibilities:

* Build AuthnRequest.
* Decode SAMLResponse.
* Hardened XML parse.
* Verify XMLDSig.
* Decrypt EncryptedAssertion.
* Validate protocol rules.
* Parse/generate metadata.
* Return typed results.

Suggested modules:

Elicit.SAML.Protocol.AuthnRequest
Elicit.SAML.Protocol.Response
Elicit.SAML.Protocol.Assertion
Elicit.SAML.Protocol.Logout
Elicit.SAML.Protocol.Metadata
Elicit.SAML.Protocol.Binding.Redirect
Elicit.SAML.Protocol.Binding.POST
Elicit.SAML.Security.XML
Elicit.SAML.Security.Signature
Elicit.SAML.Security.Encryption
Elicit.SAML.Security.AlgorithmPolicy

2. Trust and Metadata

Configures what the SP trusts.

Responsibilities:

* IdP certificate inventory.
* Metadata import/export.
* Metadata refresh.
* Certificate rollover.
* Entity ID and endpoint validation.
* Signature/encryption key separation.

OWASP identifies multiple certificate use cases in SAML, including IdP signing, SP signing, SP encryption, and IdP TLS, and recommends metadata URLs for certificate rotation where available.  ￼

3. Connection Management

Multi-tenant app configuration.

Responsibilities:

* Tenant-to-IdP relationship.
* Provider presets.
* Connection states.
* Attribute/group mapping config.
* Admin UI.
* Audit log.

4. Phoenix/Plug Runtime

Framework integration.

Responsibilities:

* Router macro.
* Plugs/controllers.
* ACS endpoint.
* Login/logout endpoints.
* Session adapter.
* Flash/error rendering.
* CSRF/session compatibility.

5. Identity Mapping and Provisioning

Application-specific user identity.

Responsibilities:

* Map NameID/attributes to local user.
* Enforce domain and tenant membership.
* JIT provisioning policy.
* Group-to-role mapping.
* Account linking.
* SCIM handoff.

Important boundary: SAML is authentication, not full lifecycle management. JIT provisioning is useful, but SCIM should remain a separate integration or extension point.

6. Observability and Audit

Operations and compliance.

Responsibilities:

* Telemetry.
* Structured redacted logs.
* Audit events.
* Debug bundles.
* Runbook messages.
* Admin-visible health checks.

⸻

Security invariants

These should be treated as non-negotiable defaults.

XML parsing

1. Disable DTDs, external entities, and network fetches.
2. Enforce input size limits before and after base64 decode/inflate.
3. Use local trusted schemas only if schema validation is performed.
4. Never auto-download schemas.
5. Never log raw assertions by default.
6. Treat parsing as hostile even before signature verification.

The esaml XXE CVE is the Elixir-specific warning: attacker-controlled SAML was parsed before signature verification without disabling XML entity expansion, enabling local file reads and possible SSRF.  ￼

Signature verification

1. Verify against configured IdP certificates, not KeyInfo from the document.
2. Bind the verified signature to the exact XML node consumed.
3. Reject duplicate XML IDs.
4. Reject ambiguous multiple assertions unless explicitly supported and safely selected.
5. Reject missing signatures by default.
6. Reject deprecated algorithms by default.
7. Add regression fixtures for known signature-wrapping and parser-differential attacks.

Ruby-SAML’s 2024 and 2025 vulnerabilities show why this must be central: attackers could use valid signed SAML documents to forge assertions, and parser differentials between XML parsers created authentication bypasses.  ￼

Protocol validation

Validate all of:

* Issuer
* Destination
* Recipient
* Audience
* InResponseTo
* NotBefore
* NotOnOrAfter
* SessionIndex where needed for logout
* response/assertion IDs
* status code
* tenant/connection match

OWASP calls out protocol processing as a common security gap and recommends validating AuthnRequest and Response processing rules to counter stolen assertions, MITM, forged assertions, and browser state exposure.  ￼

Replay defense

1. Store pending AuthnRequest IDs for SP-initiated flows.
2. Atomically consume request IDs.
3. Store consumed response/assertion IDs with TTL.
4. Require a cluster-safe store in production.
5. Support ETS only for local dev/single-node demos unless sticky sessions and risk are documented.

IdP-initiated SSO

Support it because enterprise IdP dashboards need it, but never pretend it is equivalent to SP-initiated SSO.

Default posture:

allow_idp_initiated?: false

When enabled:

* Require explicit tenant/connection binding.
* Require replay detection.
* Require RelayState allowlist or opaque server-side RelayState.
* Disable arbitrary redirect URLs.
* Audit that it was enabled.
* Document missing login-intent protection.

OWASP describes unsolicited/IdP-initiated SSO as inherently less secure because the SP cannot create a pre-login session or verify user login intent; it specifically calls for RelayState allowlisting and replay detection.  ￼

RelayState

RelayState should be an opaque handle by default:

RelayState = "rs_..." -> server-side record containing return_to, tenant_id, request_id, expires_at

Avoid:

RelayState = "https://customer-controlled.example/redirect"

Provider docs acknowledge RelayState is often used for deep-link continuation; the library should support that use case via server-side opaque state rather than trusting arbitrary URLs.  ￼

Algorithm policy

Default:

allowed_signature_algorithms: [
  :rsa_sha256,
  :rsa_sha384,
  :rsa_sha512,
  :ecdsa_sha256,
  :ecdsa_sha384,
  :ecdsa_sha512
],
allowed_digest_algorithms: [
  :sha256,
  :sha384,
  :sha512
],
reject_sha1?: true

Compatibility escape hatch:

legacy_algorithm_policy:
  allow_sha1_until: ~D[2026-12-31],
  reason: "Customer ADFS migration",
  audit: true

Logging and telemetry safety

Never log:

* raw SAMLResponse
* raw assertion XML
* decrypted assertions
* private keys
* full certificates unless explicitly requested in debug tooling
* full NameID/email in high-cardinality metrics

Safe to log:

* connection ID
* tenant ID
* IdP entity ID hash
* certificate fingerprint prefix
* validation step
* error atom
* timing
* payload byte sizes
* request ID hash

⸻

Lessons learned from existing libraries

What Samly did right

* Targeted Plug/Phoenix directly.
* Used familiar Phoenix routes.
* Supported multiple common enterprise IdPs.
* Had companion examples/how-to material.
* Exposed pluggable assertion storage.
* Solved enough of the problem to get real-world usage.

What Samly/esaml teaches as risk

* Core protocol dependency maintenance matters as much as wrapper maintenance.
* XML parser defaults can become CVEs.
* Forks by organizations are a signal of unmet operational/security needs.
* “Works with my IdP” is not enough without adversarial tests and security response.

What ExSaml appears to be doing right

* Recognizes the Samly maintenance/security gap.
* Adds provider resolution by path/subdomain.
* Adds relay-state anti-replay.
* Adds configurable storage/cache.
* Adds security headers.
* Explicitly addresses XXE and SHA-1 in the README.

Where a new library can still win

* Independent security architecture rather than patching the old lineage.
* Stronger docs and generators.
* Ecto-backed multi-tenant admin UI.
* First-class telemetry and audit.
* CI with real IdP containers and adversarial corpus.
* More explicit public behaviours and stable extension points.
* Better migration story from Samly and ExSaml.
* Security advisory process and long-term maintainer governance.

Ruby lessons

Ruby’s ecosystem demonstrates that adoption does not remove security risk. omniauth-saml provides nice framework integration, but it depends on lower-level SAML handling where repeated critical vulnerabilities have appeared. The lesson for Elixir: split framework integration from protocol core, but own the security contract end-to-end.  ￼

Node lessons

Node’s passport-saml/node-saml split is a strong pattern: a framework-agnostic core plus a framework adapter. Its multi-provider strategy is especially relevant for B2B SaaS. The Suomi.fi fork shows that government/enterprise adopters will fork to add hardening, but they will migrate back if upstream absorbs the hardening and exposes the right configuration surface.  ￼

Python lessons

python3-saml shows the importance of explicit security release notes and strict defaults. Its README documents when strict mode became default, when SHA-256 became default, and when XXE, XPath injection, signature validation, and signature wrapping issues were fixed. This is the kind of security history an auth library should make visible.  ￼

Spring/.NET lessons

Spring’s RelyingPartyRegistration is a strong naming/modeling pattern: one object represents the configured relationship between the SP/relying party and IdP/asserting party metadata. Spring also supports refreshable asserting-party metadata repositories and metadata signature verification. Sustainsys maps SAML options directly into ASP.NET Core authentication options, which is exactly the framework-native posture Phoenix needs.  ￼

Go lessons

Go’s crewjam/saml includes a core package, SP middleware, and a rudimentary IdP useful for testing. The modularization discussion around request tracking, session issuing, and error handling is directly applicable to Phoenix: these should be behaviours, not hardcoded implementation details.  ￼

⸻

Footguns to design out

1. “Disable signature validation to make the demo pass”

Never allow this casually. A library may support test mode, but production config must refuse unsigned assertions unless the user performs an explicit unsafe override with audit logging.

2. Signature wrapping

The app must consume only the signed assertion/response that was verified. Do not verify one XML node and read user attributes from another.

3. Parser differentials

Do not parse with one XML parser, canonicalize with another, and extract values with a third. Ruby-SAML’s parser-differential issues are a concrete example of why this matters.  ￼

4. XML before safety

Signature verification does not protect unsafe XML parsing that already happened. Disable entities and external references before any security decision.

5. RelayState open redirects

RelayState is often used for deep links, but arbitrary URL RelayState becomes an open redirect and sometimes a login confusion primitive.

6. IdP-initiated SSO as default

IdP-initiated SSO is common in enterprise dashboards, but it lacks SP-created login intent. Support it with warnings and controls, not as the default path.

7. Local ETS in clustered production

ETS replay/request stores are fine for local dev and single-node examples. Distributed Phoenix deployments need a shared store or carefully documented deployment constraints.

8. Certificate rollover as a support ticket

Enterprises rotate IdP signing certs. The library should support multiple active certs, metadata refresh, expiry warnings, and staged rollover.

9. Confusing NameID with email

NameID can be transient, persistent, unspecified, or email-like. Mapping should be explicit. Microsoft Entra, for example, can issue persistent, emailAddress, unspecified, or transient NameID formats depending on request/configuration.  ￼

10. Treating attributes as authorization without contract

SAML attributes can carry profile and authorization data, but OASIS notes that using attributes for authorization requires prior agreement on names and values. Build group mapping, but make it explicit and auditable.  ￼

11. Over-promising SLO

Single Logout is complex across IdPs, browser bindings, back channels, app sessions, and multiple SPs. Node’s Passport-SAML docs explicitly warn that fully functional IdP-initiated SLO is not provided out of the box and depends on deployment/use cases. Treat SLO as advanced, testable, and partial by provider.  ￼

⸻

Recommended architecture

Package layout

Use an umbrella of focused packages or one repo with optional dependencies:

elicit_saml_core
  Pure SAML protocol, metadata, XML security, validation.
elicit_saml_plug
  Plug routes, request/response integration, behaviours.
elicit_saml_phoenix
  Router macros, controllers, generators, Phoenix UX.
elicit_saml_ecto
  Optional schemas, migrations, config storage, audit tables.
elicit_saml_live_admin
  Optional LiveView admin UI.
elicit_saml_test_support
  Fixtures, fake IdP, Phoenix ConnCase helpers, signed response builders.

Single-package MVP is acceptable, but keep boundaries internally so Ecto/Phoenix do not leak into the protocol core.

Core public API shape

defmodule Elicit.SAML do
  alias Elicit.SAML.{Connection, LoginResult}
  @spec start_login(Plug.Conn.t(), Connection.t(), keyword()) ::
          {:ok, Plug.Conn.t()} | {:error, Elicit.SAML.Error.t()}
  @spec consume_response(Plug.Conn.t(), Connection.t(), keyword()) ::
          {:ok, LoginResult.t(), Plug.Conn.t()} | {:error, Elicit.SAML.Error.t()}
end

Phoenix router API

defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Elicit.SAML.Phoenix.Router
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  scope "/sso", MyAppWeb do
    pipe_through :browser
    saml_routes MyApp.SSO,
      connection_resolver: MyApp.SSO.ConnectionResolver,
      session_adapter: MyAppWeb.SAMLSession,
      on_error: MyAppWeb.SAMLErrorController
  end
end

Generated routes:

GET  /sso/:connection_id/metadata
GET  /sso/:connection_id/login
POST /sso/:connection_id/login
POST /sso/:connection_id/acs
GET  /sso/:connection_id/logout
POST /sso/:connection_id/logout
GET  /sso/:connection_id/slo
POST /sso/:connection_id/slo

Behaviours

defmodule Elicit.SAML.ConnectionResolver do
  @callback resolve(Plug.Conn.t()) ::
              {:ok, Elicit.SAML.Connection.t()} |
              {:error, Elicit.SAML.Error.t()}
end
defmodule Elicit.SAML.SessionAdapter do
  @callback sign_in(Plug.Conn.t(), Elicit.SAML.Principal.t(), keyword()) ::
              {:ok, Plug.Conn.t()} | {:error, term()}
end
defmodule Elicit.SAML.UserMapper do
  @callback map(Elicit.SAML.Principal.t(), Elicit.SAML.Connection.t()) ::
              {:ok, term()} | {:error, term()}
end
defmodule Elicit.SAML.ReplayStore do
  @callback put_new(binary(), DateTime.t()) :: :ok | {:error, :already_seen | term()}
end
defmodule Elicit.SAML.RequestStore do
  @callback put(binary(), map(), DateTime.t()) :: :ok | {:error, term()}
  @callback pop(binary()) :: {:ok, map()} | {:error, :not_found | term()}
end

Ecto schemas

saml_connections
  id
  organization_id
  slug
  status
  provider_preset
  sp_entity_id
  sp_acs_url
  sp_slo_url
  idp_entity_id
  idp_sso_url
  idp_slo_url
  idp_metadata_url
  idp_metadata_xml
  name_id_format
  sign_authn_requests
  require_signed_assertions
  require_signed_responses
  allow_idp_initiated
  relay_state_policy
  jit_provisioning_policy
  inserted_at
  updated_at
saml_certificates
  id
  saml_connection_id
  party              # :idp | :sp
  use                # :signing | :encryption
  pem
  fingerprint_sha256
  not_before
  not_after
  status             # :active | :next | :retired | :expired
  source             # :metadata | :manual | :generated
  inserted_at
saml_attribute_mappings
  id
  saml_connection_id
  saml_attribute_name
  local_field
  required
  transform
saml_group_mappings
  id
  saml_connection_id
  saml_group_value
  local_role_or_group_id
saml_login_attempts
  id
  saml_connection_id
  organization_id
  request_id_hash
  response_id_hash
  assertion_id_hash
  outcome
  error_code
  idp_entity_id_hash
  subject_hash
  duration_ms
  inserted_at
saml_audit_events
  id
  organization_id
  saml_connection_id
  actor_id
  event_name
  metadata
  inserted_at

Admin UI

The admin UI is a major differentiator.

Wizard flow

1. Choose provider
    * Okta
    * Microsoft Entra ID
    * Google Workspace
    * OneLogin
    * Ping
    * ADFS
    * Shibboleth
    * Keycloak
    * Generic SAML 2.0
2. SP details
    * Entity ID
    * ACS URL
    * SLO URL
    * Download SP metadata
    * Copy buttons
    * Environment awareness: dev/staging/prod
3. Import IdP details
    * Metadata URL
    * Metadata XML upload
    * Manual SSO URL/certificate fields
    * Validate certificate and endpoints
4. Security settings
    * Require signed assertion
    * Require signed response
    * Sign AuthnRequests
    * Allow IdP-initiated SSO
    * RelayState policy
    * Algorithm policy
    * Clock skew
5. Attribute mapping
    * NameID preview
    * email
    * first name
    * last name
    * display name
    * groups
    * custom attributes
6. Provisioning
    * Link-only
    * JIT create users
    * JIT update attributes
    * Allowed domains
    * Required groups
7. Test connection
    * Start test login
    * Show validation stages
    * Show mapped attributes
    * Do not create session unless admin confirms
    * Provide support/debug bundle
8. Enable
    * Confirm fallback admin login exists
    * Confirm at least one break-glass admin
    * Enable for subset or entire tenant

Okta’s docs explicitly recommend thinking through single vs multiple IdPs, SP-initiated flow, exposing SAML configuration in the SP, enabling SAML for all vs subset of users, and a “backdoor” access path.  ￼

⸻

Provider presets

Provider presets should not hide the protocol, but they should encode known defaults, labels, and instructions.

Okta

* Common flow: SP-initiated and IdP-initiated.
* Admin needs ACS URL, Entity ID, optional SLO.
* Group attributes common.
* RelayState/deep links common.
* Login hint support useful.

Microsoft Entra ID

* Admin config uses Reply URL / ACS URL, Sign on URL, Identifier / Entity ID, and downloadable certificate. Entra’s protocol docs show Redirect binding for AuthnRequest and POST binding for Response, with ID, Issuer, AssertionConsumerServiceURL, ForceAuthn, IsPassive, NameIDPolicy, and optional signed AuthnRequests.  ￼

Google Workspace

* Admin config requires ACS URL starting with HTTPS, globally unique Entity ID, optional Start URL that sets RelayState, and a choice where the entire response may be signed or only the assertion is signed. This directly argues for flexible but safe signature policy.  ￼

Keycloak / SimpleSAMLphp / Shibboleth

* Essential for reproducible local and CI tests.
* Should have first-class guides because OSS users will use them to debug before connecting enterprise IdPs.

⸻

Testing strategy

Unit tests

Cover pure functions:

* AuthnRequest generation.
* Redirect binding deflate/base64/urlencode/signature.
* POST binding.
* Metadata parse/generate.
* Conditions validation.
* SubjectConfirmation validation.
* Audience matching.
* Algorithm policy.
* Attribute normalization.
* Error taxonomy.

Security regression corpus

Include fixtures for:

* unsigned response/assertion
* response signed but unsigned malicious assertion
* assertion signed but attributes read from unsigned assertion
* duplicate XML IDs
* signature wrapping
* parser differential style payloads
* malicious KeyInfo
* external entity / XXE
* DTD/entity expansion
* malformed XML
* wrong issuer
* wrong destination
* wrong recipient
* wrong audience
* expired assertion
* not-yet-valid assertion
* excessive clock skew
* replayed assertion
* mismatched InResponseTo
* missing InResponseTo in SP-initiated flow
* IdP-initiated response with unsafe RelayState
* SHA-1 signature
* compressed/base64 oversized payload
* encrypted assertion success/failure
* cert rollover with old and new certs

ruby-saml, samlify, and esaml vulnerabilities should become permanent regression fixtures. NVD reports samlify before 2.10.0 had a signature-wrapping attack that allowed forged SAML responses when the attacker had a signed XML document from the IdP.  ￼

Integration tests

Use a Phoenix sample app in CI:

examples/phoenix_saml_demo

Test:

* router macro compiles
* generated migrations run
* login starts
* ACS consumes response
* session adapter signs in
* LiveView admin UI renders
* telemetry emitted
* connection resolver works
* multi-tenant paths work
* failure pages are safe and helpful

E2E IdP containers

Run docker-compose in CI with:

* Keycloak
* SimpleSAMLphp
* optional Shibboleth
* optional mock IdP implemented in Elixir or test-support package

The Go crewjam/saml pattern of including a rudimentary IdP for testing is worth copying.  ￼

Provider fixture suite

For Okta, Entra, Google Workspace, Ping, OneLogin:

* store sanitized metadata fixtures
* store signed response fixtures
* store provider-specific attribute names
* test docs against fixtures
* optionally run nightly live tests when credentials exist

Property/fuzz tests

Use StreamData or similar for:

* RelayState token generation/consumption
* XML ID uniqueness assumptions
* clock skew boundaries
* audience matching
* URL allowlisting
* base64/deflate decode boundaries
* attribute mapping normalization

⸻

Telemetry and SRE design

Emit telemetry with stable event names.

[:elicit, :saml, :login, :start]
[:elicit, :saml, :authn_request, :stop]
[:elicit, :saml, :response, :decode, :stop]
[:elicit, :saml, :response, :validate, :stop]
[:elicit, :saml, :signature, :verify, :stop]
[:elicit, :saml, :replay, :check, :stop]
[:elicit, :saml, :user, :map, :stop]
[:elicit, :saml, :session, :establish, :stop]
[:elicit, :saml, :metadata, :refresh, :stop]
[:elicit, :saml, :certificate, :expiry, :check]
[:elicit, :saml, :logout, :stop]

Measurements

duration_ms
xml_bytes
base64_bytes
inflated_bytes
assertion_count
attribute_count
cert_days_remaining
metadata_age_seconds
clock_skew_seconds
request_store_latency_ms
replay_store_latency_ms

Metadata

connection_id
organization_id
provider_preset
flow                       # :sp_initiated | :idp_initiated
binding                    # :redirect | :post | :artifact
outcome                    # :ok | :error
error_code
idp_entity_id_hash
sp_entity_id_hash
certificate_fingerprint_prefix
signature_algorithm
digest_algorithm

Dashboards

Recommended panels:

* SAML login success rate.
* SAML login latency p50/p95/p99.
* Errors by error_code.
* Errors by provider preset.
* Certificate days remaining.
* Metadata refresh age.
* Replay detections.
* IdP-initiated vs SP-initiated usage.
* Top failing connections.
* Unsafe compatibility options enabled.

Alerts

* IdP certificate expires in 30/14/7 days.
* Metadata refresh failed for N hours.
* Spike in :invalid_signature.
* Spike in :replayed_assertion.
* Spike in :destination_mismatch or :audience_mismatch.
* Replay store unavailable.
* Request store unavailable.
* Unsafe option enabled in production.

⸻

Documentation strategy

Docs should be written for three levels.

Day 0: local dev

* “Add SAML to Phoenix in 15 minutes.”
* Generated certs for dev.
* Run local IdP container.
* Phoenix sample app.
* Explanation of Entity ID, ACS URL, metadata.
* How to inspect SAML with browser tools safely.
* Common errors.

Day 1: first enterprise customer

* Okta guide.
* Microsoft Entra guide.
* Google Workspace guide.
* Generic SAML guide.
* Admin UI guide.
* Attribute mapping guide.
* JIT provisioning guide.
* Rollout checklist.
* Break-glass login checklist.

Day 2: operations

* Certificate rotation.
* Metadata refresh.
* SLO caveats.
* Debugging invalid signatures.
* Debugging audience/destination mismatch.
* Replay cache operations.
* Multi-region deployments.
* Security hardening.
* Incident response.
* Migration from Samly/ExSaml.

Documentation tone

Avoid “SAML is easy.” Better:

“SAML has many moving pieces. This library validates the dangerous parts by default and gives you tools to debug the integration safely.”

⸻

CI/CD and release engineering

CI matrix

Run against:

* supported Elixir versions
* supported OTP versions
* Phoenix current/stable versions
* Plug current/stable versions
* Ecto current/stable versions where applicable

Jobs:

mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix test --only integration
mix credo --strict
mix dialyzer
mix docs
mix deps.audit
mix sobelow --config
mix hex.build

Security automation

* Dependabot or Renovate.
* GitHub code scanning.
* Secret scanning.
* SBOM generation.
* OpenSSF Scorecard.
* SECURITY.md.
* Private advisory workflow.
* CVE process documented.
* Regression tests for every security advisory.

Release automation

* Conventional commits.
* Release Please or equivalent release PR.
* Changelog generated.
* Version bump reviewed.
* Hex publish only after CI passes.
* Docs publish with release.
* GitHub release includes security-relevant notes.
* Signed tags or provenance where practical.

Repository quality

* CONTRIBUTING.md
* SECURITY.md
* CHANGELOG.md
* MIGRATING.md
* CODE_OF_CONDUCT.md
* architecture decision records
* threat model
* compatibility matrix
* provider support matrix
* examples directory
* test fixtures directory

⸻

Advanced features that make it “ultimate”

1. Self-service SAML admin UI

This is likely the biggest adoption unlock for B2B SaaS teams. Most SAML pain is configuration, not code.

2. Provider presets with validation

A preset should:

* label fields the way that provider labels them
* set default bindings
* explain signature behavior
* validate metadata
* show exact setup steps
* include screenshots or text-only equivalents
* include known caveats

3. Connection test mode

A test login should show:

✓ Received SAMLResponse
✓ Decoded base64
✓ Parsed XML safely
✓ Matched IdP issuer
✓ Verified assertion signature
✓ Validated audience
✓ Validated recipient
✓ Validated InResponseTo
✓ Checked replay cache
✓ Mapped email attribute
✓ Would sign in user: user@example.com

For failure:

✗ invalid_audience
The assertion Audience was:
  https://wrong.example.com/saml/metadata
Expected one of:
  https://app.example.com/sso/acme/metadata
How to fix:
  In Okta, set Audience URI / SP Entity ID to ...

4. Debug bundle

Generate a redacted bundle:

connection_config_redacted.json
validation_trace.json
certificate_fingerprints.txt
metadata_summary.txt
error.txt

Never include raw assertion XML unless an admin explicitly downloads it with a warning.

5. Migration from Samly

Provide:

mix elicit_saml.migrate.samly

Outputs:

* detected Samly config
* equivalent new config
* warnings for unsafe defaults
* route migration
* state store migration
* test checklist

6. Test support for Phoenix apps

import Elicit.SAML.TestSupport
setup_saml_connection(:okta)
conn
|> start_saml_login(connection)
|> assert_redirect_to_idp()
conn
|> post_saml_response(connection, fixture: :okta_success)
|> assert_saml_signed_in(user)

7. Fake IdP

Ship a test IdP:

children = [
  {Elicit.SAML.TestIdP, port: 4040, signing_key: :dev}
]

Use it for local dev, examples, and CI.

8. Metadata refresh and cert rollover

Features:

* fetch metadata URL on schedule
* validate TLS
* optionally validate signed metadata
* parse new certs
* keep old and new certs active during overlap
* alert on expiry
* show diff in admin UI
* require confirmation for surprising issuer/entity changes

9. Multi-region story

Document:

* request store requirements
* replay cache requirements
* clock synchronization
* metadata cache replication
* session adapter expectations
* idempotency behavior

⸻

Tradeoffs

Pure Elixir XMLDSig vs native XML security library

Pure BEAM advantages

* Easier Hex install.
* No OS-level dependency.
* Easier cross-platform usage.
* Fits Elixir deployment expectations.

Pure BEAM risks

* XMLDSig and canonicalization are security-hard.
* Easy to repeat parser/canonicalization mistakes.
* More code to audit.

Native/xmlsec-style advantages

* Mature XML security implementation.
* Better chance of correctness for XMLDSig/XMLEnc edge cases.

Native/xmlsec-style risks

* Harder deployment.
* NIF/port complexity.
* Cross-platform friction.
* Supply chain complexity.

Recommendation: do not hand-wave this. The protocol core needs an explicit ADR. The security bar is: one hardened parser path, no parser differentials, adversarial corpus, and a clear answer for canonicalization/signature correctness.

Admin UI vs headless library

Admin UI increases dependencies and surface area, but it is the feature that most reduces enterprise onboarding friction.

Recommendation:

* core/headless packages first-class
* LiveView admin as optional package
* same behaviours and schemas underneath

Strict defaults vs legacy IdP compatibility

Strict defaults will break some legacy customers. Loose defaults create vulnerabilities.

Recommendation:

* strict defaults
* provider presets
* explicit unsafe overrides
* audit unsafe overrides
* docs that explain exact risk
* time-boxed legacy allowances

SP-initiated vs IdP-initiated

SP-initiated is safer and easier to bind to login intent via InResponseTo. IdP-initiated is expected by customer IdP dashboards.

Recommendation:

* SP-initiated default
* IdP-initiated opt-in per connection
* replay cache mandatory
* RelayState allowlist/opaque state mandatory

Ecto persistence vs bring-your-own storage

Ecto schemas are great for Phoenix SaaS teams. Libraries should not force every app into one storage model.

Recommendation:

* Ecto package provides default schemas
* behaviours allow custom storage
* generated migrations are optional
* admin UI expects Ecto unless customized

⸻

MVP / v1 / v2 scope

MVP: secure SP-initiated SSO for Phoenix

Must include:

* AuthnRequest generation.
* ACS response consumption.
* strict signed assertion/response validation.
* safe XML parsing.
* issuer/audience/recipient/destination/time validation.
* replay/request store behaviour.
* Phoenix router macro.
* session adapter behaviour.
* provider guides for Okta, Entra, Google.
* local dev IdP.
* telemetry.
* core error taxonomy.
* CI security corpus.

v1: enterprise-ready multi-tenant SSO

Add:

* Ecto schemas and migrations.
* LiveView admin UI.
* metadata import/export.
* metadata URL refresh.
* certificate rollover.
* attribute/group mapping.
* JIT provisioning hooks.
* migration guide from Samly.
* test support package.
* provider preset matrix.
* production runbooks.

v2: advanced federation

Add:

* encrypted assertions.
* SLO with clear provider matrix.
* signed AuthnRequests everywhere.
* signed metadata.
* artifact binding if justified.
* multi-region reference architecture.
* SCIM companion integration hooks.
* formal fuzzing harness.
* external security review.

⸻

“Ultimate library” acceptance checklist

Developer experience

* mix igniter.install elicit_saml or equivalent generator.
* One router macro.
* One generated config module.
* One generated Ecto migration set.
* One local IdP command.
* Copy-paste provider guides.
* Clear, typed errors.
* Great HexDocs.
* Real Phoenix example app.

Security

* Strict mode default.
* No unsafe XML parser defaults.
* No unsigned assertion acceptance.
* No SHA-1 by default.
* Replay defense required.
* Request ID validation for SP-initiated flows.
* RelayState allowlist/opaque state.
* Cert rollover support.
* Security regression corpus.
* SECURITY.md and disclosure path.

Correctness

* OASIS terminology mapped correctly.
* Web Browser SSO profile implemented carefully.
* Redirect and POST bindings tested.
* Metadata generated and parsed.
* IdP fixtures tested.
* Clock skew tested.
* Boundary conditions tested.

Operations

* Telemetry events.
* Structured redacted logs.
* Audit events.
* Certificate expiry alerts.
* Metadata refresh alerts.
* Debug bundle.
* Runbooks.
* Dashboards.

Maintainability

* Protocol core isolated.
* Framework adapters thin.
* Behaviours for storage/session/mapping/errors.
* CI matrix.
* Release automation.
* Changelog.
* Security advisory process.
* Compatibility matrix.

⸻

Recommended north-star API

defmodule MyApp.SSO do
  use Elicit.SAML.Phoenix,
    repo: MyApp.Repo,
    endpoint: MyAppWeb.Endpoint,
    session_adapter: MyAppWeb.SAMLSession,
    user_mapper: MyApp.SSO.UserMapper,
    provisioner: MyApp.SSO.Provisioner,
    replay_store: MyApp.SSO.ReplayStore,
    request_store: MyApp.SSO.RequestStore
end
defmodule MyApp.SSO.UserMapper do
  @behaviour Elicit.SAML.UserMapper
  def map(%Elicit.SAML.Principal{} = principal, connection) do
    with {:ok, email} <- Elicit.SAML.Principal.fetch_attribute(principal, "email"),
         {:ok, user} <- MyApp.Accounts.get_user_by_email(connection.organization_id, email) do
      {:ok, user}
    end
  end
end
defmodule MyAppWeb.SAMLSession do
  @behaviour Elicit.SAML.SessionAdapter
  def sign_in(conn, principal, user: user, connection: connection) do
    conn =
      conn
      |> Phoenix.Controller.put_flash(:info, "Signed in with #{connection.display_name}")
      |> MyAppWeb.UserAuth.log_in_user(user)
    {:ok, conn}
  end
end

⸻

Final product principle

SAML is old, XML-heavy, and full of edge cases. That is exactly why a great Phoenix library can win.

The winning library should not expose developers to the protocol accidentally. It should expose the protocol intentionally: clear domain language, safe defaults, typed errors, admin workflows, telemetry, and security invariants that hold even when an IdP, browser, attacker, or enterprise rollout behaves badly.