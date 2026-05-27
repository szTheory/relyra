# Phase 49 Research: Adoption honesty — CONFORMANCE, jtbd map, preset taxonomy

**Researched:** 2026-05-27  
**Phase:** 49 — Adoption honesty — CONFORMANCE, jtbd map, preset taxonomy  
**Requirements:** ADOPT-04, ADOPT-05, ADOPT-06  
**Status:** Ready for planning

---

## 1. Executive Summary

Phase 49 closes the v1.6 **Adoption Truth** milestone: external-facing docs and generated CONFORMANCE output must match v1.5 shipped reality. All three requirements are doc-or-manifest-honesty with one executable conformance row (ENC pass).

**ADOPT-04** extends `Mix.Tasks.Relyra.Conformance.render_report/1` with a **"Scope boundary & diminishing returns"** section (never hand-edit `CONFORMANCE.md`), flips `sp-encrypted-assertions-deferred` → `sp-encrypted-assertions-pass` in `priv/conformance/sp_manifest.json`, and adds an `evaluate_row/1` clause in `test/conformance/sp_conformance_test.exs` using `FakeIdP.encrypted_response/2`.

**ADOPT-05** fully refreshes `docs/jtbd_gap_map.md` — stale "missing" claims for shipped features (generic runbook v1.3, logout v1.4, incident playbook v1.4+48, login trace v1.5, ENC v1.3, identity mapping v1.3) become **Strong** or demoted from "biggest gaps."

**ADOPT-06** aligns preset taxonomy: add Keycloak + OneLogin decoder rows to `guides/recipes/generic_saml.md`, fix Getting Started §4 to **4 batteries-included** presets (include ADFS), resolve Ping/PingFederate naming, optionally Shibboleth table row or cross-link.

**Recommended plan split:** three parallel wave-1 plans — (01) ADOPT-04 code+manifest+CONFORMANCE regen, (02) ADOPT-05 jtbd_gap_map, (03) ADOPT-06 preset taxonomy docs.

---

## 2. ADOPT-04: CONFORMANCE Generator + ENC Manifest

### Current generator (`lib/mix/tasks/relyra.conformance.ex:79–101`)

`render_report/1` emits, in order:

1. Title + manifest provenance blurb  
2. Requirement Summary table (counts pass/reject/unsupported/deferred)  
3. CVE summary lines  
4. CONF-01 SP Conformance Coverage table  
5. CVE-REG-01 Regression Coverage table  

**Gap:** No scope-boundary section. Append after CVE-REG-01 table (before final newline) per D-01.

### Scope-boundary content source

`.planning/STRATEGIC-ASSESSMENT-2026-05-23.md:183–189` — deliberate out-of-scope list:

- HTTP-Artifact binding, ECP, Attribute Query  
- SCIM-in-core  
- More provider presets without generic-path investment  
- Standalone demo app  
- Full customer-admin synthetic-login self-service  

Frame as **demand-gated, not missing**; cite v0.x→v1.5 arc and ~92–95% done-enough (v1.6 assessment). Also note demand-gated protocol items: AUTHN-POST-01, KMS-01, SIGNED-META-01.

### ENC manifest row (`priv/conformance/sp_manifest.json:212–224`)

| Field | Current | Target |
|-------|---------|--------|
| id | `sp-encrypted-assertions-deferred` | `sp-encrypted-assertions-pass` |
| status | `deferred` | `pass` |
| expected_outcome | `{"result": "deferred"}` | `{"result": "ok"}` |
| notes | "not claimed by ExUnit lane yet" | Positive-control note referencing ENC-01 Phase 34 |

**Summary table impact:** deferred 1→0, pass 8→9 (D-06).

### Executable row pattern

`Relyra.ConformanceFixtures.executed_rows/1` filters `status in ["pass", "reject"]` only — flipping to `pass` requires `evaluate_row/1` handler.

**Reference:** `test/security/xml_enc_adversarial_test.exs:63–116`

1. `setup`: derive SP private key PEM from `FakeIdP.keypair()`, `Application.put_env(:relyra, :sp_private_key_pem, pem)`  
2. `FakeIdP.encrypted_response()` → `Relyra.consume_response/3` with matching `request_intent()` and `connection()` using `FakeIdP.self_signed_cert_pem()` in `cert_chain`  
3. Assert `%{"result" => "ok"}`

**Async caveat:** `SPConformanceTest` is currently `async: true`. SP private key via `Application.put_env` requires `async: false` (same as xml_enc suite) to avoid cross-test pollution.

**Insert clause** before catch-all `evaluate_row/1` at line 155 (reject fallback).

### Regeneration workflow

```bash
mix relyra.conformance          # writes CONFORMANCE.md
mix relyra.conformance --check  # drift gate (ci.conformance)
mix ci.conformance              # sp_conformance_test + --check
```

---

## 3. ADOPT-05: jtbd_gap_map Refresh

### Stale inventory (Last refreshed: 2026-05-23)

| Stale claim | Shipped artifact | Version |
|-------------|------------------|---------|
| No generic runbook | `guides/recipes/generic_saml.md` | v1.3 Phase 36 |
| Logout not polished workflow | `guides/recipes/logout.md` | v1.4 Phase 39 |
| No incident playbook | `guides/operations/incident_playbook.md` | v1.4 + trace Phase 48 |
| Login trace missing | LiveView + `mix relyra.trace` | v1.5 Phase 42 |
| ENC deferred | ENC-01 | v1.3 Phase 34 |
| Identity mapping gap | `guides/identity_mapping_and_provisioning.md` | v1.3 Phase 37 |

### Persona updates (D-09)

- **Operator/SRE:** Strong — playbook + trace documented (Phase 48)  
- **Custom/generic SAML:** Strong with caveat — generic runbook exists, not preset-backed  
- **Phoenix SaaS adopter:** Update "three shipped presets" → four (include ADFS) where mentioned  

### "Biggest gaps" demotion (D-09)

Remove or demote entries #1 (generic runbook), #3 (logout workflow), #4 (incident playbook) — all shipped.

Reorder "Recommended next milestones" to demand-gated future work (AUTHN-POST-01, KMS-01, SIGNED-META-01) per D-10.

### Required structural edits

1. Update `Last refreshed:` to 2026-05-27  
2. Add **"What changed since last refresh"** section listing v1.4–v1.6 doc shipments  
3. Refresh persona status blocks and gap priorities  
4. Update diminishing-returns threshold to reflect v1.5/v1.6 done-enough state  

**No new ci.docs drift test** (D-15, Phase 47/48 precedent).

---

## 4. ADOPT-06: Preset Taxonomy Alignment

### Current drift

| Surface | Claim | Issue |
|---------|-------|-------|
| `README.md:41–65` | 4 first-class + 7 IdP families (Ping, OneLogin, Shibboleth, Keycloak, IBM, CyberArk, Oracle) | Source of truth |
| `guides/getting_started.md:144–149` | Batteries included: Okta, Entra, Google only; ADFS "special case" | Missing ADFS in batteries-included list (D-12) |
| `guides/recipes/generic_saml.md:8–11` | "stops at Okta, Entra, Google" | Omits ADFS preset; intro stale |
| Decoder table `:122–128` | IBM, CyberArk, Oracle, PingFederate, CA SiteMinder | Missing Keycloak, OneLogin (D-11) |
| Ping naming | README "Ping" vs table "PingFederate" | Cross-ref note (D-13) |
| Shibboleth | Dedicated notes section `:154+` | No table row; optional row or intro cross-link (D-14) |

### Phase 41 TD-04 constraint

Do **not** narrow README — add decoder rows for Keycloak/OneLogin; align Getting Started to 4 batteries-included + generic path framing.

### Decoder row template

Copy IBM/CyberArk row structure from `generic_saml.md:124–127` — operator-facing admin labels for Keycloak and OneLogin (Claude's discretion on exact cell text).

---

## 5. CI Gates

| Gate | Command | Phase 49 touchpoints |
|------|---------|---------------------|
| Conformance | `mix ci.conformance` | Manifest flip, evaluate_row, CONFORMANCE regen |
| Docs | `mix ci.docs` | jtbd_gap_map, getting_started, generic_saml (presence only) |
| Full | `mix test --warnings-as-errors` | No regressions |

---

## 6. Risks

| Risk | Mitigation |
|------|------------|
| Hand-editing CONFORMANCE.md | Generator-only path; `--check` gate |
| Encrypted row without evaluate_row | ci.conformance fails on executed_rows assertion |
| Application.put_env race with async:true | Set `async: false` on SPConformanceTest |
| README/runbook drift recurs | Document alignment in plan 03 verify grep set |
| jtbd_gap_map still claims "three presets" | Grep sweep during refresh |

---

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix |
| Quick run | Targeted grep on edited files |
| Full suite | `mix ci.conformance && mix ci.docs && mix test --warnings-as-errors` |
| Estimated runtime | ~60–90s |

### Per-change verification map

| Change | Verify command | Expected |
|--------|----------------|----------|
| Scope boundary section | `grep "Scope boundary" CONFORMANCE.md` | match |
| ENC row pass | `grep "sp-encrypted-assertions-pass" priv/conformance/sp_manifest.json` | match |
| No stale deferred ENC | `grep "sp-encrypted-assertions-deferred" priv/conformance/sp_manifest.json` | no match |
| evaluate_row clause | `grep "sp-encrypted-assertions-pass" test/conformance/sp_conformance_test.exs` | match |
| jtbd refresh date | `grep "2026-05-27" docs/jtbd_gap_map.md` | match |
| jtbd what changed | `grep "What changed since last refresh" docs/jtbd_gap_map.md` | match |
| Keycloak row | `grep -i keycloak guides/recipes/generic_saml.md` | match in table |
| OneLogin row | `grep -i onelogin guides/recipes/generic_saml.md` | match in table |
| Getting Started 4 presets | `grep -i adfs guides/getting_started.md` in §4 batteries list | match |
| CI conformance | `mix ci.conformance` | exit 0 |
| CI docs | `mix ci.docs` | exit 0 |

## RESEARCH COMPLETE
