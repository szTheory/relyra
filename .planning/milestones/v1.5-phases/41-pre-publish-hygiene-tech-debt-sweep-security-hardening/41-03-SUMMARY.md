---
phase: 41-pre-publish-hygiene-tech-debt-sweep-security-hardening
plan: 03
subsystem: security
tags: [xml, encrypted-assertion, parse-tree, td-03, one-trust-path]

requires: []
provides:
  - Optional start_byte/end_byte on SaxyTree.Node for wire-format element spans
  - Tree-bound EncryptedAssertion slice in ValidationPipeline (no regex)
affects: [41-04, 41-05, 42]

tech-stack:
  added: []
  patterns: [parse-tree-bound binary extraction for decrypt splice input]

key-files:
  created: []
  modified:
    - lib/relyra/security/xml/saxy_tree.ex
    - lib/relyra/protocol/validation_pipeline.ex
    - test/relyra/protocol/decrypt_assertion_test.exs

key-decisions:
  - "Fail closed to :ambiguous when byte spans are missing or out of bounds"
  - "ParserPathGuard: avoid 'Saxy' token in validation_pipeline comments"

patterns-established:
  - "Encrypted assertion wire bytes extracted via parse-tree node spans on the same parse pass"

requirements-completed: [TD-03]

duration: 12min
completed: 2026-05-27
---

# Phase 41 Plan 03 Summary

**Retire regex-alongside-tree EncryptedAssertion locator; extract wire bytes from SaxyTree byte spans**

## Performance

- **Duration:** 12 min
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Extended `SaxyTree.Node` with optional `start_byte`/`end_byte` recorded during the single parse pass
- Replaced `locate_encrypted_assertion/1` regex with `locate_encrypted_assertion/2` using `binary_part/3` on tree spans
- Added span-fidelity regression test for unprefixed and `saml:`-prefixed EncryptedAssertion fixtures

## Task Commits

1. **Add wire-format byte spans to SaxyTree nodes** - `57ffdea`
2. **Replace encrypted assertion regex with tree spans** - `a172d53`
3. **Assert EncryptedAssertion span fidelity** - `9c87d50`

## Verification

```
mix test test/relyra/protocol/decrypt_assertion_test.exs \
  test/security/xml_enc_adversarial_test.exs \
  test/security/xml_enc_test.exs --warnings-as-errors
# 21 tests, 0 failures
```

No `~r/` regex remains in `locate_encrypted_assertion`; ENC-01 ambiguity and `:decryption_failed` behavior unchanged.

## Deviations from Plan

None - plan executed exactly as written.

---
*Phase: 41-pre-publish-hygiene-tech-debt-sweep-security-hardening*
*Completed: 2026-05-27*
