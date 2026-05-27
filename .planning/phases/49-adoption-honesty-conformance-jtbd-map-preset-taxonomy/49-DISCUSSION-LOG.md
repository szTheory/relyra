# Phase 49: Adoption honesty — CONFORMANCE, jtbd map, preset taxonomy - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 49-adoption-honesty-conformance-jtbd-map-preset-taxonomy
**Mode:** assumptions
**Areas analyzed:** CONFORMANCE scope boundary, ENC manifest flip, jtbd_gap_map refresh, preset taxonomy alignment, CI gates

---

## Assumptions Presented

### CONFORMANCE scope boundary (ADOPT-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add scope-boundary section to conformance generator, not hand-edited CONFORMANCE.md | Confident | `lib/mix/tasks/relyra.conformance.ex` `render_report/1`; `--check` drift gate |
| Content from REQUIREMENTS out-of-scope list + STRATEGIC-ASSESSMENT diminishing-returns line | Confident | `.planning/REQUIREMENTS.md` ADOPT-04; `.planning/STRATEGIC-ASSESSMENT-2026-05-23.md` |

### ENC manifest flip (ADOPT-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Rename `sp-encrypted-assertions-deferred` → `sp-encrypted-assertions-pass`, status pass | Confident | `priv/conformance/sp_manifest.json` line 212; ENC-01 Phase 34 shipped |
| Add evaluate_row using FakeIdP.encrypted_response/2 | Confident | `test/security/xml_enc_adversarial_test.exs` positive control; `FakeIdP.encrypted_response/2` |

### jtbd_gap_map refresh (ADOPT-05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Full refresh to v1.5 reality; remove stale "missing" rows for shipped features | Confident | `docs/jtbd_gap_map.md` dated 2026-05-23; v1.6 assessment drift table |
| Reclassify Operator and Custom SAML personas to Strong | Likely | Incident playbook v1.4, generic runbook v1.3, trace v1.5 all shipped |

### Preset taxonomy alignment (ADOPT-06)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add Keycloak + OneLogin decoder rows (not narrow README) | Likely | README lines 65-66; Phase 41 TD-04; generic_saml.md table gap |
| Fix Getting Started §4 to 4 batteries-included including ADFS | Confident | README vs getting_started.md §4 mismatch |
| Resolve Ping vs PingFederate naming | Likely | README "Ping" vs table "PingFederate" |

### CI gates
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No new drift tests; ci.conformance + ci.docs + full test suite | Confident | Phase 47 D-11, Phase 48 D-15 precedent |

---

## Corrections Made

No corrections — all assumptions confirmed by user ("Yes, proceed").

---

## External Research

Not performed — codebase evidence sufficient for all assumptions.
