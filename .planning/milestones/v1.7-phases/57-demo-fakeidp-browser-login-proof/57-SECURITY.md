---
phase: 57
slug: demo-fakeidp-browser-login-proof
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-14
---

# Phase 57 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Register origin: authored at plan time (all three PLAN.md files carried a parseable
`<threat_model>` block). The audit verified each declared mitigation exists in the
implementation — it did not scan for new threats. The phase touches `demo/ledger_loop/`
only: `git diff main...HEAD -- lib/` is empty and `mix.exs` has no dependency changes,
so Relyra's published trust posture is unchanged.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| demo `priv/` secret → committed repo | Demo IdP RSA-2048 private key is committed; must be unmistakably demo-only (no real-world trust) | RSA private key (demo-only) |
| demo signer ↔ relyra `:prod` build | Demo path-dep compiles relyra in `:prod`; relyra TestSupport is stripped and must never be referenced at runtime | Elixir module references |
| fixture cert → relyra connection cert_chain | The seeded cert is the ONLY trust anchor relyra uses for …J0 (never document `KeyInfo`) | X.509 cert PEM |
| demo signer → relyra C14N engine | Canonicalization MUST be relyra's; a second canonicalizer is the auth-bypass class | XML canonical bytes |
| signed Response → relyra `do_verify/4` | The strict crypto gate; the demo earns a real pass, never weakens it | Signed SAML `<Response>` |
| browser → `/fake_idp/*` (untrusted form input) | `RelayState` / `idp_action` / `in_response_to` cross here; CSRF-protected via `:browser` pipeline | Form params |
| FakeIdP self-submitting POST → `/saml/:id/acs` | The signed (or tampered) SAMLResponse crosses into relyra's strict pipeline | base64 SAMLResponse |
| relyra `do_verify/4` → demo SessionAdapter | Only a verified assertion establishes a host session | Verified `LoginResult` |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-57-01 | Elevation | demo keypair leaking into prod trust | mitigate | Keypair + signer live in `demo/ledger_loop/` only; no `Relyra.TestSupport` alias/call; relyra `prod_elixirc_paths` `test_support` exclusion untouched. Evidence: relyra `lib/` diff empty; `keypair.ex` sole match is a moduledoc prohibition line | closed |
| T-57-02 | Spoofing | document-`KeyInfo` trust bypass | accept (relyra-owned) | relyra rejects `key_info_trust` (`signature.ex:174-178`); demo only sets the configured connection cert `:pem` (`fixtures.ex:121`) — trust source unchanged | closed |
| T-57-03 | Tampering/Repudiation | trace rows missing → tampered attempt invisible | mitigate | `LoginTrace.attach(repo: LedgerLoop.Repo)` wired post-`Supervisor.start_link` (`application.ex:31-34`); public API `login_trace.ex:62` | closed |
| T-57-04 | Tampering | fixture/signer cert drift | mitigate | Fixture `:pem` sourced from `Keypair.cert_pem/0` at compile time (`@demo_idp_cert_pem`, `fixtures.ex:8`, enabled row `fixtures.ex:121`) — single source, cannot drift | closed |
| T-57-05 | Tampering/Repudiation | divergent demo C14N masks a real verifier bug | mitigate | Signer calls ONLY `PureBeam.canonicalize` (`signer.ex:176`) + `C14N.serialize` (`signer.ex:184`); no local `defp canonicaliz`; grep-gated in `signer_test.exs:99-149` | closed |
| T-57-06 | Spoofing | weak crypto (SHA-1 / structure-only sig) | mitigate | RSA-SHA256 + SHA-256 digest via `:public_key` (`signer.ex:32-33,177,185`); real `{:ok}` pass under relyra allowlist `do_verify/4` (`signer_test.exs:44-53`) | closed |
| T-57-07 | Tampering | tampered assertion silently accepted | mitigate | `tamper/1` (`signer.ex:102-106`) → exact `:digest_mismatch` asserted (`signer_test.exs:83-92`) | closed |
| T-57-08 | Elevation | runtime use of `Relyra.TestSupport` (undefined in `:prod`) | mitigate | Signer aliases only relyra PUBLIC XML modules + `LedgerLoop.FakeIdP.Keypair` (`signer.ex:26-30`); `grep -c "Relyra.TestSupport" signer.ex` = 0 | closed |
| T-57-09 | Tampering | IdP-initiated bypass (`allow_idp_initiated?` mismatch) | mitigate | Flow is SP-initiated: affordance → `/saml/#{@conn_id}/login` (`route_affordance_html/login.html.heex:12`); InResponseTo captured (`fake_idp_controller.ex:49,114-124`); SP chain proven (`fake_idp_flow_test.exs:45-102`) | closed |
| T-57-10 | Spoofing | wrong ACS path / unscoped `/saml/acs` | mitigate | Self-submitting form posts to connection-scoped `/saml/<…J0>/acs` (`fake_idp_controller.ex:71-72`, `sso.html.heex:14`); test asserts scoped path (`fake_idp_flow_test.exs:84`) | closed |
| T-57-11 | Repudiation | tampered attempt leaves no audit trail | mitigate | `LoginTrace` writes `domain: :login` AuditEvent; flow test asserts `signature.verify.error_code == "digest_mismatch"` renders in the trace UI (`fake_idp_flow_test.exs:157-204`) | closed |
| T-57-12 | Spoofing | impression of a real production IdP | mitigate | "Local Test Support / FakeIdP" + "local testing harness" banner (`login.html.heex:3-4`); asserted in controller test | closed |
| T-57-13 | Input validation (V5) | malformed `SAMLRequest` inflate crash | mitigate | `login/2` nil-tolerant inflate + rescue (`fake_idp_controller.ex:114-139`); relyra parse-guards own the response path | closed |
| T-57-SC | Tampering | npm/pip/cargo installs (supply chain) | accept | Zero new dependencies — no `mix.exs` dep changes; `added: []` across all plan SUMMARYs | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-57-01 | T-57-02 | Document-`KeyInfo` trust is a relyra-owned invariant, already rejected at `signature.ex:174-178`. This phase only swaps the configured connection trust anchor (the demo cert) — it does not change the trust source, so no demo-side control is owed. | gsd-security-auditor (verified) | 2026-06-14 |
| AR-57-02 | T-57-SC | Supply-chain exposure is N/A — the phase adds zero dependencies (OTP stdlib + relyra public modules only). Confirmed: no `mix.exs` dep additions; `tech-stack.added: []` in all three SUMMARYs. | gsd-security-auditor (verified) | 2026-06-14 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-14 | 14 | 14 | 0 | gsd-security-auditor |

### Audit Notes (2026-06-14)

Adversarial checks that passed (mitigations verified in code, not inferred from intent):

- `grep -c "Relyra.TestSupport" keypair.ex` = 1 was inspected, not waved through — the single hit is a moduledoc prohibition line (`keypair.ex:6`); no `alias`/call exists. The stricter target (`signer.ex`) is a true 0.
- The two surviving `MOCK_PEM_NOT_REAL` strings (`fixtures.ex:130,143`) were traced to the *staged/next* cert rows. The *enabled* …J0 trust anchor is the real demo cert (`fixtures.ex:121`); the plan's "leave staged rows as-is" directive was followed — not a missed mitigation.
- T-57-02 accept was not treated as "not our problem": relyra's `KeyInfo`-trust rejection was located in source and the demo confirmed to leave the trust-source decision untouched.
- Phase scope confined to `demo/`: `git diff main...HEAD -- lib/` empty; relyra published posture unchanged.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-14
