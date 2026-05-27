# Phase 41: Pre-publish hygiene - Tech-debt sweep & security hardening - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the Phase 41 hygiene/security sweep before the first `1.4.0` Hex publish: metadata attribute escaping, production artifact exclusion for test support modules, parse-tree-only encrypted assertion detection, ENC-01/provider-count doc drift, and formatting drift. This phase does not add protocol features, release versioning, trace UI, or adopter DX beyond the explicit TD-01..TD-05 scope.
</domain>

<decisions>
## Implementation Decisions

### Metadata Attribute Escaping
- **D-01:** TD-01 is scoped to XML attribute positions emitted by `Relyra.Protocol.Metadata.build_sp_metadata/2`, especially dynamic `entityID` and `Location` values. Certificate element text is not the WR-03 attribute-injection target.
- **D-02:** Every metadata attribute interpolation should route through one XML-attribute escaping path before serialization. Fixed literal attributes may use the same helper for consistency, but the security-critical coverage is dynamic interpolation.
- **D-03:** Add `test/security/metadata_attribute_injection_test.exs` to prove XML metacharacters and control/control-like characters are escaped in attribute position, then wire it into `mix ci.security` as its own `cmd mix test` step.

### Production Artifact Exclusion
- **D-04:** TD-02 requires removing `Relyra.TestSupport` modules from production package contents, not merely relying on runtime `Mix.env() == :prod` guards.
- **D-05:** `elixirc_paths(:prod)` and `package.files` must agree that `lib/relyra/test_support*` is excluded from the production artifact. The planned fix should make that agreement inspectable locally before Phase 45 verifies the published tarball.

### Encrypted Assertion Trust Path
- **D-06:** TD-03 must preserve existing ENC-01 behavior while retiring `locate_encrypted_assertion/1`'s regex substring locator: no cleartext+encrypted ambiguity, no multi-`EncryptedAssertion` splice-first behavior, prefix-aware handling, opaque `:decryption_failed`, and reparse through `PureBeam.parse_safely/2` before validation.
- **D-07:** The parse tree is the authoritative encrypted-assertion detector and locator. Any raw-byte operation that remains for recomposition must be driven by the bound parse-tree node, not by an independent regex-alongside-tree detector.

### Docs And Gates
- **D-08:** TD-04 is hygiene-only: correct active adopter-facing copy and legacy ENC-01 drift to match shipped scope, without reopening v1.3 implementation decisions or adding `EncryptedAttribute` support.
- **D-09:** Provider-count copy should use the honest framing: "4 first-class presets + a generic SAML runbook covering 7 IdP families" for Okta, Microsoft Entra ID, Google Workspace, ADFS, plus Ping, OneLogin, Shibboleth, Keycloak, IBM Security Verify, CyberArk, and Oracle Access Manager through the generic runbook.
- **D-10:** TD-05 is formatting-only for `test/security/xml/adversarial_crypto_test.exs`; no semantic test changes should be hidden inside the format drift cleanup.
- **D-11:** Any new or adjusted security gate must preserve the Phase 30 hollow-gate invariant: each security suite runs as its own `cmd mix test` process, and `test/security/ci_gate_integrity_test.exs` is updated if a new gated suite is added.

### the agent's Discretion
- Planner may choose whether the metadata attribute escaper is a local helper or extracted shared helper, as long as it does not couple metadata generation to private C14N internals in a brittle way.
- Planner may choose the local tarball inspection command for TD-02, provided it verifies package contents before publish and can be chained to Phase 45's published-tarball check.
- Planner may decide the exact doc search/edit set for TD-04, but must include active public docs and known legacy ENC-01 references identified below.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 41 goal, success criteria, dependencies, and v1.5 ordering.
- `.planning/REQUIREMENTS.md` - TD-01 through TD-05 definitions and out-of-scope boundaries.
- `.planning/STATE.md` - v1.5 carried decisions, especially TD-02 sequencing and TD-03 one-trust-path rationale.
- `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md` - Original polish assessment and warning-level tech-debt list.

### Audit Sources
- `.planning/v1.3-MILESTONE-AUDIT.md` - Source of WR-01/02, WR-03, WR-04, and WR-ENC-ATTR.
- `.planning/v1.3-v1.3-MILESTONE-AUDIT.md` - Duplicate audit artifact carrying the same warning list; keep consistent if retained.
- `.planning/milestones/v1.4-MILESTONE-AUDIT.md` - Phase 40 formatting drift carry-forward.

### Implementation Touchpoints
- `lib/relyra/protocol/metadata.ex` - SP metadata serialization and attribute interpolation target.
- `lib/relyra/protocol/validation_pipeline.ex` - Encrypted-assertion detect/decrypt/reparse path and regex locator to retire.
- `lib/relyra/security/xml/saxy_tree.ex` - Parse-tree node shape available for tree-bound location.
- `mix.exs` - `elixirc_paths/1`, `package.files`, and `ci.security` alias.
- `test/security/ci_gate_integrity_test.exs` - Structural anti-hollow security lane guard.
- `test/relyra/protocol/decrypt_assertion_test.exs` - Existing ENC-01 behavior that TD-03 must preserve.
- `test/security/xml/adversarial_crypto_test.exs` - Formatting-only target for TD-05.

### Doc Drift Targets
- `README.md` - Provider-count/adopter-facing copy.
- `.planning/milestones/v1.3-REQUIREMENTS.md` - Known `EncryptedAttribute` legacy requirement drift.
- `.planning/research/FEATURES.md` and `.planning/research/SUMMARY.md` - Historical v1.3 research references that still mention `EncryptedAttribute`; update or explicitly classify as historical only during planning.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/relyra/security/xml/c14n.ex` has a private `escape_attr/1` implementing C14N attribute escaping. It is useful evidence for character handling, but it is private serializer code; reuse should be deliberate rather than a blind dependency.
- `test/security/ci_gate_integrity_test.exs` already validates security suite presence, `cmd mix test` usage, and `--only` tag integrity. Add the new metadata security suite to its `@gated_suites` contract when wiring TD-01.
- `test/relyra/protocol/decrypt_assertion_test.exs` and `test/security/xml_enc_adversarial_test.exs` pin encrypted-assertion behavior that the parse-tree locator refactor must keep green.

### Established Patterns
- Security suites in `mix ci.security` are separate `cmd mix test` lines because bare `test` steps become hollow after `ci.conformance` consumes the Mix test task.
- Security-relevant fixes get adversarial tests rather than only positive-path tests.
- XML trust-path code derives protocol fields from the saxy tree behind `PureBeam.parse_safely/2`; regex-alongside-tree detection is now considered invariant drift.
- Dev/test support belongs outside production artifacts. Runtime guards are insufficient when the tarball itself exposes helper modules.

### Integration Points
- `metadata.ex` changes connect to SP metadata export and provider setup docs.
- `validation_pipeline.ex` changes connect to ENC-01 decrypt-then-reparse before verification.
- `mix.exs` changes affect compile paths, Hex package content, and CI alias behavior.
- README and planning-doc drift fixes connect Phase 41 to Phase 46's adopter-DX work; Phase 41 owns the provider-count truth that Phase 46 inherits.
</code_context>

<specifics>
## Specific Ideas

- Treat TD-02 as load-bearing for publish safety: Phase 45 can prove byte equality but cannot save a bad tag that already includes `test_support`.
- Treat TD-03 as one-trust-path enforcement, not an optimization.
- Keep `EncryptedAttribute` out of Phase 41 implementation scope; the correction is doc honesty about what v1.3 actually shipped.
- Keep `adversarial_crypto_test.exs` changes formatting-only, with semantic diffs reviewed skeptically.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within Phase 41 scope.
</deferred>

---

*Phase: 41-pre-publish-hygiene-tech-debt-sweep-security-hardening*
*Context gathered: 2026-05-27*
