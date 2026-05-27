---
phase: 49
status: issues
reviewed: 2026-05-27
depth: standard
files_reviewed: 7
critical: 0
warning: 2
info: 2
total: 4
---

# Phase 49 Code Review

Mixed phase: conformance generator/manifest/test (49-01), internal JTBD gap map (49-02), and adopter-facing runbook taxonomy (49-03). Seven files reviewed per SUMMARY key-files.

## Security invariants

**No critical findings.** Crypto posture in the conformance harness is sound:

- `genuinely_signed_fixture_xml/1` signs fixtures that carry a `Reference URI` before `consume_response/3`, so reject rows (`destination_mismatch`, `invalid_audience`, `recipient_mismatch`, `assertion_not_yet_valid`) fail **after** real XMLDSig verification — not via structure-only acceptance. Comments at lines 197–203 document the Phase 29 triage rationale correctly.
- `sp-encrypted-assertions-pass` runs through `FakeIdP.encrypted_response/0` → `Relyra.consume_response/3` with `Application.put_env(:relyra, :sp_private_key_pem, …)` in setup, matching the adversarial ENC positive-control pattern. No bypass of decrypt or signature gates.
- `connection/0` uses `XmldsigSigner.self_signed_cert_pem()` aligned with the FakeIdP keypair — configured IdP certs only; no document `KeyInfo` trust.
- `Mix.Tasks.Relyra.Conformance` is generator-only (reads manifests, renders markdown, drift-checks). No runtime auth or crypto seam changes.
- `mix test test/conformance/sp_conformance_test.exs --warnings-as-errors` — PASS
- `mix relyra.conformance --check` — PASS

## Findings

### WR-01: README seven-family claim vs decoder table mismatch (doc accuracy)

**Severity:** warning  
**File:** `guides/recipes/generic_saml.md` (intro added in 49-03)

The new intro lists seven README families (Ping, OneLogin, Shibboleth, Keycloak, IBM Security Verify, CyberArk, Oracle) and states decoder rows follow. The table still includes **CA SiteMinder**, which is not in README's seven-family list, while **Shibboleth** has no decoder row (only a cross-linked notes section). Adopters following the intro may assume 1:1 README↔table coverage.

**Remediation:** Either replace the SiteMinder row with a Shibboleth row, add SiteMinder to README's family list with explicit rationale, or soften the intro to "seven primary families plus additional decoder rows where operator demand exists."

### WR-02: Manifest binding metadata inconsistent with AuthnRequest build test (coverage accuracy)

**Severity:** warning  
**Files:** `priv/conformance/sp_manifest.json`, `test/conformance/sp_conformance_test.exs`

`sp-authn-request-build` declares binding `HTTP-Redirect`, but `evaluate_row/1` asserts `authn_request.protocol_binding` is `HTTP-POST` (matching `AuthnRequest` default). CONFORMANCE.md inherits the Redirect binding in the published coverage table. This does not weaken runtime security but misstates executable coverage for security reviewers reading the manifest.

**Remediation:** Align manifest `binding` with the built protocol binding, or extend `evaluate_row` to build with `protocol_binding: redirect` when Redirect is the declared coverage intent.

### IN-01: Catch-all `evaluate_row/1` clause masks missing pass handlers (test quality)

**Severity:** info  
**File:** `test/conformance/sp_conformance_test.exs`

The final `evaluate_row/1` clause treats any unmatched row as a reject-path assertion. New **pass** rows without an explicit clause fail loudly (good), but the pattern offers no compile-time or manifest-level guard that every `executed_rows` pass id has a dedicated clause. Consider a `@pass_row_ids` set assertion in setup or a separate test listing covered ids.

### IN-02: Manifest notes arity drift (doc nit)

**Severity:** info  
**File:** `priv/conformance/sp_manifest.json`

ENC row notes reference `FakeIdP.encrypted_response/2`; `evaluate_row` and security tests call `encrypted_response/0`. Harmless but slightly imprecise for readers cross-walking to `fake_idp.ex`.

## Doc accuracy (non-blocking positives verified)

- `docs/jtbd_gap_map.md` — v1.6 Adoption Truth claims (CONFORMANCE scope boundary, ENC pass, demand-gated milestones) match generated `CONFORMANCE.md` and shipped guides. Persona reclassifications are internally consistent.
- `guides/getting_started.md` — four batteries-included presets (Okta, Entra, Google Workspace, ADFS) align with README and `generic_saml.md` intro; `~> 1.4` matches current `mix.exs` `@version`.
- `guides/recipes/generic_saml.md` — Keycloak and OneLogin decoder rows present; PingFederate footgun cross-ref to README "Ping" naming; encryption algorithm shorthand (`aes256-gcm`, etc.) matches `lib/relyra/protocol/metadata.ex` accept-list URIs.
- `CONFORMANCE.md` — generator-only; scope boundary section and 9 pass / 4 reject / 2 unsupported counts match manifest state.
- `mix ci.docs` — PASS

## Summary

| Severity | Count |
|----------|-------|
| critical | 0 |
| warning | 2 |
| info | 2 |
| **total** | **4** |

Phase 49 successfully delivers adoption-honesty artifacts without weakening crypto invariants. Remaining issues are documentation/coverage-metadata accuracy, not auth bypass risk.

## Advisory

None beyond findings above. No `gsd-code-review-fix` required for security; doc fixes are optional polish before milestone ship.
