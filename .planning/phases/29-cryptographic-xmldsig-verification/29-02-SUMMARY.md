---
phase: 29-cryptographic-xmldsig-verification
plan: 02
subsystem: auth
tags: [saml, xmldsig, canonicalization, algorithm-policy, digest, signature, ecdsa]

# Dependency graph
requires:
  - phase: 28-cryptographic-xmldsig-verification
    provides: "SaxyTree.Node parse tree + bound :node/:signature_node/:transforms_node on the signed-node handle (D-10) that this plan extends with D-02 crypto inputs"
provides:
  - "pure_beam.ex signed_candidates/1 surfaces :signed_info_node / :digest_value_b64 / :signature_value_b64 per signed candidate (D-02)"
  - "those three fields carry through select_candidate/1 onto the signed-node handle Plan 03 reads"
  - "AlgorithmPolicy.digest_atom_for_signature_method/1 — RSA-SHA256/384/512 → digest atom (D-06), ECDSA/unknown → :unsupported_signature_algorithm fail-closed (D-07)"
affects: [29-03-signature-verify, 29-04-metadata-root-parity, fake-idp-real-signing, adversarial-crypto-corpus]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Additive candidate-map / handle extension: new keys appended off the already-bound ds:Signature node, existing keys untouched (D-08 contract preserved)"
    - "Nil-safe field extraction (maybe_find/2 + trimmed_node_text/1): absent DigestValue/SignatureValue yield nil, never raise — base64 values are optional DATA"
    - "Fail-CLOSED algorithm selection: ECDSA rejected in the URI→atom mapping BEFORE rsa-sha* suffix match, with the allowlist left intact (reject ≠ allowlist-removal)"

key-files:
  created:
    - test/security/xml/pure_beam_candidate_test.exs
    - test/relyra/security/algorithm_policy_test.exs
  modified:
    - lib/relyra/security/xml/pure_beam.ex
    - lib/relyra/security/algorithm_policy.ex

key-decisions:
  - "ECDSA fail-closed lives in digest_atom_for_signature_method/1, NOT by removing ECDSA from default/0's allowlist — the allowlist still permits ECDSA URIs (SHA-2 strength); the typed reject before any verify attempt is the contract per D-07 / Pitfall 5 (RFC 6931 r‖s-vs-DER fail-open)"
  - "ECDSA check ordered BEFORE the rsa-sha* suffix match so an '...#ecdsa-sha256' URI can never fall through to a digest atom"
  - "Bare {:ok, atom} | {:error, :unsupported_signature_algorithm} shape returned; Plan 03 wraps the error in a typed %Relyra.Error{type: :unsupported_signature_algorithm} with details (T-29-06 redaction inherited there)"
  - "Base64 DigestValue/SignatureValue carried as nil-safe :digest_value_b64 / :signature_value_b64 — DATA only here (decoded + verified in Plan 03), never executed or logged raw"

patterns-established:
  - "D-02 crypto-input surfacing: SignedInfo node + base64 Digest/SignatureValue derived off the bound ds:Signature in signed_candidates/1, carried additively onto the handle"
  - "Single source of truth for digest selection: digest_atom_for_signature_method/1 is where the recompute hash is chosen AND where ECDSA is rejected"

requirements-completed: [SIGV-01, SIGV-02]

# Metrics
duration: 2min
completed: 2026-05-24
---

# Phase 29 Plan 02: D-02 Crypto-Input Plumbing + Digest-Atom Mapping Summary

**Surfaced the SignedInfo node + base64 DigestValue + base64 SignatureValue per signed candidate (and onto the handle), and added `AlgorithmPolicy.digest_atom_for_signature_method/1` mapping RSA-SHA256/384/512 to digest atoms while failing closed for ECDSA — the two data-plumbing gaps Plan 03's `:public_key.verify` + digest-recompute needs.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-24T11:54:59Z
- **Completed:** 2026-05-24T11:56:36Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- `pure_beam.ex` `signed_candidates/1` now derives `:signed_info_node` (the `SignedInfo` tree node), `:digest_value_b64`, and `:signature_value_b64` off the already-bound `signature_node` — additively, with every Phase-28 key (`xml_id`/`xpath`/`signed_xml`/`node`/`signature_node`/`transforms_node`) unchanged.
- Those three fields survive `select_candidate/1` onto the signed-node handle (via `Map.get/2`), so `signature.ex` (Plan 03) reads the crypto inputs straight off the handle it already binds for canonicalization (D-10 anti-XSW).
- Absent `DigestValue` / `SignatureValue` yield `nil` (no raise) via new nil-safe helpers `maybe_find/2` + `trimmed_node_text/1`.
- `AlgorithmPolicy.digest_atom_for_signature_method/1` maps `rsa-sha256/384/512` → `{:ok, :sha256|:sha384|:sha512}` and fails CLOSED (`{:error, :unsupported_signature_algorithm}`) for any ECDSA URI, unknown URI, `nil`, or non-binary input — the single source of truth for which hash Plan 03 recomputes and the point where ECDSA is rejected before any verify attempt (T-29-04, Pitfall 5).

## Task Commits

Each task was committed atomically:

1. **Task 1: Surface D-02 fields (SignedInfo node, base64 Digest/SignatureValue) per candidate + carry onto the handle** — `5d1cfc9` (feat)
2. **Task 2: Add AlgorithmPolicy.digest_atom_for_signature_method/1 (RSA→atom, ECDSA fail-closed)** — `e63216e` (feat)

**Plan metadata:** (final docs commit — see git log)

## Files Created/Modified

- `lib/relyra/security/xml/pure_beam.ex` — `signed_candidates/1` derives + adds the three D-02 keys; `select_candidate/1` carries them onto the handle; new nil-safe `maybe_find/2` + `trimmed_node_text/1` helpers.
- `lib/relyra/security/algorithm_policy.ex` — new public `digest_atom_for_signature_method/1` (URI→atom mapping with ECDSA/unknown/non-binary fail-closed); `default/0`, `enforce_*`, and the SHA-1 legacy logic untouched.
- `test/security/xml/pure_beam_candidate_test.exs` — asserts the handle's `:signed_info_node` is `%SaxyTree.Node{local: "SignedInfo"}`, `:digest_value_b64`/`:signature_value_b64` equal the trimmed base64 text, the absent-value path returns nil, and the candidate map carries the three keys additively.
- `test/relyra/security/algorithm_policy_test.exs` — asserts each RSA-SHA URI → correct atom; ECDSA (256/384/512) / unknown / `nil` / non-binary → fail-closed; and ECDSA URIs remain in `default/0`'s allowlist (proving fail-CLOSED, not allowlist-removal).

## Decisions Made

- **ECDSA fail-closed = typed reject in the new function, allowlist unchanged.** `default/0` still allowlists `ecdsa-sha256/384/512` (SHA-2 strength); the explicit `:unsupported_signature_algorithm` in `digest_atom_for_signature_method/1` — checked *before* the `rsa-sha*` suffix match — is what prevents the RFC 6931 r‖s-vs-OTP-DER fail-open (Pitfall 5, T-29-04). Plan 03 will wrap the bare error atom in a typed `%Relyra.Error{}`.
- **Base64 values are nil-safe DATA.** `:digest_value_b64` / `:signature_value_b64` are carried verbatim (trimmed) but treated as attacker-controlled strings — decoded + verified only in Plan 03, never executed or logged raw (T-29-06 redaction lands with the Plan 03 details maps).

## Deviations from Plan

None - plan executed exactly as written. No bugs, missing critical functionality, or blocking issues surfaced; no architectural decisions required.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required (in-repo Elixir only; no package installs — T-29-SC accept).

## Verification

- `mix test test/security/xml/pure_beam_candidate_test.exs test/relyra/security/algorithm_policy_test.exs test/security/xml/ test/relyra/security/xml/ --warnings-as-errors` → **104 tests, 0 failures**.
- Broader regression `mix test test/relyra/security/ test/security/ --warnings-as-errors` → **140 tests, 0 failures** (existing pure_beam / c14n / corpus / signature seam tests stay green).
- ECDSA URIs confirmed still present in `default/0` allowlist (the reject is intentional in the new function, not allowlist removal).

## Next Phase Readiness

- Plan 03 (`signature.ex` `do_verify`) now has both inputs it needs: the per-candidate `:signed_info_node` / `:digest_value_b64` / `:signature_value_b64` on the handle, plus `digest_atom_for_signature_method/1` to drive `:crypto.hash` and reject ECDSA before any `:public_key.verify`.
- No file overlap with Plan 01 (parallel-safe, as planned). No blockers.

## Self-Check: PASSED

- Created/modified files all present: `pure_beam.ex`, `algorithm_policy.ex`, `pure_beam_candidate_test.exs`, `algorithm_policy_test.exs`, `29-02-SUMMARY.md`.
- Task commits exist in git: `5d1cfc9` (Task 1), `e63216e` (Task 2).

## Requirement Status Note

The plan frontmatter lists `requirements: [SIGV-01, SIGV-02]` because this plan delivers the
data-plumbing those requirements depend on (D-02 fields + digest-atom mapping). The requirements'
done-criteria — forged signatures REJECTED via `:public_key.verify` and tampered content rejected via
`DigestValue` recompute/compare — are NOT met by this plan; that crypto lands in Plan 03. Per the v1.1
honesty constraint (Core Value / DISC-01), **SIGV-01 / SIGV-02 are deliberately left `Pending` in
REQUIREMENTS.md** and will be marked complete by Plan 03 / the phase verifier once the actual
verification rejects forged + tampered material. No overstated guarantee.

---
*Phase: 29-cryptographic-xmldsig-verification*
*Completed: 2026-05-24*
