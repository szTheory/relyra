# Phase 76: User Setup Required

**Generated:** 2026-09-26  
**Phase:** 76-lifecycle-and-recovery-journeys  
**Status:** Retired 2026-10-19 (never configured)

> **Retired.** The scheduled managed-IdP canary (`real-idp-canary.yml`, `scripts/test_real_idp_canary.sh`, `real_idp_canary.spec.ts`, `playwright.real-idp.config.mjs`) was removed on 2026-10-19.
>
> **Why:** it needed a hosted LedgerLoop staging deployment, a managed IdP account and named owners. None of them ever existed, so it failed daily with `configuration_incomplete`. It is also an operational monitor for a hosted service, which a library does not run. Real-IdP interop stays covered deterministically on every PR by the Keycloak container lanes (`adoption-external-idp`, `keycloak-proxy-e2e`).
>
> **What still satisfies EVID-03:**
> - the deterministic `external_canary_contract_test` in `ci.evidence`;
> - the daily `rulestead-main-canary` in `fleet-proxy-e2e.yml`, which is the scheduled external signal.
>
> The setup steps below are historical.

The deterministic evidence contract is implemented and runs in `ci.evidence`. The external health signal needs an owner-managed staging IdP connection and GitHub Environment values before it can prove provider availability. Until then, scheduled runs report `configuration_incomplete` with a status-only artifact; this setup does not block deterministic phase acceptance.

## GitHub Environment Configuration

Create or configure the repository environment named `real-idp-canary` under **Settings → Environments**. Add the following repository environment variables there. Do not put credentials in variables or planning files.

| Status | Variable | Source | Add to |
|--------|----------|--------|--------|
| [ ] | `REAL_IDP_CANARY_SP_LOGIN_URL` | The approved HTTPS LedgerLoop staging login route for the canary connection | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_SP_ORIGIN` | The exact HTTPS origin of the LedgerLoop staging instance, with no path or query | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_IDP_ORIGIN` | The exact HTTPS origin the managed IdP uses for its login page, with no path or query | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_PROVIDER_ALIAS` | A short non-secret label such as `northstar-staging` | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_OWNER` | The service owner’s name or team | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_CREDENTIAL_OWNER` | The dedicated account’s credential rotation owner | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_RESPONDER` | The team or role that responds to failed canary runs | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_RUNBOOK` | A short approved recovery reference, for example `docs/runbooks/real-idp-canary` | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_USER_SELECTOR` | Owner-approved username field selector: `#id`, `.class`, or `[name=field]` | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_PASSWORD_SELECTOR` | Owner-approved password field selector: `#id`, `.class`, or `[name=field]` | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_SUBMIT_SELECTOR` | Owner-approved submit control selector: `#id`, `.class`, or `[name=field]` | `real-idp-canary` environment variable |
| [ ] | `REAL_IDP_CANARY_USERNAME` | Dedicated canary account username | `real-idp-canary` environment secret |
| [ ] | `REAL_IDP_CANARY_PASSWORD` | Dedicated canary account password | `real-idp-canary` environment secret |

Keep the account limited to the staging connection and rotate its credentials through the named credential owner. Selectors and origins must describe the actual managed IdP flow. The runner accepts only the simple selector forms above and checks the exact HTTPS IdP origin before entering either credential.

## IdP and Staging Connection

- [ ] Register the staging LedgerLoop ACS URL for the selected connection in the managed IdP.
- [ ] Provision a dedicated canary user and an owner-approved sign-in policy for this staging-only automation flow.
- [ ] Confirm the connection uses the staging SP entity ID, ACS route, and configured IdP signing certificate.
- [ ] Confirm the canary user reaches the authenticated LedgerLoop workspace after a successful SAML response.
- [ ] Record the service owner, credential owner, responder, and recovery runbook reference in the `real-idp-canary` environment.

## Verification

After setting the environment values and completing the IdP setup, use **Actions → real-idp-canary → Run workflow** to dispatch a run. The workflow also runs daily at 08:31 UTC. Review its job summary and `real-idp-canary-status` artifact.

Expected success is `status: "passed"`, with the configured provider alias and named owners in the fixed status artifact. Failures must remain nonzero and report one of the allowlisted statuses (`configuration_incomplete`, `unexpected_origin`, `idp_rejected`, `callback_failure`, `provider_failure`). The artifact must contain only status metadata, never login material or browser recordings.

This repository does not contain live IdP credentials or an owner-provided staging endpoint, so no real-provider success is claimed here.

---

**Once all items are configured and a dispatch succeeds:** Update the status above to `Complete` and record the successful workflow run in the service’s normal operational record.
