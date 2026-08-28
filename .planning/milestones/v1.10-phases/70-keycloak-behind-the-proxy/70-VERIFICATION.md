---
phase: 70-keycloak-behind-the-proxy
verified: 2026-08-26T22:39:30Z
status: passed
score: 16/16 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 9/16
  gaps_closed:
    - "G-70-1: focused Keycloak CI and Req/Mint remediation provide independent executable evidence."
    - "G-70-2: deterministic trace-visual Chromium automation exercises the former manual backstops."
  gaps_remaining: []
  regressions: []
---

# Phase 70: Keycloak Behind the Proxy Verification Report

**Phase Goal:** The optional Keycloak real-IdP profile runs behind the proxy at nice hostnames so the full Keycloak-backed SAML login round-trip succeeds end-to-end.
**Verified:** 2026-08-26T22:39:30Z
**Status:** passed
**Re-verification:** Yes — after Plans 70-11 through 70-14

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Keycloak is browser-reachable with the default public forwarded-host identity. | ✓ VERIFIED | Fresh `npm run demo:keycloak-proxy` lifecycle built an owned stack, provisioned Keycloak, ran Chromium, and removed its Compose project. Static checks assert the required hostname/xforwarded/no-host-port/8080-backend contract. |
| 2 | Realm URLs, ACS, redirect URIs, and descriptor transport use the required split horizon. | ✓ VERIFIED | Realm renders public `http://relyra.localhost/saml/01H0…J4/{metadata,acs}` values; descriptor transport is only `http://keycloak:8080/.../descriptor`; static harness checks default and override rendering. |
| 3 | A real browser Keycloak login reaches scoped ACS, verifies, and establishes a durable receipt. | ✓ VERIFIED | The fresh scenario runs `keycloak.spec.ts`; its harness requires signed POST, one receipt, and exactly `response.validate`, `signature.verify`, and `replay.check`. No failure diagnostics were promoted. |
| 4 | Descriptor trust and Sarah mapping use audited seams and enable last. | ✓ VERIFIED | Candidate → `MetadataApply` → `CertificateInventory`; mapping audit and enablement share a transaction. Focused provisioner tests: 12/12 passed. |
| 5 | Key rotation removes stale active trust and does not churn on an unchanged descriptor. | ✓ VERIFIED | Focused rotation/idempotency assertions passed. |
| 6 | Fetch, parse, apply, activation, identity, mapping-audit, and enablement failures fail closed. | ✓ VERIFIED | Focused tests cover injected failures and rollback/no-enabled-connection outcomes. |
| 7 | Only Sarah's exact public-realm identity is provisioned. | ✓ VERIFIED | Subject, issuer, and user match are enforced; mismatched identity test passes fail-closed. |
| 8 | Owned E2E lifecycle recreates realm state before import. | ✓ VERIFIED | Harness reserves a project, runs `down --volumes` before startup, and refuses active `relyra-demo`; fresh run cleaned up. |
| 9 | Browser output and promoted diagnostics contain no protected content. | ✓ VERIFIED | Diagnostic/artifact policy tests pass; both Playwright configs disable trace, screenshot, and video; temporary output is validated then removed. |
| 10 | FakeIdP remains independent and Keycloak remains optional. | ✓ VERIFIED | FakeIdP is always available; Keycloak is conditional on the enabled connection; deterministic tamper lane remains separate. |
| 11 | Receipt wording is truthful and makes no cookie claim. | ✓ VERIFIED | Keycloak Chromium test asserts the exact session-establishment receipt copy. |
| 12 | Failed ACS cannot produce a false workspace or verified receipt, and recovery works. | ✓ VERIFIED | Fresh `npm run demo:trace-visual`: real tampered ACS POST returns 400/`digest_mismatch`, no workspace/receipt, then authenticated trace recovery and Back navigation. |
| 13 | Native trace disclosure is keyboard-operable. | ✓ VERIFIED | Chromium focuses the native summary and toggles it with Enter; render-contract test passes. |
| 14 | Narrow trace evidence is accessible without page-wide clipping. | ✓ VERIFIED | At 360px Chromium proves document bounds, focusable labelled evidence region, horizontal scrolling, and visible Duration column. |
| 15 | Long safe trace evidence remains visible. | ✓ VERIFIED | Exact opt-in fixture routes synthetic data through `AuditWriter`; Chromium asserts the long cause and known error code. |
| 16 | Only runtime-supplied host-admin credentials establish admin scope. | ✓ VERIFIED | Guarded-route coverage remains present; both browser harnesses generate process-only credentials with no bypass. |

**Score:** 16/16 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docker-compose.proxy.yml` and realm JSON | Proxy/realm public-host contract | ✓ VERIFIED | Fixed public host, xforwarded, private Keycloak transport, public ACS and redirect values. |
| `keycloak_provisioner.ex` and test | Audited descriptor-to-trust provisioning | ✓ VERIFIED | Substantive wiring plus 12 passing focused tests. |
| `scripts/test_keycloak_proxy_e2e.sh` | Owned real-IdP acceptance | ✓ VERIFIED | Static, redaction, artifact policy, and fresh live scenario pass. |
| `keycloak-proxy-e2e.yml` | Recurring focused Keycloak CI | ✓ VERIFIED | PR/main/schedule/dispatch invokes only the focused npm command, with no upload. |
| `mix.lock` | Patched Req/Finch/Mint graph | ✓ VERIFIED | Req 0.7.4, Finch 0.23.0, Mint 1.9.3; direct audit no longer reports Req or Mint. |
| Fixture, LiveAdmin, trace harness/spec/CI | Deterministic failure and visual proof | ✓ VERIFIED | Fresh Chromium test passed and the demo E2E workflow invokes it. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Proxy Compose | Realm import | `RELYRA_HOST`, `KC_HOSTNAME`, `xforwarded` | ✓ WIRED | Default is live-tested; override rendering is static-tested. |
| Provisioner | Metadata/certificate audited seams | one candidate → apply → inventory → transaction | ✓ WIRED | No raw XML re-import or assertion `KeyInfo` trust path. |
| Keycloak harness | Keycloak browser spec | live stack then attachment-free Playwright | ✓ WIRED | Fresh owned scenario executed. |
| Trace harness | Fixture → LiveAdmin → Chromium | env gate, `AuditWriter`, semantic selectors | ✓ WIRED | Fresh browser journey executed. |
| CI workflows | npm acceptance commands | Actions steps | ✓ WIRED | YAML parses; no artifact-upload step exists. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Provisioner | candidate/fingerprints | live Keycloak descriptor | Yes | ✓ FLOWING |
| Optional link | connection availability | persisted enabled connection | Yes | ✓ FLOWING |
| Workspace receipt | receipt | persisted `LoginReceipt` after ACS | Yes | ✓ FLOWING |
| Trace fixture | audit event → export → DOM | opt-in `AuditWriter` event | Yes; synthetic/redaction-safe | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Rendered proxy/realm contracts | `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` | Passed | ✓ PASS |
| Keycloak redaction/artifact policy | Keycloak harness self-test modes | Passed | ✓ PASS |
| Default-host real Keycloak SAML journey | `npm run demo:keycloak-proxy` | Fresh owned Docker/Chromium lifecycle completed and cleaned up | ✓ PASS |
| Provisioner safety paths | focused provisioner test | 12 tests, 0 failures | ✓ PASS |
| Failure/recovery/keyboard/viewport/long values | `npm run demo:trace-visual` | 1 Chromium test, 0 failures; temporary output removed | ✓ PASS |
| Fixture and LiveAdmin contracts | focused reset and Phase 15 tests | 6 + 6 tests, 0 failures | ✓ PASS |
| Security lane | `mix ci.security` | Completed in this verification run; separate from scenario gate | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase-70 `scripts/*/tests/probe-*.sh` probe is declared.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- |
| KC-01 | 70-01 through 70-14 | Optional proxy-hosted Keycloak with public host/realm URLs and a verified round trip. | ✓ SATISFIED | Fresh default-host scenario, focused safety tests, recurring Keycloak CI wiring, and deterministic failure/visual coverage. |

Every Phase 70 plan declares `KC-01`; `.planning/REQUIREMENTS.md` maps it only to Phase 70. No Phase-70 requirement is orphaned.

### Anti-Patterns Found

No `TBD`, `FIXME`, or `XXX` debt marker was found in the Phase-70 implementation set. No changed code introduces a second XML parser, document-KeyInfo trust, raw trust writes, or a FakeIdP→Keycloak dependency.

### Advisory Notes

- Req/Mint remediation is verified: direct audit no longer reports either. It still reports the documented pre-existing Decimal 2.4.1 advisory; `mix ci.security` owns its unchanged explicit disposition. This is outside KC-01 and was not hidden or changed by Plans 70-11/12.
- Review warning WR-01 remains advisory: custom `RELYRA_HOST` is dynamically rendered and static-checked, but browser resolver/spec assertions are for the default `relyra.localhost` pair. The phase contract is the default pair, which is live-tested; add a non-default browser lane if custom-host runtime support becomes a phase contract.

### Human Verification Required

None. The former human-UAT behaviors now have deterministic executable browser coverage.

---

_Verified: 2026-08-26T22:39:30Z_
_Verifier: the agent (gsd-verifier)_
