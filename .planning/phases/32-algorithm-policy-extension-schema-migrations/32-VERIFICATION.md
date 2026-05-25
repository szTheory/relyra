---
phase: 32-algorithm-policy-extension-schema-migrations
verified: 2026-05-25T14:35:00Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
---

# Phase 32: AlgorithmPolicy Extension + Schema Migrations Verification Report

**Phase Goal:** Extend AlgorithmPolicy with encryption enforcement functions and add DB schema migrations for encrypted assertion and signed AuthnRequest support — the shared prerequisite for all ENC-01 and AUTHN-01 work.
**Verified:** 2026-05-25T14:35:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | enforce_key_transport_algorithm/2 hard-rejects RSA-PKCS1v1.5 URI with no escape hatch, regardless of policy state | VERIFIED | Pattern-matched function head at line 150; test at algorithm_policy_test.exs:97 confirms allowlist override still rejects |
| 2 | enforce_content_encryption_algorithm/3 rejects AES-CBC URIs by default and allows them only when legacy_aes_cbc hatch is active and unexpired | VERIFIED | cond branch at line 181 calls enforce_legacy_override/3; tests at algorithm_policy_test.exs:149-187 cover default-reject, active hatch, and expired hatch |
| 3 | enforce_content_encryption_algorithm/3 returns :decryption_failed for any auth_tag < 16 bytes, firing before the allowlist check | VERIFIED | cond guard at line 174 is first branch; test at algorithm_policy_test.exs:217 confirms guard fires even for AES-CBC (which would otherwise hit a different branch) |
| 4 | enforce_key_transport_algorithm/2 allows RSA-OAEP (rsa-oaep-mgf1p) by default | VERIFIED | default/0 at line 68 includes rsa-oaep-mgf1p; test at algorithm_policy_test.exs:107 asserts :ok |
| 5 | enforce_content_encryption_algorithm/3 allows AES-128-GCM and AES-256-GCM by default | VERIFIED | default/0 at lines 71-74 includes both URIs; tests at algorithm_policy_test.exs:137-146 assert :ok |
| 6 | AlgorithmPolicy.default/0 populates all five struct fields (allowed_key_transport_algorithms, allowed_content_encryption_algorithms, legacy_aes_cbc: nil) | VERIFIED | default/0 at lines 52-77 sets all 6 struct fields; legacy_aes_cbc: nil confirmed at line 75 |
| 7 | strict_default_proof_test.exs covers both new enforce functions | VERIFIED | Lines 46-58 contain proof tests for PKCS1v1.5 hard-reject and AES-CBC default reject |
| 8 | relyra_connection_certificates table has party (:string, not null, default 'idp') and use (:string, not null, default 'signing') columns; all existing rows get these safe defaults | VERIFIED | Migration 20260525100000 up/0 adds both columns with null: false and static defaults; migration ran successfully in test (output captured) |
| 9 | relyra_connections table has sign_authn_requests (:boolean, not null, default false); all existing rows get false | VERIFIED | Migration 20260525100001 change/0 adds sign_authn_requests with null: false, default: false; migration ran successfully in test |
| 10 | Certificate Ecto schema exposes party as Ecto.Enum [:idp, :sp] and use as Ecto.Enum [:signing, :encryption] | VERIFIED | certificate.ex lines 29-30 declare both fields; both appear in changeset/2 cast list at lines 58-59 |
| 11 | Connection Ecto schema exposes sign_authn_requests as :boolean, default: false; field is in both draft_changeset and update_changeset cast lists | VERIFIED | connection.ex line 40 declares field; lines 98 and 124 include it in both changesets |
| 12 | All existing cert rollover, snapshot, and connection tests still pass after schema changes | VERIFIED | mix test --warnings-as-errors: 575 tests, 0 failures; mix test test/relyra/ecto/ --warnings-as-errors: 101 tests, 0 failures |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/relyra/security/algorithm_policy.ex` | Extended AlgorithmPolicy struct + two new public enforce functions | VERIFIED | defstruct has 6 fields (lines 23-30); enforce_key_transport_algorithm/2 at lines 149-164; enforce_content_encryption_algorithm/3 at lines 166-187 |
| `test/relyra/security/algorithm_policy_test.exs` | Unit tests for all new enforce function behaviors | VERIFIED | 4 new describe blocks covering all behaviors from plan; 228 lines; all 31 tests pass |
| `test/security/strict_default_proof_test.exs` | Security proof tests for ENC-03 default posture | VERIFIED | Lines 46-58 add two proof tests; @rsa_pkcs1_uri and @aes128_cbc_uri module attributes at lines 11-12 |
| `priv/repo/migrations/20260525100000_add_party_and_use_to_relyra_connection_certificates.exs` | up/down migration adding party + use columns to cert table | VERIFIED | Module Relyra.Repo.Migrations.AddPartyAndUseToRelyraConnectionCertificates; uses def up/def down (not change); correct null: false defaults |
| `priv/repo/migrations/20260525100001_add_sign_authn_requests_to_relyra_connections.exs` | change migration adding sign_authn_requests to connections table | VERIFIED | Module Relyra.Repo.Migrations.AddSignAuthnRequestsToRelyraConnections; uses def change; sign_authn_requests :boolean, default: false, null: false |
| `lib/relyra/ecto/certificate.ex` | Certificate schema with party and use Ecto.Enum fields | VERIFIED | field :party, Ecto.Enum, values: [:idp, :sp] at line 29; field :use, Ecto.Enum, values: [:signing, :encryption] at line 30; both in changeset/2 cast |
| `lib/relyra/ecto/connection.ex` | Connection schema with sign_authn_requests boolean field | VERIFIED | field :sign_authn_requests, :boolean, default: false at line 40 (top level, not in RuntimePolicy); in both draft_changeset and update_changeset |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| enforce_key_transport_algorithm/2 | deprecated_algorithm/2 private helper | allowlist check via method_allowed?/2 then fallthrough | WIRED | Line 162 calls deprecated_algorithm(method, :key_transport_algorithm) on allowlist miss |
| enforce_content_encryption_algorithm/3 | enforce_legacy_override/3 private helper | MapSet.member?(@aes_cbc_uris, method) | WIRED | Line 182 calls enforce_legacy_override(policy.legacy_aes_cbc, method, :content_encryption_algorithm) |
| certificate.ex :party field | relyra_connection_certificates.party column | Ecto.Enum, values: [:idp, :sp] | WIRED | field :party, Ecto.Enum declaration matches migration string column; Ecto SELECT queries in test logs include "party" column |
| connection.ex :sign_authn_requests field | relyra_connections.sign_authn_requests column | :boolean, default: false | WIRED | INSERT in escape_hatch_audit test log includes sign_authn_requests column with value false |

### Data-Flow Trace (Level 4)

Not applicable. Phase 32 delivers policy enforcement functions and schema columns — no dynamic-data-rendering components (no components, pages, or dashboards). All artifacts are pure logic functions and schema definitions; no data-flow trace needed.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| enforce_key_transport_algorithm hard-rejects PKCS1v1.5 | mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors | 31 tests, 0 failures | PASS |
| enforce_content_encryption_algorithm auth tag guard fires first | mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors | 31 tests, 0 failures | PASS |
| strict_default_proof covers both new functions | mix test test/security/strict_default_proof_test.exs --warnings-as-errors | 31 tests total, 0 failures | PASS |
| cert and connection schema changes don't break existing tests | mix test test/relyra/ecto/ --warnings-as-errors | 101 tests, 0 failures | PASS |
| Full suite passes | mix test --warnings-as-errors | 575 tests, 0 failures | PASS |
| Security CI suite passes | mix ci.security | exit 0; all suites pass (6+4+6+1+9+3+6 tests, 0 failures) | PASS |

### Probe Execution

No `probe-*.sh` files declared or present for this phase. Phase 32 is a pure Elixir/Ecto phase with no probe scripts. Spot-checks above substitute.

### Requirements Coverage

| Requirement | Source Plan | Description (scope for Phase 32) | Status | Evidence |
|-------------|------------|----------------------------------|--------|----------|
| ENC-03 | 32-01-PLAN.md | AlgorithmPolicy hard-rejects PKCS1v1.5 (no escape hatch); AES-CBC blocked by default with time-boxed hatch; GCM auth tag validated (== 16 bytes) before any crypto call | SATISFIED | enforce_key_transport_algorithm/2 and enforce_content_encryption_algorithm/3 fully implemented; strict_default_proof covers both; all tests green |
| ENC-04 (schema half) | 32-02-PLAN.md | cert inventory party/use fields isolate encryption certs from signing certs. Note: ROADMAP assigns KeyResolver behaviour to Phase 33; Phase 32 covers schema half only | SATISFIED | party/use migration and Ecto.Enum fields verified; ENC-04 full completion deferred to Phase 33 per ROADMAP |
| AUTHN-02 (schema half) | 32-02-PLAN.md | sign_authn_requests boolean on connections, default false, backward-compatible. Note: ROADMAP assigns the actual toggle wire-up to Phase 35; Phase 32 covers schema half only | SATISFIED | migration and Connection schema field verified; both changeset cast lists include the field |

**Scope note on ENC-04 and AUTHN-02:** REQUIREMENTS.md defines ENC-04 and AUTHN-02 at the full-feature level. ROADMAP.md explicitly partitions them across phases: ENC-04 schema half in Phase 32, KeyResolver behaviour in Phase 33; AUTHN-02 schema half in Phase 32, toggle wiring in Phase 35. Phase 32 satisfies the portions it owns.

### Anti-Patterns Found

No anti-patterns found. Scan of all seven phase-modified files:
- Zero TBD / FIXME / XXX markers
- Zero TODO / HACK / PLACEHOLDER markers
- No `return null` or stub patterns
- No hardcoded empty data in production paths
- All enforce functions contain real logic (cond chains, pattern-matched heads, allowlist checks)

### Human Verification Required

None. All behaviors are verifiable programmatically and confirmed by passing tests.

### Gaps Summary

No gaps. All 12 must-have truths are verified against actual codebase evidence. All four commits exist and contain the expected changes. All three test files have been updated. Both migrations are correct (up/down vs change as required). Ecto schemas are wired to their respective DB columns. Full test suite (575 tests) and security CI suite both exit 0.

---

_Verified: 2026-05-25T14:35:00Z_
_Verifier: Claude (gsd-verifier)_
