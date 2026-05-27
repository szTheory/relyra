# Investigation: Signed SP Metadata (SIGNED-META-01)

Status: OPEN — stub 2026-05-27; not yet in a milestone; no plan count until triggered
Priority: Low (demand-gated — save-for-demand)
Depends: v1.1 SIGV-04 metadata-root verification (DONE — Phase 29); SP metadata generation (DONE — `Relyra.Protocol.Metadata.build_sp_metadata/2`)

## Trigger

Real GitHub issue from a Phoenix SaaS adopter blocked on academic federation / InCommon onboarding. Persona: ed-tech team winning an R1 university pilot requiring signed `EntityDescriptor` and federation metadata extensions.

**Zero adopter signal at v1.5 close.** Do NOT plan unless issue lands.

## Gap (what exists vs what's missing)

**Shipped:**
- Unsigned SP metadata generation with signing + encryption `KeyDescriptor`s (`lib/relyra/protocol/metadata.ex`)
- IdP metadata-root **verification** via same crypto primitive as response signatures (SIGV-04, Phase 29)
- Metadata served at `GET /:connection_id/metadata` via Phoenix router

**Not shipped:**
- Signing the SP `EntityDescriptor` before export
- Federation metadata extensions: `mdrpi:RegistrationInfo`, `mdui:UIInfo`, `mdattr:EntityAttributes`
- InCommon / academic federation onboarding runbook
- Corpus gate for signed SP metadata in `mix ci.security`

## Real scope (not just sign primitive)

Assessment consensus: the wedge is **metadata extensions + federation runbook + signed export**, not merely wrapping `build_sp_metadata/2` with XMLDSig. InCommon onboarding requires operator-facing guidance beyond the signing math.

**Plan count:** Not enumerated until triggered. Expect multi-phase (sign primitive → extensions → runbook → corpus).

## Technical approach (sketch only)

- Reuse `XmldsigSigner` + C14N engine (same primitives as response/metadata-root verify path)
- Sign `EntityDescriptor` as root; enveloped-signature transform over document
- Export path: admin UI + `mix relyra.metadata` or existing metadata export seam
- AlgorithmPolicy gates signing algorithms (RSA-SHA256 default; SHA-1 rejected)
- Adversarial corpus: tampered EntityDescriptor rejected; wrong-key rejected

## Idiomatic Elixir / ecosystem notes

- Spring Security SAML and python3-saml ship unsigned SP metadata by default; signed SP metadata is federation-specific (InCommon, eduGAIN)
- Shibboleth SP signs metadata when `signMetadata="true"` — reference for extension element ordering
- Do NOT trust document KeyInfo for verification (existing invariant applies symmetrically on generation side — sign with configured SP key only)

## Explicitly out of scope until triggered

- Full federation registry automation (InCommon API integration)
- Attribute Query / Artifact binding (separate out-of-scope items)
- Replacing host-app metadata hosting

## Cross-references

- `.planning/threads/v1-6-milestone-assessment-2026-05-27.md` — demand-gated verdict
- `.planning/STATE.md` — SIGNED-META-01 sizing note (EntityDescriptor + mdrpi/mdui/mdattr + runbook)
- `.planning/milestones/v1.3-REQUIREMENTS.md` — original deferral to demand-gated posture
- `lib/relyra/protocol/metadata.ex` — unsigned generation baseline
- `lib/relyra/security/signature.ex` — verify_metadata_root/4 (verification mirror)
