---
phase: 57-demo-fakeidp-browser-login-proof
plan: "02"
subsystem: demo-idp
tags: [saml, elixir, xmldsig, c14n, tdd, demo]

requires:
  - phase: 57-01
    provides: LedgerLoop.FakeIdP.Keypair (private_key/0, cert_pem/0); enabled cert fixture aligned to real demo cert

provides:
  - LedgerLoop.FakeIdP.Signer with signed_response/1 (genuine RSA-SHA256 + SHA-256 digest via relyra C14N) and tamper/1
  - signer_test.exs: byte-compat proof (Signature.verify/4 {:ok}) + tamper → :digest_mismatch + anti-divergence guards

affects:
  - 57-03 (controller — calls Signer.signed_response/1 in POST /fake_idp/sso handler)

tech-stack:
  added: []
  patterns:
    - "Vendored signer technique: 4-step XmldsigSigner shape re-homed in demo app, calling relyra's PUBLIC C14N modules (never hand-rolled)"
    - "Anti-divergence guarantee: PureBeam.canonicalize for DigestValue, C14N.serialize for SignedInfo — same engines verifier uses"
    - "Unique assertion_id per call via System.unique_integer/1 (replay guard, Pitfall 6)"
    - "Tamper targets Assertion NameID specifically to land :digest_mismatch (not :issuer_mismatch)"

key-files:
  created:
    - demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex
    - demo/ledger_loop/test/ledger_loop/fake_idp/signer_test.exs
  modified: []

key-decisions:
  - "Vendored 4-step signing technique from XmldsigSigner — copies the shape, calls relyra's PUBLIC XML modules (C14N.serialize + PureBeam.canonicalize) rather than importing test_support code"
  - "tamper/1 targets Assertion NameID (not Response-level Issuer) to guarantee rejection fires at :digest_mismatch in do_verify/4, not at earlier protocol step :issuer_mismatch"
  - "Test anti-divergence guard uses defp/def regex (no local canonicalize function defined) and alias/call regex (no Relyra.TestSupport.* alias or call) — more robust than string-matching on docs"
  - "assertion_id generated as 'demo-assertion-<unique_integer>' per call; unique_integer(:positive) avoids replay store collisions across repeated test invocations"

duration: 7min
completed: "2026-06-14"
---

# Phase 57, Plan 02: FakeIdP Signer — Genuine SAML Signing via Relyra C14N Summary

**Vendored 4-step XmldsigSigner technique re-homed in demo/ledger_loop as LedgerLoop.FakeIdP.Signer, computing DigestValue via PureBeam.canonicalize and SignatureValue via C14N.serialize — the same engines Relyra's do_verify/4 uses — so the demo earns a real cryptographic pass**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-06-14T00:50:00Z
- **Completed:** 2026-06-14T00:56:44Z
- **Tasks:** 2 (RED + GREEN)
- **Files modified:** 2

## Accomplishments

- Created `LedgerLoop.FakeIdP.Signer` with `signed_response/1` and `tamper/1`
- `signed_response/1` implements the 4-step XmldsigSigner technique: (1) placeholder XML with empty digest/sig, (2) SaxyTree.parse → PureBeam.canonicalize(Assertion) → SHA-256 → DigestValue, (3) re-embed digest → SaxyTree.parse → C14N.serialize(SignedInfo) → :public_key.sign → SignatureValue, (4) emit final XML; Base.encode64
- `tamper/1` decodes base64, replaces `<NameID>` text with `"TAMPERED"`, re-encodes — leaves SignatureValue intact so Relyra rejects with `:digest_mismatch` at the crypto gate
- `assertion_id` generated uniquely per call via `System.unique_integer([:positive])` to prevent replay store collisions
- Created `signer_test.exs` with 7 tests: byte-compat proof (Signature.verify/4 → {:ok}), unique assertion_id, tamper content mutation, tamper → :digest_mismatch, anti-divergence guards (C14N.serialize + PureBeam.canonicalize present; no Relyra.TestSupport alias/call; no local defp canonicalize)
- TDD RED→GREEN committed as two separate commits; `mix format --check-formatted` passes on both
- Full demo suite: 50/50 tests green (up from 43 before this plan)

## TDD Gate Compliance

- **RED commit** (`7d9cc50`): `test(57-02)` — 7 failing tests (Signer module undefined)
- **GREEN commit** (`797b014`): `feat(57-02)` — all 7 tests pass
- REFACTOR: not needed (implementation is clean; no behavior change after GREEN)

## Task Commits

Each task was committed atomically:

1. **Task 1: Failing signer test (RED)** - `7d9cc50` (test)
2. **Task 2: Signer implementation (GREEN) + test guard fixes** - `797b014` (feat)

## Files Created/Modified

- `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex` — 230 lines; `signed_response/1` + `tamper/1` + tree-walk helpers (re-homed from XmldsigSigner)
- `demo/ledger_loop/test/ledger_loop/fake_idp/signer_test.exs` — 151 lines; 7 tests covering byte-compat, replay uniqueness, tamper mutation, :digest_mismatch, anti-divergence guards

## Decisions Made

- **Vendored 4-step shape:** The signing technique is a re-homing of `XmldsigSigner.signed_response/1`'s 4-step shape into `LedgerLoop.FakeIdP.Signer`. The two load-bearing calls (`PureBeam.canonicalize` for digest, `C14N.serialize` for SignedInfo) are copied verbatim from `xmldsig_signer.ex:284-297`. This is the anti-divergence guarantee: the demo signer can never canonicalize differently from the verifier.
- **tamper/1 targets NameID:** Mutating the Response-level `<Issuer>` would produce `:issuer_mismatch` (a pre-crypto pipeline step), not the crypto rejection the demo showcases. Targeting the Assertion's `<NameID>` ensures the rejection fires at `do_verify/4` as `:digest_mismatch`, which is the intended cryptographic proof.
- **Test guard refinement:** The initial test for "no Relyra.TestSupport reference" triggered on the moduledoc comment. Fixed to use a regex matching actual `alias Relyra.TestSupport` or `Relyra.TestSupport.[A-Z]` call patterns. Similarly, the "no hand-rolled canonicalization" test was refined to check for `def(p)? canonicaliz` function definitions rather than string counts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test anti-divergence guards triggered on moduledoc/comment text**
- **Found during:** Task 2 (GREEN run)
- **Issue:** The "no Relyra.TestSupport reference" test matched the moduledoc comment; the "no hand-rolled canonicalization" test matched `@moduledoc`, `#` comments, and XML attribute strings (`CanonicalizationMethod`)
- **Fix:** Refined "no Relyra.TestSupport" to regex-match `alias` or function call patterns; refined "no hand-rolled canonicalization" to check for `defp? canonicaliz` function definitions
- **Files modified:** `demo/ledger_loop/test/ledger_loop/fake_idp/signer_test.exs`
- **Verification:** All 7 tests green

**2. [Rule 1 - Bug] signer.ex moduledoc contained "Relyra.TestSupport" string causing grep-c plan verification to return 1 instead of 0**
- **Found during:** Post-GREEN verification step (plan criterion: `grep -c "Relyra.TestSupport" signer.ex` is 0)
- **Fix:** Rewrote the security boundary paragraph in the `@moduledoc` to describe the constraint without naming the module
- **Files modified:** `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex`
- **Verification:** `grep -c "Relyra.TestSupport" signer.ex` = 0

## Known Stubs

None. The signer produces real signed XML and the tamper helper produces real rejected XML. No placeholder values.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes. The signer operates fully in-process; trust boundaries are unchanged (T-57-05 through T-57-08 mitigated as planned).

## Self-Check: PASSED

- `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex` — FOUND
- `demo/ledger_loop/test/ledger_loop/fake_idp/signer_test.exs` — FOUND
- Commit `7d9cc50` (RED test) — FOUND
- Commit `797b014` (GREEN implementation) — FOUND
- `grep -c "Relyra.TestSupport" signer.ex` = 0 — VERIFIED
- `grep -nE "C14N.serialize|PureBeam.canonicalize" signer.ex` — BOTH PRESENT
- 7/7 signer tests green — VERIFIED
- Full demo suite 50/50 — VERIFIED

---
*Phase: 57-demo-fakeidp-browser-login-proof*
*Completed: 2026-06-14*
