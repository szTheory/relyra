# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Post-v1.6 milestone-next assessment (2026-05-28)

**Context:** Adopter-first assessment after v1.6 Adoption Truth shipped. Repo inspection (`lib/`, `test/`, `priv/conformance/`, guides) — not milestone-name trust.

**Done-%:** ~93% (90–95% band). v1.6 Adoption Truth criteria MET per `docs/jtbd_gap_map.md`.

**Verdict:** Pause default — no new feature milestone until GitHub issue, adopter request, or maintenance release. Do not bundle AUTHN-POST + KMS + SIGNED-META.

**Single pick when work resumes:** Issue-driven triage; first protocol wedge likely AUTHN-POST-01 (~1 week). Phase numbering continues from **50**.

**Residual (low severity):** `guides/jtbd_user_flows.md` Scene 3 lists three batteries-included presets; Getting Started/README list four (ADFS omitted in flows doc).

**Graduation candidates (cross-phase):**

1. Run post-ship milestone assessment thread before `/gsd-new-milestone` when `milestone_pause_when_done_enough` is true.
2. On doc milestones, keep `jtbd_user_flows` preset taxonomy aligned with Getting Started §4.
3. Adoption Truth is a one-time pattern at done-enough — do not repeat without new gap evidence.

**Thread:** `.planning/threads/v1-7-milestone-assessment-2026-05-28.md`

---

## Milestone: v1.6 — Adoption Truth

**Shipped:** 2026-05-28
**Phases:** 5 (3 scope + 2 gap-closure) | **Plans:** 15 | **Tasks:** 46

### What Was Built

- **Onboarding truth (Phase 47).** Getting Started §3 promotes TestSupport macro round-trip; manual FakeIdP builder demoted to appendix; new `guides/production_ecto_path.md` with migrations, resolver, store swap, and ETS prod warning.
- **Operator completeness (Phase 48).** Incident playbook documents login-trace LiveView and `mix relyra.trace` across evidence surfaces, scenarios 3–6, and Day-2 hub cross-links.
- **Adoption honesty (Phase 49).** CONFORMANCE scope boundary + ENC manifest pass row; jtbd_gap_map refreshed to v1.5+ shipped reality; Keycloak/OneLogin decoder rows and four batteries-included presets aligned.
- **Gap closure (Phases 49.1–49.2).** Ecto path → Day-2 ops forward handoff; README/jtbd cross-links; retroactive Phase 47 Nyquist VALIDATION.md; editorial polish per audit.

### What Worked

- **Doc-only boundary held.** No protocol surface creep despite rich codebase — milestone stayed at adoption-truth wedge.
- **Audit-driven gap closure.** Pre-close audit inserted 49.1/49.2 instead of shipping with known handoff gaps; integration score went 3/4 → 4/4.
- **D-15 precedent for doc-only phases.** No new ci.docs drift tests when presence guards suffice — kept hollow-gate discipline without test sprawl.
- **Adoption Truth pattern at done-enough line.** Closes asymmetry between shipped code and adopter story without reopening protocol work.

### What Was Inefficient

- **REQUIREMENTS.md gap-closure table lagged audit.** Traceability still showed 49.1/49.2 items as Pending after phases completed — fixed at milestone close, not during execution.
- **summary-extract one_liners sparse.** Phase SUMMARY frontmatter lacks `one_liner` field; accomplishment extraction fell back to manual reads.

### Patterns Established

- **Adoption Truth milestone type.** Doc wedge at ~92–95% done-enough: onboarding path, production deploy guide, ops tool surfacing, CONFORMANCE honesty, planning-doc refresh.
- **Decimal gap-closure after audit.** 49.1 (handoff) + 49.2 (Nyquist retro + editorial) mirrors v1.4's 40.1 pattern for doc milestones.
- **Forward-nav footers on deploy guides.** `production_ecto_path.md` Related Day-2 guides footer prevents adopters backtracking through overview.

### Key Lessons

1. **Run milestone audit before close, then gap-close.** v1.6 audit on 2026-05-27 found real handoffs; 49.1/49.2 closed them before archive — cleaner than accepting tech debt.
2. **Adoption truth is a milestone, not a phase.** Six ADOPT requirements across three phases plus two closure phases — scope as milestone, not single doc PR.
3. **Pause default is correct post-v1.6.** Protocol candidates remain save-for-demand; next work needs GitHub issue signal.

## Milestone: v0.5 — Operational maturity

**Shipped:** 2026-05-07
**Phases:** 4 (2 scope + 2 closure) | **Plans:** 15 | **Tests at close:** 358/358

### What Was Built

- **Bulk Operations (CFG-07).** Phase 20 delivered bulk enable/disable/refresh for connections. Enforced sequential execution to avoid DB pressure and unified audit correlation ID for batched transactions.
- **Scheduled Metadata Refresh (CFG-08).** Phase 21 delivered an automated ticker for background metadata refresh with configurable cadences. Includes asymmetric strictness (unattended background jobs require signed metadata) and failure backoff with auto-suspension.
- **Telemetry & Observability.** Granular `[:relyra, :saml, :metadata, :auto_refresh, ...]` telemetry namespaces and an opt-in reference `LogAlerts` handler.

### What Worked

- **Extending the Closure-Phase Pattern (Phases 21.1, 21.2).** The milestone audit surfaced an integration BLOCKER (bulk refresh dropping correlation_id) and scope drift (2 unbuilt features). Instead of reopening Phases 20 and 21, two small closure phases were added. This contained the blast radius, cleanly resolved the gaps, and kept the audit trail transparent.
- **Asymmetric Strictness for Automation.** Manual overrides allow leniency, but automated background routines enforce strictness (e.g., unsigned metadata must be manually applied). This preserved UX without weakening the security posture.
- **Single-Transaction Audit Enforcement.** The invariant that every mutation co-commits an audit log was successfully preserved through bulk processes and automated Oban workers by forcing all paths through the `transact/2` wrapper in `MetadataApply`.
- **Wave-0 Stub Pattern.** Pre-creating test files (`:pending`) for multi-wave phases ensured that future wave plans hit real paths right away, giving a loud signal via `flunk` if a stub wasn't overwritten.

### What Was Inefficient

- **Scope Drift Without Re-Alignment.** v0.5 was scoped for 4 features, but only 2 were built. No canonical `v0.5-REQUIREMENTS.md` was created, making the audit flag the missing features late. Scope changes should be proactively documented when features (like Debug Bundles and Expiry Alerts) are deferred.
- **Cross-Phase Integration Gaps.** Phase 20 (bulk ops) and Phase 9/21 (refresh) didn't seamlessly connect. The legacy `Refresh.refresh/2` failed to forward the new bulk `correlation_id` and `actor`. This integration blocker highlights the need for stronger cross-phase E2E validation earlier.
- **Documentation Drift.** Phase 20 bulk features were entirely missed in the README. Only caught by the final milestone audit.

### Patterns Established

- **Audit-Gap Closure Phases.** Phases like 21.1 and 21.2 prove that closure phases work not just for tests (v0.2), but for security blockers and scope realignment as well.
- **Wave-0 Test Stubbing.** Laying out all test files before code is written guarantees high Nyquist coverage and eliminates missed integration seams during later waves.
- **Strict-by-Default Automation.** Unattended processes MUST be stricter than operator-driven manual overrides.

### Key Lessons

1. **Verify integration between isolated phases.** Two phases that pass Nyquist tests in isolation can still fail when stitched together (e.g., bulk ops executing a legacy refresh path).
2. **Re-align scope early.** When deciding to defer work, update `PROJECT.md` immediately rather than waiting for the milestone audit to complain about orphaned requirements.

## Milestone: v0.2 — Enterprise Configuration

**Shipped:** 2026-05-06
**Phases:** 8 (5 scope + 3 closure) | **Plans:** 25 | **Tests at close:** 168/168 (serial)

### What Was Built

- **Durable connection records (CFG-01).** `Relyra.Ecto.Connection` aggregate with internal binary PK + public `connection_id`, lifecycle status (draft/enabled/disabled), child certificate inventory, and minimal create/update/enable/disable persistence API. Runtime-readiness is a separate explicit gate.
- **Resolver snapshot boundary (CFG-02).** `Relyra.ConnectionResolver.Ecto` returns a normalized `%Relyra.Connection{}` value struct via dedicated `ConnectionLoader` + `ConnectionSnapshot`. No Ecto rows leak above the resolver. Login, metadata, and protocol validation all consume the same canonical snapshot with `idp_certificates` precedence.
- **Metadata import/export + controlled refresh (CFG-03).** `Relyra.Metadata.import_xml/3`, `register_source/3`, `refresh/2`. Single transactional apply seam with last-known-good preservation on failure. Endpoint precedence: HTTP-Redirect → HTTP-POST → remaining. Optional `Req` for HTTPS metadata fetches. Telemetry redacted.
- **Certificate inventory + staged rollover (CFG-04).** `Relyra.Ecto.CertificateInventory` owns `:active` / `:next` / `:retired` lifecycle with per-cert `not_before` / `not_after` facts, optimistic-locked transitions, and typed `:conflict` errors on stale writes. Snapshot hydrates only `:active` certs.
- **Persisted mappings + cross-domain audit ledger (CFG-05).** `AttributeMapping`, `GroupMapping`, append-only `MappingRevision`. `MappingCommands` co-commits live row replacement + revision row + audit event in one transaction. Cross-domain audit hardening (Plan 11-03) extends same-transaction audit capture to connection, metadata, and certificate writes via a single `Relyra.Ecto.AuditWriter.append_event` seam.

### What Worked

- **Closure-phase pattern (Phases 12, 13, 14).** When the 2026-05-05 milestone audit surfaced verification orphans for CFG-03/04/05, the response was three small purpose-built closure phases that produced the missing `09/10/11-VERIFICATION.md` artifacts (plus one regression repair) instead of re-opening implementation. Smaller blast radius, cleaner audit trail, manual sign-off captured per artifact, and no regressions to the v0.2 implementation work that had already passed phase verification. Worth carrying forward as a canonical move.
- **Single audit-writer seam.** Routing all four mutation modules (Connections, MetadataApply, CertificateInventory, MappingCommands) through `Relyra.Ecto.AuditWriter.append_event` inside the same transaction made cross-domain audit hardening (Plan 11-03) a contained refactor rather than a sweep. The audit ledger cannot drift from the data it describes because there's only one writer with one redaction policy.
- **Public ID separation from internal PK.** Persisting connections with internal binary PK + public `connection_id` join key meant the resolver, validation pipeline, and audit ledger all reference the same stable public identity even as the persistence shape evolves. Avoids the Spring/Sustainsys footgun where downstream code couples to ORM rows.
- **Operator-triggered refresh.** Holding the line on "metadata refresh is operator-triggered only; new signing certs stage as `:next`" eliminated an entire class of silent trust-shift bugs. The brand metaphor ("verified trust path") is now also the implementation contract.
- **3-source requirements cross-reference at audit time.** Checking each REQ-ID against (a) phase VERIFICATION.md, (b) phase SUMMARY.md frontmatter, and (c) REQUIREMENTS.md traceability caught the orphan pattern that the original gap_found audit surfaced — and gave the closure phases a precise definition of done.

### What Was Inefficient

- **Initial v0.2 close attempted with stale audit.** The 2026-05-05 audit was already three phases out of date when `/gsd-complete-milestone` was first invoked. The pre-flight check correctly forced a re-audit before archive — but the time would have been saved by running `/gsd-audit-milestone` immediately after the last closure-phase commit instead of treating the audit as a one-shot artifact.
- **`MappingCommands.append_audit/8` divergence from the explicit-rollback pattern.** The other three co-commit sites all use the explicit `rollback(repo, error)` pattern; `MappingCommands` returns `{:error, _}` from inside the `with` chain and relies on `transact/1` auto-rollback. Caught only at integration-check time, not during phase code review. Not a correctness bug on modern Ecto, but a consistency gap that should have been caught earlier.
- **Parallel migration bootstrap races.** Phase 08 (and re-confirmed during v0.2 close) showed that parallel Mix smoke suites can race the Ecto migration bootstrap and produce false-negative results. Tracked as operational guidance ("run smoke serially") but worth automating in CI before v0.3 instead of relying on operator memory.

### Patterns Established

- **Closure-phase pattern.** When an audit surfaces verification orphans for already-shipped implementation, prefer producing the missing verification artifacts in a small dedicated phase over re-opening implementation. The closure phase's deliverable IS the upstream-phase verification artifact; it doesn't need its own VERIFICATION.md.
- **Single co-commit seam per mutation domain.** All four v0.2 mutation modules write audit rows through one shared `AuditWriter.append_event` inside the same transaction as the change. This is the canonical pattern for any future trust-mutation surface in Relyra.
- **Public-ID separation.** Internal binary PK + public string ID join key for any persisted aggregate that has runtime consumers. The runtime never sees the internal PK; the persistence layer never exposes the runtime value struct.
- **Stage-then-promote for trust shifts.** Newly fetched / newly imported signing material stages as `:next`; promotion is explicit operator action. Runtime trust never shifts implicitly on a fetch / parse / apply event.
- **3-source REQ cross-reference at milestone audit.** VERIFICATION.md + SUMMARY frontmatter + REQUIREMENTS.md traceability — any disagreement is a gap signal.

### Key Lessons

1. **Audits decay.** A milestone audit reflects a point-in-time snapshot. After any phase that materially changes coverage (closure phases, regression repairs, new VERIFICATION artifacts), re-run `/gsd-audit-milestone` before treating the audit as the close-readiness check.
2. **Cross-cutting consistency lives in patterns, not lint rules.** The `MappingCommands.append_audit` divergence wasn't caught by code review because the pattern (explicit rollback on co-commit failure) wasn't documented as a hard rule. Either codify cross-cutting patterns in `CLAUDE.md`/`AGENTS.md` or write a Credo check for them.
3. **Closure phases beat re-opening implementation.** Three small closure phases closed three audit orphans without touching any of the green implementation work or producing a single regression in the 168-test serial suite. The cost of reopening even a verified phase is much higher than the cost of a clean closure phase.
4. **Operator-triggered, not implicit.** Trust shifts (new signing material activated, certificates promoted, mappings replaced) must always be the result of an explicit operator action, never a side effect of a fetch/parse/apply event. Holding this line in v0.2 retroactively justifies the v0.1 strict-by-default posture.
5. **Audit before archive.** Pre-flight `audit-milestone` is non-optional. The 2026-05-05 → 2026-05-06 audit refresh caught no new issues — but it confirmed the closure phases actually closed what they claimed.

### Cost Observations

- Model mix: not measured (Claude Code session — primary model: Opus 4.7 1M).
- Sessions: not exhaustively counted; the closure-phase chain (12 → 13 → 14) ran inside the milestone-close session continuum.
- Notable: closure phases 12-14 produced their entire deliverable (regression repair + serial verification packets + planning-truth updates + per-phase manual sign-off) in roughly the same per-phase rhythm as a normal scope phase, suggesting the closure-phase pattern is not noticeably more expensive than the alternative of re-opening implementation.

---

## Milestone: v1.5 — Publish, Prove, Polish

**Shipped:** 2026-05-27
**Phases:** 6 | **Plans:** 18 | **Requirements:** 15/15

### What Was Built

- **Pre-publish hygiene (Phase 41).** Closed v1.3 audit warnings: metadata attribute XML escaping, `test_support` excluded from prod/Hex artifact, regex-alongside-tree retired from encrypted-assertion path, doc drift fixes, repo-wide `mix format` clean.
- **Login trace UI (Phase 42).** `ConnectionTraceLive` at `/relyra/admin/connections/:id/trace` plus `mix relyra.trace` headless companion. Reuses telemetry + audit ledger only — no parallel storage. Security corpus in `mix ci.security` proves redaction equivalence.
- **Hex publish (Phases 43-44).** Version bump to `1.4.0`, CHANGELOG backfill, release-please stall diagnosed and fixed (stale PR #5 closed, PR #6 merged), `1.4.0` published via CI automation.
- **Parity verification (Phase 45).** `mix verify.release_parity 1.4.0` compares Hex tarball path-set to git tag; **PASS** with auditable `PARITY-RESULT.md`.
- **Adopter DX (Phase 46).** README Okta snippet above the fold, installer auto-injects `saml_routes()` when unambiguous, job-shaped `guides/overview.md`.

### What Worked

- **Phase reorder (42 before 43).** Sequencing trace LiveView before publish prep ensured the `v1.4.0` Hex tarball ships the trace UI by construction — no separate "slip to 1.4.1" coordination.
- **TD-02 before publish.** Excluding `test_support` from the artifact before Phase 44 publish meant parity verification (Phase 45) proved correctness of the tarball adopters actually install, not just git-tag byte equality.
- **Release-please diagnosis artifact.** `RELEASE-PLEASE-DIAGNOSIS.md` documents the stall root cause (unpushed commits + stale open PR) so recurrence is detectable.
- **Shared redaction helper.** `LoginTrace.Export` serves both LiveView and CLI — one redaction policy, security corpus proves equivalence.

### What Was Inefficient

- **No v1.5 milestone audit before close.** Pre-flight recommended `/gsd-audit-milestone`; proceeded with open-artifact audit only (all clear). A formal milestone audit would have been belt-and-suspenders for a publish milestone.
- **Large git diff range.** Phase 41-46 span includes release-please merge history; stats are noisy for LOC attribution.

### Patterns Established

- **Publish-before-parity ordering.** Always verify the *published* Hex tarball, not just local git tag, when closing a publish milestone.
- **Trace UI reuses audit co-commit store.** Login traces read from existing `domain:login` audit rows — no second source of truth.
- **Single Hex jump (1.2.0 → 1.4.0).** CHANGELOG retains `[1.3.0]` section for historical readers; Hex sees one release.

### Key Lessons

1. **Tarball correctness beats tag correctness.** Phase 45 path-set diff catches `test_support` leakage that a git-tag-only check would miss if `package.files` drifted.
2. **Reorder phases when publish artifacts are the deliverable.** Anything that must ship in the published tarball must land before the version bump commit release-please sees.
3. **Done-enough is a real milestone outcome.** v1.5 intentionally ships no new protocol features — closing the adopter visibility gap is the product event.

### Cost Observations

- Model mix: not measured (Cursor session).
- Timeline: single day (2026-05-27) for all six phases.
- Notable: yolo mode auto-approved scope gates; 18 plans executed without milestone audit file.

---

## Post-v1.6 maintenance (2026-05-28)

**Scope:** Hex patch hygiene and CI/CD enforcement — not a feature milestone.

### What happened

- **Red CI on `main`:** three test files were unformatted locally but never committed; `security-gates` failed at `mix qa` while **Release Please** still published **1.5.0** (publish job did not run `mix qa`; no branch protection).
- **Fixes shipped:** format commit; `mix qa` on Hex publish path; `fetch-depth: 0` for release-parity integration; LiveAdmin endpoint ETS health-check; branch protection with `enforce_admins`; release-please automerge; `BRANCH_PROTECTION_PAT` + daily re-assert workflow; pre-commit hook for format check.
- **Hex 1.5.1 shipped:** patch bumps `ex_doc` 0.40.3, `req` 0.5.18; `fix(ci)` commit to satisfy release-please user-facing changelog; PR #11 merged with human-triggered `security-gates` on bot branch.
- **Release-please bot PRs:** GitHub skips `pull_request` workflows for `GITHUB_TOKEN`-created PRs. Mitigation shipped: `release-please-pr-checks.yml` dispatches `security-gates` and PAT nudges the release branch; automerge polls OTP 27/28 checks before merge. PAT fallback remains if dispatch alone does not attach checks to the PR.
- **Planning-only PRs:** `security-gates` uses `paths-ignore: .planning/**`, so phase closeout PRs (e.g. `STATE.md` only) never get required checks on the PR. `workflow_dispatch` runs green on the branch but does not satisfy merge under `enforce_admins`. Mitigation shipped: `planning-pr-checks.yml` updates `.github/planning_ci_ref.txt` on the PR branch so `pull_request` `security-gates` runs and attaches `security (27|28, 1.19.5)` to the PR.

### Lessons

1. **Publish path must run the same gate as `main`.** Adding `mix qa` to `publish-hex` closes “red main, green Hex.”
2. **`enforce_admins` is required** for shift-left — without it, admins bypass required checks silently.
3. **Pre-commit is cheap insurance** against agent/human format drift.
4. **Bot release PRs need a human nudge for CI** under branch protection — document or automate (e.g. `workflow_run` dispatch on release branch).
5. **Planning-only PRs need a non-`.planning/` path on the PR diff** for required checks to attach — automate via `planning-pr-checks.yml` (not `workflow_dispatch` alone).

---

## Milestone: v1.9 - Loose Ends & Adoption Honesty

**Shipped:** 2026-06-19
**Phases:** 4 | **Plans:** 13

### What Was Built

- Public `Relyra.Testing` fixtures: signed success, typed rejection fixtures, explicit consume opts, package-included public modules, and Phoenix-optional ACS dispatch.
- Documentation truth: README, Getting Started, recipes, overview, generated batteries proof, demo tests, and drift tests now route Hex adopters through public `Relyra.Testing`, not private `Relyra.TestSupport`.
- LedgerLoop FakeIdP disposition: retained as demo-local browser proof, documented in `guides/fake_idp_demo.md`, with success/tamper behavior and port-4000 caveat explicit.
- Maintenance sync: `CVE-2026-49454` backfilled, CI/release guard notes refreshed, Phase 29 warning follow-ups given item-level dispositions, and SEED-001..003 moved to resolved/historical status.

### What Worked

- Treating public test helpers as a test-only API kept adopter DX honest without moving private adversarial corpus internals into Hex.
- Release parity proof stayed artifact-level: local Hex unpack checks proved `lib/relyra/testing*` ships and `lib/relyra/test_support*` does not.
- Phase 66's explicit retain/remove checkpoint prevented stale FakeIdP work from lingering as ambiguous demo scope.
- Phase 67 separated planning truth from code fixes: warning dispositions were recorded without implying crypto/parser changes.

### What Was Inefficient

- The milestone audit had to be created during completion because `v1.9-MILESTONE-AUDIT.md` was missing at closeout.
- Nyquist validation metadata stayed uneven across phases even though phase verification and requirements coverage were complete.
- `~/.agents/gsd-core/bin/gsd-tools.cjs` was broken locally due to missing package metadata; the PATH `gsd-tools` binary worked and should be preferred in this environment.

### Patterns Established

- Public testing helpers should return explicit fixture/trust material and avoid global resolver or Application env mutation.
- Package-boundary claims should be proven against an unpacked artifact, not source tree presence alone.
- Demo-local IdP support can remain when it is named precisely, bounded to local proof, and documented with caveats.
- Resolved seeds should be marked as historical records so they do not resurface as future milestone candidates.

### Key Lessons

1. A public testing API can improve adoption honesty without weakening the production trust boundary when it reuses verifier primitives and keeps trust material explicit.
2. Documentation truth needs executable drift tests; otherwise private helper names leak back into adopter-facing paths.
3. Closeout audits should run before completion, even when phase verification is already green, because audit metadata quality is a separate planning concern.

### Cost Observations

- Model mix: not measured.
- Timeline: v1.9 started 2026-06-15 and shipped 2026-06-19.
- Notable: completion used manual in-process integration review because subagent delegation was not explicitly requested in this Codex runtime.

---

## Milestone: v1.10 — Docker DX & Fleet Proxy

**Shipped:** 2026-08-27
**Phases:** 6 | **Plans:** 30 | **Tasks:** 51

### What Was Built

- Cached, architecture-correct Docker development with lock-content-aware boot and real browser live reload.
- Solo-first Compose plus opt-in shared Traefik fleet routing that avoids host port collisions.
- A genuine Keycloak signed-SAML proof with audited descriptor trust, protected traces, and recurring CI.
- A Make-first launcher, deterministic diagnostics, and a self-contained evaluator documentation journey.
- Connection-scoped evaluator endpoints and runtime Basic Auth for fail-closed trace access.

### What Worked

- The demo/docker/docs boundary held: no Relyra public API, parser, crypto, replay, or package-surface change was needed.
- Mandatory CI lanes modeled browser, Docker, credentials, failures, and recovery without adding a new human completion gate.
- Audit-driven closure fixed real endpoint and trace-auth handoffs in Phase 72.1, then strict three-source reconciliation closed metadata-only gaps.
- A dedicated disposable Phase 68 harness converted four historical manual receipts into deterministic Docker/Chromium evidence.

### What Was Inefficient

- Phase 68's first automation pass had readiness, log-pipeline, browser-subscription, and origin mismatches; several full Docker cycles were needed before the harness reflected the real contract.
- Docker's VM disk reached 100% during validation; a constrained prune of unused build cache older than 24 hours was required before evidence could complete.
- GSD's generated audit filename was duplicated, the archival parser initially excluded inserted Phase 72.1, and legacy summaries caused the generated task count to under-report 51 tasks as 15.

### Patterns Established

- Runtime-only Docker acceptance belongs in an owned disposable harness, including cleanup, live browser behavior, and current-container log assertions.
- Always dry-run milestone archival and compare its phase/plan counts with `STATE.md`, especially when decimal closure phases exist.
- Preserve strict origin policy in the app; browser harnesses should use the configured public host instead of weakening `check_origin`.

### Key Lessons

1. Cache correctness is behavioral: prove BuildKit vertices, nested volume masking, lock branches, and live reload, not just configuration shape.
2. Milestone evidence has its own integrity contract: REQUIREMENTS, VERIFICATION, SUMMARY frontmatter, and authoritative VALIDATION status must agree.
3. Archive automation needs a scope preview; a successful command with the wrong phase set is still a failed closeout.

### Cost Observations

- Model mix: not measured.
- Timeline: Phase 68 began in June; the active v1.10 completion push finished 2026-08-27.
- Notable: deterministic closeout found harness and archive-tool defects without changing product security posture.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v0.1 | 6 | 19 | Established XML-trust-boundary ADR pattern + behaviour-backed store contracts. |
| v0.2 | 8 (5+3) | 25 | Established closure-phase pattern; established single-AuditWriter seam; established public-ID/internal-PK separation for persisted aggregates. |
| v1.10 | 6 (5+1) | 30 | Established disposable Docker/Chromium acceptance and dry-run scope reconciliation for decimal closure phases. |

### Cumulative Quality

| Milestone | Tests at close | Code LOC (lib + test) | New patterns added |
|-----------|----------------|-----------------------|--------------------|
| v0.1 | n/a (not recorded) | n/a | XML-ADR, behaviour-stores, opaque-RelayState |
| v0.2 | 168/168 (serial) | 16,534 | closure-phase, AuditWriter seam, public-ID/internal-PK, stage-then-promote |
| v1.10 | 32 focused docs tests + Phase 68 Docker/Chromium harness | no library-surface change | disposable runtime acceptance, archive-scope preview |

### Top Lessons (Verified Across Milestones)

1. **Strict defaults pay back across milestones.** v0.1 locked "no implicit trust shift, no signature trust from KeyInfo, no SHA-1 default, no parser differential, replay required in prod." v0.2 extended that posture to "no implicit trust shift on metadata fetch, audit row co-committed with every mutation, runtime trust hydrates only `:active` certs." Each new strict default in v0.2 was a direct extension of a v0.1 invariant — the strict-by-default stance compounds.
2. **Behaviour-backed seams beat ad-hoc integration.** v0.1 established behaviour-backed `RequestStore` / `ReplayStore` / `SessionAdapter` / `UserMapper`. v0.2 extended that pattern to `ConnectionResolver` (with `Default` and `Ecto` adapters) — the host app picks its persistence story without forking. Behaviours are still the canonical extension point.
