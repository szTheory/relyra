# Phase 36: Generic SAML Runbook - Context

**Gathered:** 2026-05-26 (assumptions mode, `--auto`)
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish one operator-grade generic SAML runbook at `guides/recipes/generic_saml.md` for
non-preset and partially-supported IdPs. The document must get an operator from Relyra's
existing Day-1 path into a safe first integration without requiring SAML-spec fluency.

The guide is a custom/generic fallback surface, not a new batteries-included support claim.
It must cover the exact `DOCS-02` scope already locked in roadmap/requirements: SP metadata
field reference, IdP metadata import checklist, decoder tables for IBM Security Verify,
CyberArk, Oracle Access Manager, PingFederate, and CA SiteMinder, plus ADFS/Shibboleth
subsections, NameID format guidance, signing/encryption triggers, minimum-safe checklist,
debugging flow, and certificate rotation procedure.

Out of scope for this phase: new preset modules, new runtime features, new support claims for
providers beyond the shipped preset set, broad troubleshooting-taxonomy work, or the identity
mapping/JIT guidance owned by Phase 37.
</domain>

<decisions>
## Implementation Decisions

### Support posture and audience
- **D-01:** The runbook is the authoritative `custom/generic SAML` path described by
  `README.md` and `guides/getting_started.md`, not an expansion of the batteries-included
  matrix. It should explicitly help with IBM Security Verify, CyberArk, Oracle Access
  Manager, PingFederate, CA SiteMinder, Shibboleth, and custom ADFS deployments without
  implying that those providers now ship preset-backed first-class support.
- **D-02:** The primary reader is an operator integrating one unfamiliar enterprise IdP after
  the local `FakeIdP` proof is already green. The guide should assume they understand their
  own app and admin console, but not SAML metadata vocabulary.
- **D-03:** The guide should preserve Phase 27's taxonomy: `batteries included` remains
  limited to Okta / Entra / Google Workspace; everything else stays under an explicit
  generic/custom label.

### Document shape and information architecture
- **D-04:** The generic runbook should mirror the repo's existing operator-runbook style
  rather than invent a new doc format. It should feel like a peer of
  `guides/recipes/okta.md`, `guides/recipes/entra.md`, `guides/recipes/google_workspace.md`,
  and `guides/recipes/adfs.md`, but with a stronger reference-table spine.
- **D-05:** The guide should be structured around setup order, not around protocol theory.
  Recommended backbone:
  1. Overview and support posture
  2. Relyra owns / IdP owns / Host owns
  3. SP metadata field reference in plain English
  4. IdP metadata import checklist
  5. Vendor decoder tables
  6. NameID format decision guide
  7. When to enable signing and encryption
  8. Minimum-safe checklist
  9. Debugging flow
  10. Certificate rotation
- **D-06:** The guide should end in concrete operator receipts and next actions, following
  the same "proof, then production follow-ons" posture used in `guides/getting_started.md`.

### Metadata reference and decoder-table strategy
- **D-07:** The SP metadata field reference must derive from Relyra's actual public/runtime
  seams, not from generic SAML prose. The doc should explain the real fields and metadata
  output Relyra already publishes: `sp_entity_id`, `acs_url`, `AuthnRequestsSigned`,
  signing/encryption `KeyDescriptor`s, encryption algorithm advertisement, and the NameID
  policy emitted by AuthnRequest generation.
- **D-08:** The IdP metadata import checklist should be framed around what Relyra consumes or
  operator-imports today: IdP entity ID, SSO URL, signing certificates, metadata URL/import
  flow, and flags that imply feature toggles such as `WantAuthnRequestsSigned` or encrypted
  assertions.
- **D-09:** Vendor decoder tables are the distinctive payload of this phase. They should map
  Relyra's internal connection/runtime concepts to each vendor's admin-console vocabulary and
  common claim names: email, given name, surname, groups, NameID default, and notable
  footguns. The tables should be clearly dated or version-pinned where the repo already has
  evidence, because field labels drift over time.

### NameID, signing, and encryption guidance
- **D-10:** The NameID decision guide should stay operational, not theoretical: explain when
  `persistent` is the safest user anchor, when email-style NameID is convenient but brittle,
  when `transient` is unsuitable for local account anchoring, and why `unspecified` means
  "you must verify what the IdP is actually emitting."
- **D-11:** The runbook should explain signing and encryption as triggers from observable IdP
  behavior and metadata, not as optional knobs to experiment with casually. `sign_authn_requests`
  is enabled when the IdP requires signed requests; encryption is enabled when the IdP sends
  `EncryptedAssertion` or demands encrypted assertions.
- **D-12:** The ADFS and Shibboleth subsections should be treated as generic-path footgun
  addenda, not full replacement runbooks. ADFS already has its own recipe; the generic guide
  should cross-link it while still explaining how a custom ADFS/Shibboleth path changes the
  generic setup.

### Security and debugging posture
- **D-13:** The minimum-safe checklist should document Relyra's strict defaults and explain
  what operators must not weaken: signed assertions/responses, configured IdP cert trust,
  replay protection in production, SHA-1/CBC rejection posture, and the split between SP
  signing certs and SP encryption certs.
- **D-14:** The debugging flow should start from the existing adoption spine:
  local `FakeIdP` proof first, then metadata/field alignment, then certificate and signing
  expectations, then encryption/signing toggles, then claim/NameID verification. It should
  use the repo's current error/result surfaces rather than promising a new troubleshooting
  system.
- **D-15:** Certificate rotation guidance should align with Relyra's staged metadata/cert
  model: import or refresh metadata, stage next certs, verify overlap, then promote. The
  guide should distinguish IdP signing-certificate rotation from SP signing/encryption cert
  updates so operators do not conflate the trust paths.

### the agent's Discretion
- Exact headings, table layouts, and markdown formatting, provided the guide stays operator-
  first and reference-heavy.
- Exact wording of vendor notes where the repo does not already have locked vocabulary, as
  long as support claims remain narrow and explicit.
- Whether to surface a short "related docs" tail linking to `guides/getting_started.md`,
  metadata/certificate docs, and the ADFS runbook.
</decisions>

<specifics>
## Specific Ideas

- Use the existing runbook idiom of `Relyra owns / IdP owns / Host owns` near the top so the
  trust boundary is obvious before configuration steps begin.
- Treat the SP metadata field reference as the "decoder ring" for operators looking at
  `Relyra.Protocol.Metadata.build_sp_metadata/2` output or their IdP's metadata-import UI.
- Present vendor decoder content as compact comparison tables rather than long prose blocks;
  this phase's unique value is fast translation from Relyra field names to vendor vocabulary.
- Cross-link `guides/recipes/adfs.md` from the ADFS subsection instead of duplicating its full
  PowerShell and claim-rule content.
- Keep the debugging flow sequential and observable:
  `FakeIdP proof -> metadata values -> signing certs -> NameID/claims -> signed requests ->
  encrypted assertions -> rotation drift`.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and locked requirements
- `.planning/ROADMAP.md` — Phase 36 goal and success criteria
- `.planning/REQUIREMENTS.md` — `DOCS-02` requirement wording
- `.planning/milestones/v1.3-ROADMAP.md` — milestone-level Phase 36 framing
- `.planning/PROJECT.md` — support taxonomy, operator-friendly voice, and v1.3 guide intent
- `.planning/STATE.md` — current phase position and dependency posture

### Prior decisions that constrain this guide
- `.planning/phases/27-adopter-onboarding-polish-and-case-studies/27-CONTEXT.md` — locked
  support taxonomy and custom/generic SAML posture
- `.planning/phases/31-disclosure-and-docs-honesty/31-CONTEXT.md` — exact-claims and
  falsifiable-docs discipline
- `.planning/phases/35-signed-authnrequests-adfs-preset/35-CONTEXT.md` — signed-request,
  ADFS, and metadata-toggle decisions that the guide must describe accurately
- `.planning/research/FEATURES.md` — DOCS-02 required coverage and pitfalls
- `.planning/research/SUMMARY.md` — v1.3 phase rationale including DOCS-02 deliverables

### Current guide surfaces and support matrix
- `README.md` — top-level support taxonomy and custom/generic SAML framing
- `guides/getting_started.md` — canonical Day-1 adoption spine
- `guides/recipes/okta.md` — current preset runbook structure baseline
- `guides/recipes/entra.md` — current preset runbook structure baseline
- `guides/recipes/google_workspace.md` — current preset runbook structure baseline
- `guides/recipes/adfs.md` — signed-request and ADFS-specific precedent to cross-link
- `guides/case_studies/operator_managed_rollout.md` — day-2 metadata/certificate posture

### Code and runtime truth sources
- `lib/relyra/connection.ex` — runtime connection fields the runbook must explain
- `lib/relyra/ecto/connection.ex` — persisted connection fields and operator-editable shape
- `lib/relyra/provider.ex` — preset/guide taxonomy and label-translation model
- `lib/relyra/protocol/metadata.ex` — actual SP metadata emitted by the library
- `lib/relyra/protocol/authn_request.ex` — actual AuthnRequest NameID policy and ACS usage
- `lib/relyra.ex` — start-login signed-request flow and toggle usage
- `lib/relyra/metadata/import.ex` — metadata import surface and candidate extraction
- `lib/relyra/ecto/metadata_apply.ex` — staged metadata/application workflow
- `lib/relyra/diagnostic/allow_list.ex` — confirms which connection/metadata fields are safe
  to discuss versus excluded secret material
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The preset runbooks already establish the right tone and section shape for operator docs.
- `Relyra.Provider` gives the project a built-in vocabulary-translation model that can inform
  the generic vendor decoder tables even when no preset exists.
- `Relyra.Protocol.Metadata.build_sp_metadata/2` is the authoritative source for what the SP
  actually publishes: ACS endpoint, signing/encryption descriptors, and `AuthnRequestsSigned`.
- `Relyra.Connection` and `Relyra.Ecto.Connection` expose the exact fields operators configure:
  `sp_entity_id`, `acs_url`, `idp_entity_id`, `idp_sso_url`, `sign_authn_requests`,
  `signed_request_encoding`, and runtime-policy signing requirements.
- Metadata import/apply already gives Relyra a staged rotation story; the runbook can document
  that instead of inventing a manual cert-swapping narrative.

### Established Patterns
- Docs in this repo are strongest when they follow the adopter's sequence of work and end with
  observable receipts.
- Support claims are intentionally narrow and must stay aligned with shipped presets and guides.
- Security guidance should name the trust boundary plainly and avoid "just try toggling this"
  framing for strict settings.
- Provider-specific docs use the vendor's own field names; the generic runbook should preserve
  that idea via decoder tables rather than flattening everything into abstract SAML terms.

### Integration Points
- `guides/recipes/generic_saml.md` should slot under the existing `custom/generic SAML`
  surface referenced from `README.md` and `guides/getting_started.md`.
- The ADFS subsection should connect to, not replace, `guides/recipes/adfs.md`.
- The certificate-rotation section should align with metadata refresh/import and cert staging
  flows already described elsewhere in the repo.
</code_context>

<deferred>
## Deferred Ideas

- Expanding batteries-included support claims to additional providers without shipping preset
  modules plus verified provider-specific runbooks.
- A standalone global troubleshooting guide or error-atom decoder; the generic runbook may
  reference current error surfaces, but a repo-wide troubleshooting doc is separate work.
- Identity mapping, JIT, SCIM boundary, and anchor-stability deep guidance — owned by
  Phase 37, not this runbook.
- Academic federation / InCommon specialization beyond a brief mention, since it is useful
  research context but not part of the locked Phase 36 success criteria.

### Reviewed Todos (not folded)
None — `gsd-sdk query todo.match-phase 36` returned zero matches on 2026-05-26.
</deferred>

---

*Phase: 36-generic-saml-runbook*
*Context gathered: 2026-05-26*
