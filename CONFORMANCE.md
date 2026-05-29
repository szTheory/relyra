# Conformance

Generated from executable manifest state in `priv/conformance/sp_manifest.json` and `priv/security_corpus.json`.

## Requirement Summary

| Requirement | pass | reject | unsupported | deferred | total |
| --- | --- | --- | --- | --- | --- |
| CONF-01 | 9 | 4 | 2 | 0 | 15 |

- `CVE-REG-01` fixtures pinned: 8
- Families covered: xxe, signature_wrapping, CVE-2024-45409

## CONF-01 SP Conformance Coverage

| Scope | status | profile | rule | binding | provenance | notes |
| --- | --- | --- | --- | --- | --- | --- |
| sp-authn-request-build | pass | oasis-saml2-core | SAMLCore-3.4.1 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect | https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf / 3.4.1 | SP can build AuthnRequest fields deterministically with a fixed clock. |
| sp-authn-request-redirect-transport | pass | oasis-saml2-bindings | SAMLBindings-3.4.4.1 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect | https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf / 3.4.4.1 | Redirect transport emits base64 request bytes and RelayState without live services. |
| sp-post-response-decode | pass | oasis-saml2-bindings | SAMLBindings-3.5.4 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST | https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf / 3.5.4 | HTTP-POST receipt decodes a base64 SAMLResponse deterministically. |
| sp-response-consume-pass | pass | kantara-saml2int | saml2int-respond | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST | https://kantarainitiative.org/wp-content/uploads/2019/12/SAML-V2.0-Deployment-Profile-for-Federation-Interoperability-Version-2.0.pdf / 6 | SP accepts a signed response when issuer, destination, audience, recipient, and time checks align. |
| sp-response-destination-reject | reject | oasis-saml2-core | SAMLCore-3.2.2.2 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST | https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf / 3.2.2.2 | Destination mismatch must fail closed with a typed rejection. |
| sp-response-audience-reject | reject | oasis-saml2-core | SAMLCore-2.5.1.4 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST | https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf / 2.5.1.4 | Audience restriction must match the SP entity ID. |
| sp-response-recipient-reject | reject | oasis-saml2-core | SAMLCore-2.4.1.2 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST | https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf / 2.4.1.2 | SubjectConfirmationData recipient must resolve to the ACS URL. |
| sp-response-time-reject | reject | oasis-saml2-core | SAMLCore-2.5.1.2 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST | https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf / 2.5.1.2 | NotBefore outside the configured skew window must fail closed. |
| sp-idp-initiated-accept | pass | kantara-saml2int | saml2int-idp-initiated | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST | https://kantarainitiative.org/wp-content/uploads/2019/12/SAML-V2.0-Deployment-Profile-for-Federation-Interoperability-Version-2.0.pdf / 8 | IdP-initiated acceptance is explicit and only passes when the connection opts in. |
| sp-logout-request-build | pass | oasis-saml2-profiles | SAMLProfiles-4.4.4.1 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect | https://docs.oasis-open.org/security/saml/v2.0/saml-profiles-2.0-os.pdf / 4.4.4.1 | SLO request generation remains executable and deterministic with a fixed clock. |
| sp-logout-request-redirect-transport | pass | oasis-saml2-bindings | SAMLBindings-3.4.4.1 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect | https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf / 3.4.4.1 | SLO request transport uses the same Redirect envelope as login initiation. |
| sp-logout-response-redirect-decode | pass | oasis-saml2-bindings | SAMLBindings-3.4.4.1 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect | https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf / 3.4.4.1 | Redirect decoding accepts either SAMLRequest or SAMLResponse payload keys for logout responses. |
| sp-artifact-binding-unsupported | unsupported | oasis-saml2-bindings | SAMLBindings-3.6 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact | https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf / 3.6 | Artifact binding is not implemented in the shipped SP surface and remains explicitly out of coverage. |
| sp-encrypted-assertions-pass | pass | oasis-saml2-core | SAMLCore-2.3.4 | urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST | https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf / 2.3.4 | Encrypted assertion positive control via FakeIdP.encrypted_response/2 in the test harness. |
| sp-ecp-profile-unsupported | unsupported | oasis-saml2-profiles | SAMLProfiles-4.2 | urn:oasis:names:tc:SAML:2.0:bindings:SOAP | https://docs.oasis-open.org/security/saml/v2.0/saml-profiles-2.0-os.pdf / 4.2 | Enhanced Client or Proxy profile support is not part of the current SP roadmap surface. |

## CVE-REG-01 Regression Coverage

| Fixture | family | class | expected rejection | provenance | notes |
| --- | --- | --- | --- | --- | --- |
| xxe-doctype-001 | xxe | xxe_entity_abuse | doctype_forbidden | OWASP SAML Security Cheat Sheet / ported-fixture | DOCTYPE declarations must be rejected before parser trust is established. |
| xxe-entity-001 | xxe | xxe_entity_abuse | entity_expansion_forbidden | OWASP SAML Security Cheat Sheet / ported-fixture | ENTITY declarations must be refused at the XML seam. |
| xsw-duplicate-id-001 | signature_wrapping | signature_wrapping | duplicate_xml_id | Historical XSW regression corpus / ported-fixture | Duplicate assertion IDs model classic XSW signed-node confusion. |
| xsw-ambiguous-assertion-001 | signature_wrapping | signature_wrapping | ambiguous_signed_node | Historical XSW regression corpus / ported-fixture | Multiple signed-node candidates must never collapse to a silent success. |
| c14n-differential-001 | signature_wrapping | parser_differential_and_c14n | canonicalization_failed | PureBeam seam regression corpus / ported-fixture | The current pure-BEAM seam must keep failing closed when canonicalization inputs are incomplete. |
| cve-2024-45409-keyinfo-001 | CVE-2024-45409 | cve_2024_45409 | untrusted_certificate | ruby-saml GHSA-jw9c-mfg7-9rx2 / ported-fixture | Rogue KeyInfo outside ds:Signature must never become a trust anchor; KeyInfo inside Signature is standard XMLDSig and is ignored for trust. |
| cve-2024-45409-duplicate-id-001 | CVE-2024-45409 | cve_2024_45409 | duplicate_xml_id | CVE-2024-45409 / ruby-saml advisory lineage / ported-fixture | Pinned duplicate-ID variant covers signed-node selection bypasses in the CVE family. |
| c14n-differential-rejection-002 | signature_wrapping | parser_differential_and_c14n | canonicalization_failed | Relyra adversarial crypto assurance corpus / ported-fixture | C14N-differential REJECTION: the pure-BEAM seam fails closed with :canonicalization_failed on an incomplete canonicalization handle (the bare parsed_doc map, mirroring c14n-differential-001). The complementary :digest_mismatch crypto proof lives in the adversarial_crypto suite (ASSUR-01); the JSON evaluator routes parser_differential_and_c14n through parse_safely -> canonicalize only and never reaches Signature.verify/4. |

## Scope boundary & diminishing returns

- **Shipped surface:** strict SAML SP library with cryptographic verification, four first-class provider presets plus a generic SAML runbook, Single Logout, encrypted assertions, login trace tooling, and an operator incident playbook.
- **Explicit out-of-scope (not missing):** HTTP-Artifact binding, ECP profile, Attribute Query, SCIM-in-core, additional first-class presets without generic-path investment, standalone adopter-facing demo app on Hex, customer-admin self-service portal.
- **Maintainer adoption evidence (in-repo, not shipped on Hex):** golden host fixtures under `test/fixtures/demo_host/`, `test/adoption/` journey tests, `examples/quickstart.exs`, and optional Keycloak `@tag :external_idp` lane — these prove integrator journeys for CI; they are not a customer-facing demo application.
- **Demand-gated extensions (when an adopter or federation requires them):** HTTP-POST signed AuthnRequests, KMS-native `KeyResolver` adapters, signed SP metadata export and federation extensions.
- **Posture:** enterprise SAML adoption flows in this library are intentionally complete for the stated scope; further protocol work ships on real demand, not coverage checklists.