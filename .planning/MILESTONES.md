# Milestones

## v1.5 Publish, Prove, Polish (Shipped: 2026-05-27)

**Phases completed:** 6 phases, 18 plans, 24 tasks

**Key accomplishments:**

- XML attribute escaper for SP metadata plus ci.security adversarial corpus for entityID/Location injection
- Production compile and Hex package exclude TestSupport via explicit lib file lists
- Retire regex-alongside-tree EncryptedAssertion locator; extract wire bytes from SaxyTree byte spans
- README and legacy planning docs aligned to 4 first-class presets + 7-family generic runbook; ENC-01 scoped to EncryptedAssertion
- Formatting-only cleanup of adversarial crypto corpus test file
- Process-scoped LoginTrace handler flushes domain:login audit rows and populates LoginResult.validation_trace from consume-path telemetry spans
- LoginTrace.Export redacts audit rows for UI/CLI parity; LiveAdmin query helpers fetch login traces and keep trust timelines login-free
- ConnectionTraceLive mounts at /connections/:id/trace with expandable six-step login rows, navigation link, and Phase 15 UI contract tests
- Headless `mix relyra.trace` CLI and security corpus proving LiveView/CLI redaction equivalence, wired into hollow-gate `ci.security`
- Version sources bumped to 1.4.0 with hand-written CHANGELOG backfill for v1.3/v1.4 milestones — Phase 44-ready, no tag or Hex publish
- Pre-push gates green and release-please stall diagnosis drafted — ready for maintainer-approved push in Plan 44-02.
- Pushed 115 commits to origin, closed stale PR #5, triggered release-please — PR #6 reconciled from erroneous 1.5.0 bump to 1.4.0 narrative CHANGELOG.
- Merged release PR #6; CI published relyra 1.4.0 to Hex with v1.4.0 tag — PUB-03 complete.
- Release parity Mix task compares git tag vX.Y.Z paths to Hex tarball over full package.files scope with test_support hard-fail and unit-tested pure functions.
- Live parity verification for relyra 1.4.0 vs git tag v1.4.0 passes with auditable PARITY-RESULT.md and executable milestone gate script.
- README now answers the 30-second question with a runnable Okta preset snippet above Start Here.
- Installer auto-injects SAML routes on unambiguous single-router hosts and falls back safely when detection is ambiguous.
- Documentation navigation is job-shaped; root BATTERIES_INCLUDED.md is canonical with ADFS in the generated proof map.

---
