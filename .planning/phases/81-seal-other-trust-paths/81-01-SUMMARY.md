---
phase: 81-seal-other-trust-paths
plan: 01
status: complete
requirements: [PATH-01, PATH-02, PATH-03, PATH-04, PATH-05]
commit: 32ae5e6
---

# Phase 81 Summary: Seal logout, redirect, encrypted, and metadata

**Outcome:** seams S13–S18 closed. `mix qa` (1067 tests, 0 failures) and
`mix ci.security` (exit 0) pass.

- **S15** POST logout binds the message root signature; embedded `<Assertion>`
  rejected (`:logout_assertion_forbidden`); type detection by parsed root.
- **S16** redirect rejects duplicate security query parameters.
- **S17** logout replay key connection/issuer-scoped.
- **S18** metadata derived from the authoritative signed EntityDescriptor via
  the single SaxyTree seam; regex extractor retired (invariant #2 restored).
- **S14** wire-span locator skips comment/CDATA/PI regions; **S13** plaintext is
  re-parsed through Phase-80 strict binding.

Permanent `trust_binding` corpus rows added for each. No test weakened.

## Residual (recorded)

- `extract_candidate_signing_pems/1` in `auto_refresh.ex` still scans candidate
  signing PEMs by byte regex BEFORE signature verification, then gates them by
  operator fingerprint pinning (pre-verify, trust-gated — not a derivation).
  Left as documented residual; a later pass can route it through the bound tree.
