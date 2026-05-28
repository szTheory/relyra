# Phase 49: Adoption honesty — CONFORMANCE, jtbd map, preset taxonomy - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

External-facing honesty catches up to shipped code — CONFORMANCE records the done-enough boundary, the conformance manifest reflects ENC-01, internal planning docs stop claiming missing features, and preset taxonomy is consistent across README, Getting Started, and the generic SAML runbook. Doc-only ADOPT-04, ADOPT-05, ADOPT-06. No new SAML protocol surface, no public API changes, no new presets as first-class modules.
</domain>

<decisions>
## Implementation Decisions

### CONFORMANCE scope boundary section (ADOPT-04)
- **D-01:** Add **"Scope boundary & diminishing returns"** as a new section in `Mix.Tasks.Relyra.Conformance.render_report/1` — appended after the CVE-REG-01 table so `mix relyra.conformance --check` stays green. Do not hand-edit `CONFORMANCE.md`; it is fully generated.
- **D-02:** Section content records the v0.x→v1.5 shipping arc and explicit out-of-scope boundary from REQUIREMENTS: HTTP-Artifact, ECP, Attribute Query, SCIM-in-core, more first-class presets without generic-path investment, standalone demo app, customer-admin self-service portal. Frame as **demand-gated, not missing** — aligned with `.planning/STRATEGIC-ASSESSMENT-2026-05-23.md` diminishing-returns line and v1.6 assessment (~92–95% done-enough).
- **D-03:** After generator change, regenerate `CONFORMANCE.md` via `mix relyra.conformance` and verify `mix relyra.conformance --check` passes.

### ENC manifest flip (ADOPT-04)
- **D-04:** Rename manifest row `sp-encrypted-assertions-deferred` → `sp-encrypted-assertions-pass`; set `status: "pass"` and `expected_outcome: {"result": "ok"}` in `priv/conformance/sp_manifest.json`.
- **D-05:** Add `evaluate_row/1` clause in `test/conformance/sp_conformance_test.exs` for the encrypted pass row using `FakeIdP.encrypted_response/2` — same positive-control pattern as `test/security/xml_enc_adversarial_test.exs` (SP private key via `Application.put_env(:relyra, :sp_private_key_pem, ...)` in test setup).
- **D-06:** Requirement summary table shifts: deferred **1→0**, pass **8→9**. `mix ci.conformance` must stay green (manifest gate + executable row).

### jtbd_gap_map refresh (ADOPT-05)
- **D-07:** Full refresh of `docs/jtbd_gap_map.md` to v1.5+ reality — update "Last refreshed" date and add **"What changed since last refresh"** note.
- **D-08:** Reclassify stale "missing" claims to shipped:
  - Incident playbook → `guides/operations/incident_playbook.md` (v1.4; trace tools Phase 48)
  - Generic SAML runbook → `guides/recipes/generic_saml.md` (v1.3)
  - Logout adopter workflow → `guides/recipes/logout.md` (v1.4)
  - Login trace → Phase 42 LiveView + `mix relyra.trace` (v1.5)
  - Encrypted assertions → ENC-01 (Phase 34)
  - Identity mapping guide → `guides/identity_mapping_and_provisioning.md` (v1.3)
- **D-09:** Persona reassessment: Operator/SRE → **Strong** (playbook + trace documented); Custom/generic SAML adopter → **Strong** with honest generic-runbook caveat (not preset-backed). Demote or remove stale "biggest gaps" entries (#1 generic runbook, #3 logout workflow, #4 incident playbook).
- **D-10:** Update "Recommended next milestones" and "Diminishing returns threshold" sections to reflect v1.5/v1.6 done-enough state — future work is demand-gated (AUTHN-POST-01, KMS-01, SIGNED-META-01), not coverage-gated.

### Preset taxonomy alignment (ADOPT-06)
- **D-11:** **Add Keycloak and OneLogin decoder table rows** to `guides/recipes/generic_saml.md` — do not narrow README claims (Phase 41 TD-04 locked "4 first-class + 7-family generic runbook" framing).
- **D-12:** Align Getting Started §4 support taxonomy to **4 batteries-included** presets (Okta, Entra, Google Workspace, ADFS) — currently lists only 3 with ADFS as "special case"; match README and PROJECT.md.
- **D-13:** Resolve Ping naming drift: README says "Ping"; decoder table says "PingFederate" — add cross-reference note in generic runbook (PingFederate row covers README "Ping" claim) or normalize label consistently across README and table.
- **D-14:** Shibboleth already has a dedicated notes section in generic runbook — optionally add a decoder table row for parity with the other six named families, or explicitly cross-link the notes section from the table intro so all 7 README-named families are findable.

### CI gates
- **D-15:** No new drift tests this phase — Phase 47/48 precedent (presence guards sufficient for doc-only changes). Verification: `mix ci.conformance`, `mix ci.docs`, `mix test --warnings-as-errors`.

### Claude's Discretion
- Exact scope-boundary prose wording and jtbd persona reclassification detail.
- Decoder table cell content for Keycloak and OneLogin (operator-facing admin labels).
- Whether Shibboleth gets a full table row vs notes-section cross-link only.
- Optional light sync of `guides/jtbd_user_flows.md` cross-links (not in success criteria).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 49 goal, success criteria, ADOPT-04/05/06 requirements.
- `.planning/REQUIREMENTS.md` — ADOPT-04, ADOPT-05, ADOPT-06 definitions and out-of-scope list.
- `.planning/PROJECT.md` — v1.6 Adoption Truth milestone; 4 presets + 7-family generic runbook framing; doc-only boundary.
- `.planning/STATE.md` — ENC manifest stale row; ci.docs/ci.conformance gate invariants.
- `.planning/threads/v1-6-milestone-assessment-2026-05-27.md` — Original drift inventory (CONFORMANCE, jtbd_gap_map, preset taxonomy).
- `.planning/STRATEGIC-ASSESSMENT-2026-05-23.md` — Diminishing-returns line and scope-boundary content source.

### Prior Phase Context
- `.planning/phases/47-onboarding-truth-getting-started-production-ecto-path/47-CONTEXT.md` — ci.docs presence-gate precedent; Getting Started §4 taxonomy touchpoint.
- `.planning/phases/48-operator-completeness-incident-playbook-trace-tools/48-CONTEXT.md` — incident playbook shipped; jtbd operator gap closed.
- `.planning/milestones/v1.5-phases/46-adopter-dx-ergonomics/46-CONTEXT.md` — README 30-second snippet; overview Day-2 hub pattern.

### Implementation Touchpoints
- `lib/mix/tasks/relyra.conformance.ex` — **primary edit** for scope-boundary section (generator, not CONFORMANCE.md).
- `CONFORMANCE.md` — regenerated output; verify via `--check`.
- `priv/conformance/sp_manifest.json` — ENC row rename + status flip.
- `test/conformance/sp_conformance_test.exs` — new `evaluate_row` for encrypted pass.
- `lib/relyra/test_support/fake_idp.ex` — `encrypted_response/2` for conformance positive control.
- `test/security/xml_enc_adversarial_test.exs` — reference pattern for SP key setup + encrypted login.
- `docs/jtbd_gap_map.md` — **primary edit** for v1.5 reality refresh.
- `guides/recipes/generic_saml.md` — decoder table rows (Keycloak, OneLogin).
- `README.md` — preset taxonomy source of truth (4 + 7 families); verify alignment after edits.
- `guides/getting_started.md` — §4 support taxonomy (4 batteries-included).
- `mix.exs` — `ci.conformance` alias wiring.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Relyra.Conformance.render_report/1` — single generator for all CONFORMANCE.md sections; append scope-boundary here.
- `Relyra.TestSupport.FakeIdP.encrypted_response/2` — canonical encrypted assertion generator for conformance pass row.
- `Relyra.ConformanceFixtures.executed_rows/1` — only `pass` and `reject` statuses execute; flipping deferred→pass requires evaluate_row handler.
- Existing decoder table in `generic_saml.md` — IBM/CyberArk/Oracle/PingFederate/CA SiteMinder rows as template for Keycloak/OneLogin.

### Established Patterns
- CONFORMANCE.md is generated, never hand-edited — `mix relyra.conformance --check` gates drift.
- Phase 47/48 ci.docs pattern: presence guards only; no new drift tests for doc-only phases.
- Phase 41 TD-04: honest "4 first-class + 7-family generic runbook" — add rows, don't narrow README.
- jtbd_gap_map pairs with `guides/jtbd_user_flows.md` — gap map is planning companion, user flows is adopter-facing.

### Integration Points
- Manifest row flip → sp_conformance_test evaluate_row → ci.conformance green.
- Generator scope section → regenerated CONFORMANCE.md → ci.conformance --check.
- generic_saml.md table → README "7 IdP families" claim → Getting Started §4 taxonomy.
- jtbd_gap_map refresh → internal planning accuracy for post-v1.6 pause decision.
</code_context>

<specifics>
## Specific Ideas

- v1.6 assessment flagged exact gaps: CONFORMANCE deferred ENC row, jtbd_gap_map stale since 2026-05-23, README names Keycloak/OneLogin but generic runbook table omits them.
- User confirmed all assumptions without correction (assumptions mode, 2026-05-27).
- STRATEGIC-ASSESSMENT diminishing-returns framing is authoritative for scope-boundary prose.
</specifics>

<deferred>
## Deferred Ideas

- New `test/docs/preset_taxonomy_drift_test.exs` — not warranted per Phase 47/48 precedent; revisit if README/runbook drift recurs.
- Full sync of `guides/jtbd_user_flows.md` narrative — not in ADOPT-05 success criteria; optional low-cost cross-link.
- `guides/case_studies/phoenix_saas_tenant_onboarding.md` FakeIdP references — deferred from Phase 47; out of Phase 49 scope.
- AUTHN-POST-01, KMS-01, SIGNED-META-01 — demand-gated per PROJECT.md; note in scope-boundary section, do not implement.
</deferred>

---

*Phase: 49-adoption-honesty-conformance-jtbd-map-preset-taxonomy*
*Context gathered: 2026-05-27*
