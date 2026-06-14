---
phase: 57-demo-fakeidp-browser-login-proof
plan: "01"
subsystem: auth
tags: [saml, elixir, phoenix, public_key, telemetry, demo]

requires:
  - phase: 52-ecto-stores-and-deterministic-seed-story
    provides: Fixtures module, demo connection/cert seed infrastructure, LedgerLoop.Repo

provides:
  - RSA-2048 demo IdP keypair committed at demo/ledger_loop/priv/fake_idp/
  - LedgerLoop.FakeIdP.Keypair module (private_key/0 with :persistent_term cache, cert_pem/0)
  - Enabled connection fixture (…J0) with real demo cert PEM instead of MOCK_PEM_NOT_REAL
  - idp_sso_url for …J0 pointing at local FakeIdP (http://localhost:4000/fake_idp/login)
  - Relyra.Telemetry.Handlers.LoginTrace attached in Application (domain: :login AuditEvents)

affects:
  - 57-02 (signer + controller — uses the keypair and cert alignment built here)
  - 57-03 (flow tests — depends on fixture cert trust and LoginTrace for trace assertions)

tech-stack:
  added: []
  patterns:
    - "Keypair compiled from committed PEM; decoded RSA key cached in :persistent_term"
    - "Fixture cert PEM sourced at compile time from Keypair.cert_pem/0 to prevent fixture/signer drift (T-57-04)"
    - "LoginTrace attached post-Supervisor.start_link for idempotent telemetry wiring"

key-files:
  created:
    - demo/ledger_loop/priv/fake_idp/idp_key.pem
    - demo/ledger_loop/priv/fake_idp/idp_cert.pem
    - demo/ledger_loop/lib/ledger_loop/fake_idp/keypair.ex
    - demo/ledger_loop/test/ledger_loop/fake_idp/keypair_test.exs
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
    - demo/ledger_loop/lib/ledger_loop/application.ex

key-decisions:
  - "Compile-time @demo_idp_cert_pem attribute in Fixtures sources from Keypair.cert_pem/0 — single source of truth prevents fixture/signer cert drift (T-57-04)"
  - "fingerprint_sha256 computed via case :public_key.pem_decode/1 at module level (anonymous fn syntax unsupported as module attribute; pattern match on module attribute also unsupported)"
  - "LoginTrace.attach placed after Supervisor.start_link return, not inside children list; {:error, :already_exists} ignored for idempotency"
  - "Keypair.private_key/0 caches decoded key in :persistent_term keyed by {LedgerLoop.FakeIdP.Keypair, :private_key} — mirrors fake_idp.ex keypair caching pattern"

patterns-established:
  - "Pattern: compile-time cert PEM sourcing from module function into @attribute prevents fixture/signer drift"
  - "Pattern: :persistent_term cache for decoded crypto key material — avoids repeated disk+PEM decode per signing call"

requirements-completed: [SEED-003]

duration: 4min
completed: "2026-06-14"
---

# Phase 57, Plan 01: Demo IdP Keypair + Fixture Cert Alignment Summary

**RSA-2048 demo IdP keypair committed to priv/fake_idp/, fixture cert-trust wired to real cert via compile-time Keypair.cert_pem/0 call, and LoginTrace handler attached in Application so SAML login telemetry produces auditable domain: :login rows**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-06-14T00:44:26Z
- **Completed:** 2026-06-14T00:49:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Generated an RSA-2048 keypair + self-signed cert (`CN=ledgerloop-fake-idp`) via `:public_key.pkix_test_root_cert/2`; both PEMs committed as demo-only secrets under `demo/ledger_loop/priv/fake_idp/`
- Created `LedgerLoop.FakeIdP.Keypair` with `private_key/0` (decoded `{:RSAPrivateKey, ...}`, cached in `:persistent_term`) and `cert_pem/0` (literal PEM string); no `Relyra.TestSupport` references
- Replaced `MOCK_PEM_NOT_REAL` in the `@enabled_cert_id` fixture row with `LedgerLoop.FakeIdP.Keypair.cert_pem()` sourced at compile time; `fingerprint_sha256` recomputed from real cert DER
- Changed `…J0` connection `idp_sso_url` to `http://localhost:4000/fake_idp/login`; `idp_entity_id` preserved as `https://idp.northstar.example.com` (keeps `saml_identities/0` issuer alignment)
- Attached `Relyra.Telemetry.Handlers.LoginTrace` in `LedgerLoop.Application.start/2` after `Supervisor.start_link` (idempotent; `{:error, :already_exists}` silently accepted)
- All 6 `keypair_test.exs` assertions green; `mix compile --warnings-as-errors` exits 0

## Task Commits

Each task was committed atomically:

1. **Task 1: Generate demo IdP keypair + Keypair loader** - `b123382` (feat)
2. **Task 2: Align fixture cert-trust + idp_sso_url, attach LoginTrace** - `1fb681d` (feat)

## Files Created/Modified

- `demo/ledger_loop/priv/fake_idp/idp_key.pem` - Demo RSA-2048 private key (committed demo-only secret)
- `demo/ledger_loop/priv/fake_idp/idp_cert.pem` - Self-signed cert matching the private key
- `demo/ledger_loop/lib/ledger_loop/fake_idp/keypair.ex` - Runtime loader: `private_key/0` + `cert_pem/0`
- `demo/ledger_loop/test/ledger_loop/fake_idp/keypair_test.exs` - 6 tests: key/cert existence, decode, file equality, sign/verify round-trip
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` - `@demo_idp_cert_pem` attribute + `@demo_idp_cert_fingerprint`; `@enabled_cert_id` pem/fingerprint updated; `…J0` `idp_sso_url` updated
- `demo/ledger_loop/lib/ledger_loop/application.ex` - `LoginTrace.attach(repo: LedgerLoop.Repo)` after Supervisor.start_link

## Decisions Made

- **Compile-time cert PEM:** `@demo_idp_cert_pem LedgerLoop.FakeIdP.Keypair.cert_pem()` as a module attribute evaluated at compile time. Elixir evaluates non-literal attribute values at compile time, so the cert PEM is frozen into the BEAM at build — the fixture and the signer use the exact same bytes by construction.
- **Fingerprint via case:** Elixir prohibits pattern matching on module attributes at module level and anonymous function invocation syntax (`(fn -> ... end)()`) is a parse error as an attribute. Used `@attribute (case ... do ... end)` which compiles correctly.
- **`idp_entity_id` left unchanged:** Per Pitfall 4 (RESEARCH.md), changing `idp_entity_id` would require updating all `saml_identities/0` issuer values. Since the only required change is `idp_sso_url` (where the browser redirects), `idp_entity_id` stays `https://idp.northstar.example.com`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed compile-time fingerprint computation syntax**
- **Found during:** Task 2 (Fixture cert-trust alignment)
- **Issue:** Plan implied computing the fingerprint at build time from the cert; anonymous function invocation (`(fn -> end)()`) is a syntax error as a module attribute value; pattern-matching on `@attribute` at module level is also forbidden
- **Fix:** Used `(case :public_key.pem_decode(@demo_idp_cert_pem) do [{:Certificate, der, :not_encrypted}] -> Base.encode16(:crypto.hash(:sha256, der)) end)` as the attribute RHS — valid Elixir at module level
- **Files modified:** `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex`
- **Verification:** `mix compile --warnings-as-errors` exits 0
- **Committed in:** `1fb681d`

**2. [Rule 1 - Bug] Fixed sign/verify round-trip test: OTP tuples not maps, pkix_extract_public_key unavailable**
- **Found during:** Task 1 (keypair_test.exs)
- **Issue:** Test initially used `Map.get/2` on OTP certificate tuples and called `:public_key.pkix_extract_public_key/1` which is undefined or private in the installed OTP version
- **Fix:** Pattern-matched on `{:OTPCertificate, {:OTPTBSCertificate, ..., {:OTPSubjectPublicKeyInfo, _alg, rsa_pub_key}, ...}, ...}` tuple shape to extract public key
- **Files modified:** `demo/ledger_loop/test/ledger_loop/fake_idp/keypair_test.exs`
- **Verification:** All 6 tests green
- **Committed in:** `b123382`

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both were straightforward OTP API / Elixir syntax corrections. No scope creep; all acceptance criteria met.

## Issues Encountered

None beyond the two auto-fixed bugs above.

## Known Stubs

None. The keypair PEMs are real committed values; the fixture cert is the real cert; idp_sso_url points at the real local endpoint.

## Threat Flags

None. No new network endpoints or trust boundaries introduced beyond those in the plan's threat model. The committed `idp_key.pem` is demo-only with no real-world trust as designed.

## Next Phase Readiness

- Wave-0 prerequisites complete: keypair PEMs committed, fixture cert aligned, idp_sso_url wired, LoginTrace attached
- Plan 57-02 (signer + controller) can proceed: it uses `LedgerLoop.FakeIdP.Keypair.private_key/0` for signing and relies on the `…J0` fixture cert being the demo cert
- No blockers

## Self-Check: PASSED

- `demo/ledger_loop/priv/fake_idp/idp_key.pem` — FOUND
- `demo/ledger_loop/priv/fake_idp/idp_cert.pem` — FOUND
- `demo/ledger_loop/lib/ledger_loop/fake_idp/keypair.ex` — FOUND
- `demo/ledger_loop/test/ledger_loop/fake_idp/keypair_test.exs` — FOUND
- Commit `b123382` — FOUND (Task 1)
- Commit `1fb681d` — FOUND (Task 2)

---
*Phase: 57-demo-fakeidp-browser-login-proof*
*Completed: 2026-06-14*
