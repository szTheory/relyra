# Phase 36: Generic SAML Runbook - Research

**Researched:** 2026-05-26
**Requirement anchor:** `DOCS-02`
**Goal:** Publish one operator-grade generic SAML runbook for non-preset and partially-supported IdPs, grounded in Relyra's real runtime seams and explicit support posture.

## Executive Summary

Phase 36 should stay narrow and documentation-only, but it still needs a strong execution shape because the guide is effectively a public trust contract. The repo already has the exact seams the runbook must explain: connection fields (`Relyra.Connection` and `Relyra.Ecto.Connection`), SP metadata output (`Relyra.Protocol.Metadata.build_sp_metadata/2`), AuthnRequest NameID/signing behavior (`Relyra.Protocol.AuthnRequest` and `Relyra.start_login/3`), metadata import/apply (`Relyra.Metadata.Import`, `Relyra.Ecto.MetadataApply`), and the diagnostic/export boundary (`Relyra.Diagnostic.AllowList`). The right split is:

1. Publish the canonical generic/custom-SAML route and the runbook's core operator sections.
2. Add the vendor decoder tables plus the minimum-safe, debugging, rotation, and docs-gate enforcement that make the guide durable.

This phase should not add presets, runtime features, or broader support claims. It should tighten the existing "custom SAML" surface into one authoritative guide at `guides/recipes/generic_saml.md`.

## Verified Repo Seams To Reuse

### Existing docs posture and routing

- `README.md` already distinguishes first-class presets from `Custom SAML And Not-Yet-Shipped Providers`.
- `guides/getting_started.md` already tells adopters to finish one Day-1 path before branching into broader provider work.
- `guides/recipes/adfs.md` establishes the operator-runbook style now expected for advanced federation docs.

Implication: Phase 36 should wire the generic runbook into these existing surfaces, not create a new docs taxonomy.

### Runtime fields the runbook must describe exactly

- `lib/relyra/connection.ex` is the authoritative runtime field list: `sp_entity_id`, `acs_url`, `idp_entity_id`, `idp_sso_url`, `idp_certificates`, `name_id_format`, `sign_authn_requests`, `signed_request_encoding`, and strictness toggles such as `require_signed_assertions?` / `require_signed_response?`.
- `lib/relyra/ecto/connection.ex` confirms which of those fields are persisted and operator-editable.

Implication: the SP metadata field reference and IdP import checklist must explain Relyra's real field names, not generic SAML abstractions detached from code.

### Metadata and signing/encryption truth sources

- `lib/relyra/protocol/metadata.ex` proves what the SP actually publishes: `AuthnRequestsSigned="true"` only when `sign_authn_requests: true`, signing `KeyDescriptor` only when signing is enabled, encryption `KeyDescriptor` always present, and the three advertised encryption algorithms.
- `lib/relyra/protocol/authn_request.ex` shows the default `NameIDPolicy` format is `unspecified` unless overridden and that AuthnRequest generation is ACS- and destination-driven.
- `lib/relyra.ex` shows the practical trigger for signed requests: `start_login/3` switches into the signed redirect-query path only when `sign_authn_requests: true`, with `signed_request_encoding` selecting `:rfc3986_upper` or `:adfs_lower`.

Implication: the guide's signing/encryption sections must be framed as observable configuration or metadata triggers, not experimentation advice.

### Metadata import, staged trust changes, and diagnostic boundaries

- `lib/relyra/metadata/import.ex` imports IdP metadata into the candidate shape Relyra actually consumes: entity ID, SSO URL, binding choice, and certificate set.
- `lib/relyra/ecto/metadata_apply.ex` confirms the staged metadata/apply/audit model that Phase 36's certificate-rotation section should describe.
- `lib/relyra/diagnostic/allow_list.ex` confirms the safe/public diagnostic surface: IDs, URLs, status, and metadata revision references are exportable; PEM bodies and private keys are not.

Implication: the runbook can describe staged metadata refresh and cert overlap confidently, but must keep secret material and private-key handling explicitly out of the operator workflow.

## Recommended Phase Split

### Plan 36-01: Canonical generic/custom-SAML route plus core runbook

Scope:
- Add explicit links from `README.md` and `guides/getting_started.md` to `guides/recipes/generic_saml.md`.
- Create the runbook's operator skeleton: overview/support posture, ownership table, SP metadata field reference, IdP metadata import checklist, NameID decision guide, and signing/encryption trigger guidance.

Why first:
- The generic path needs to become discoverable and coherent before the vendor-specific decoder tables are useful.

Likely files:
- `README.md`
- `guides/getting_started.md`
- `guides/recipes/generic_saml.md`

### Plan 36-02: Vendor decoder tables, safety/ops sections, and docs gate

Scope:
- Add decoder tables for IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, and CA SiteMinder.
- Add ADFS and Shibboleth subsections, minimum-safe checklist, debugging flow, and certificate rotation guidance.
- Extend `mix.exs` `ci.docs` so `guides/recipes/generic_saml.md` cannot disappear silently.

Why second:
- These sections depend on the core runbook structure and should finish by hardening the doc against drift.

Likely files:
- `guides/recipes/generic_saml.md`
- `mix.exs`

## Risks And Anti-Patterns

### Risk: accidental support-claim expansion

The guide covers non-preset IdPs, but it must not read like a promise that those IdPs now have shipped presets or vendor-verified support lanes. The taxonomy from Phases 27 and 31 must stay explicit.

### Risk: generic prose detached from real library seams

A generic SAML guide that talks only in spec language will drift away from what operators actually configure in Relyra. Every section should anchor back to concrete fields, metadata output, or existing workflows.

### Risk: stale vendor vocabulary

Decoder tables are the most likely part of the doc to age badly. Execution should date or version-scope the tables and verify labels before claiming them as current.

### Risk: "just toggle it" security advice

Signing and encryption settings are trust-boundary controls. The guide must explain when to enable them and what observable provider behavior or metadata demands them; it must not encourage trial-and-error weakening.

### Risk: no durability gate

Without a `ci.docs` presence check, the new runbook can be removed or renamed without failure. Phase 36 should close that gap.

## Recommended Verification Shape

- `rg` checks proving `README.md` and `guides/getting_started.md` route custom/generic users to `guides/recipes/generic_saml.md`.
- `rg` checks for the runbook's required H2 coverage and vendor names.
- `mix ci.docs` after adding the presence gate line for `guides/recipes/generic_saml.md`.
- `mix test --warnings-as-errors` as a regression check after touching `mix.exs`.

## Planning Guidance

- Keep the phase at two plans. The deliverable surface is one new runbook plus one docs-lane hardening change.
- Make section headers grep-able and load-bearing where possible so verification is cheap.
- Treat exact vendor labels as execution-time verification work, not planning-time assumptions.
- Keep `guides/recipes/adfs.md` as the specialized runbook and use the generic guide only as the fallback/custom path that cross-links ADFS where appropriate.

## RESEARCH COMPLETE

Phase 36 should be planned as a two-plan documentation phase: first create the authoritative generic/custom-SAML path and core runbook, then finish it with vendor decoder tables, operator safety sections, and a docs presence gate.
