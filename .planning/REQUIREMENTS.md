# Requirements: Relyra v1.12 Trust-Path Hardening

**Defined:** 2026-10-19
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection, never a silent compromise.

Seam IDs (S1–S20) refer to `.planning/research/SUMMARY.md` § Seam Inventory. Every requirement is proven by deterministic automated evidence in a mandatory CI lane. Each fixed seam has at least one permanent corpus row that goes through the public API.

## Milestone v1.12 Requirements

### Login Trust Binding (BIND)

- [ ] **BIND-01**: An adopter calling `Relyra.consume_response/3` gets identity, NameID, attributes, audiences, recipient, times, and SessionIndex only from the single signed `<Assertion>`. Any element injected elsewhere in the Response is ignored or rejected (S7).
- [ ] **BIND-02**: A Response gets a typed rejection unless:
  - its root is `samlp:Response`;
  - it contains exactly one `saml:Assertion`, with or without an ID;
  - that Assertion is a direct child of the Response (S8, S11, S12).
- [ ] **BIND-03**: A signature is accepted only under all of these conditions (S1, S2, S3):
  - it is the enveloped direct child `ds:Signature` of that Assertion;
  - its `SignedInfo` holds exactly one `Reference`, with `URI = "#" <> Assertion ID`;
  - DigestValue, DigestMethod, and Transforms are direct children of that Reference;
  - SignatureValue is a direct child of the Signature.
- [ ] **BIND-04**: The algorithm policy and the crypto use the bound `SignedInfo`'s SignatureMethod, DigestMethod, and CanonicalizationMethod. The digest uses DigestMethod, and CanonicalizationMethod is allowlisted (S4).
- [ ] **BIND-05**: Security elements are matched by namespace URI as well as local name, so a lookalike element in a foreign namespace is never consumed (S20).
- [ ] **BIND-06**: `bind_signed_node/2` rejects any result whose consumed node is not the verified signed node (S6).
- [ ] **BIND-07**: The Assertion `Issuer` must match the Response Issuer and the configured IdP. Status comes from the top-level `Status/StatusCode` only (S10).
- [ ] **BIND-08**: SubjectConfirmation must be bearer. `SubjectConfirmationData@InResponseTo` must match the pending request whenever `InResponseTo` is required (S9).

### Other Trust Paths (PATH)

- [ ] **PATH-01**: A POST LogoutRequest or LogoutResponse verifies only when it carries an enveloped signature on its own root, with Reference URI equal to the root ID. A logout carrying an embedded Assertion is rejected. Logout fields come from the bound root only (S15).
- [ ] **PATH-02**: Logout type is chosen from the parsed root element and its namespace, not a substring. Destination is validated. Replay keys are connection-scoped (S15, S17).
- [ ] **PATH-03**: An HTTP-Redirect message with duplicate `SAMLRequest`, `SAMLResponse`, `RelayState`, `SigAlg`, or `Signature` parameters is rejected. The verified octets are rebuilt from exactly the processed parameters (S16).
- [ ] **PATH-04**: A decrypted assertion replaces exactly the verified EncryptedAssertion byte span, which stays correct across comments, PIs, and CDATA. The plaintext must be exactly one `saml:Assertion`, and the ambiguity checks re-run after the re-parse (S13, S14).
- [ ] **PATH-05**: Metadata entityID, SSO endpoints, signing certs, and validUntil are derived from the verified SaxyTree root node. The regex parser is retired, so nothing is read from comments, unsigned wrappers, or KeyInfo (S18).

### Property-Based Adversarial Twin (PROP)

- [ ] **PROP-01**: A twin signer can mint a genuinely signed Response, LogoutRequest, or metadata document. It can then either mutate it after signing, or mutate it structurally and re-sign it.
- [ ] **PROP-02**: StreamData generators produce shrinkable mutation op lists across these families:
  - wrapping, moving, or duplicating an element;
  - envelope injection;
  - namespace rebinding;
  - comments, PIs, and CDATA;
  - whitespace and encoding;
  - duplicate IDs and their variants;
  - time boundaries;
  - truncation and size.
- [ ] **PROP-03**: The oracle accepts `{:ok, _}` only when the consumed values equal what the generator signed. Otherwise the result must be `{:error, %Relyra.Error{}}` with an allowlisted type. Any raise, exit, timeout, or heap blowup fails the property.
- [ ] **PROP-04**: A bounded, seeded property suite runs as its own `ci.security` line. A scheduled deep run with a printed seed runs outside `ci-gate`.
- [ ] **PROP-05**: Every shrunk counterexample becomes a permanent named corpus row. The technique stops after two consecutive deep rounds with no new defect class.

### Mutation Testing (MUT)

- [ ] **MUT-01**: A scheduled and `workflow_dispatch` mutation lane runs mutare over the security core and uploads a JSON score report. It never runs in `ci-gate`.
- [ ] **MUT-02**: Each round kills survivors with sharper tests, or fixes the real slack they expose. Equivalent mutants carry a documented ignore. No existing security test is weakened.
- [ ] **MUT-03**: The technique stops when the mutation score plateaus across two rounds. Each remaining survivor is listed as residual risk.

### Close-out (CLOSE)

- [ ] **CLOSE-01**: One evidence file records:
  - every seam with the commit and corpus row that fixed it;
  - the property rounds;
  - the mutation score trend;
  - the residual risk.
- [ ] **CLOSE-02**: An advisory document (`docs/advisories/2026-002-*`) names the affected range and the fixed version. A scripted GHSA and CVE request is filed after exact-batch approval.

## Future Requirements

- **FID-01**: real-IdP fidelity corpus (Keycloak, SimpleSAMLphp, Shibboleth) as scheduled canaries.
- **CHAOS-01**: chaos journeys (WINDOW-29/30, audit co-commit DB failure, rollover-time refresh, clock skew).
- **ADMIN-01**: customer-IT-admin journey through connection testing and attribute preview.
- **INTEROP-01**: accept Response-level (not assertion-level) signatures with strict binding (S5).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Loosening any check for interop | Hardening milestone. New acceptance paths, such as Response-only signatures, need their own decision. |
| Public API or behaviour signature changes | New error atoms are additive. `consume_response/3` and the behaviour callbacks are unchanged. |
| Running mutation or deep-property runs in `ci-gate` | Keeps PR CI around 5 minutes. Only bounded seeded properties and the frozen rows gate merges. |
| AUTHN-POST-01, KMS-01, SIGNED-META-01 | Still demand-gated. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| (filled by roadmap) | | |

---
*Requirements defined: 2026-10-19*
