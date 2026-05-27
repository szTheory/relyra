# Phase 46: Adopter DX & ergonomics - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Polish adopter-facing surfaces so a new user sees what Relyra looks like in ~30 seconds, gets `saml_routes()` wired by the installer when safe, and navigates docs by job rather than footer-chasing. No new protocol features, release versioning, or trace UI — README snippet, installer router injection, `guides/overview.md`, and `BATTERIES_INCLUDED` dedupe only (DX-01, DX-02, DX-03).
</domain>

<decisions>
## Implementation Decisions

### README above-the-fold snippet (DX-01)
- **D-01:** Insert a runnable `Relyra.Provider.apply_defaults(:okta, [...])` code block immediately after the opening tagline (lines 1–4), **before** the current "## Start Here" Day-1 router walkthrough — oban/bandit landing-page tradition.
- **D-02:** Snippet shape follows `guides/recipes/okta.md:57-63`: four user-supplied keys (`sp_entity_id`, `acs_url`, `idp_sso_url`, `idp_certificates`) with placeholder values; presets fill safe defaults underneath via `apply_defaults/2`.
- **D-03:** Preserve Phase 41 D-09 provider-count framing already in README ("4 first-class presets + generic SAML runbook covering 7 IdP families"); do not reintroduce "8 presets" copy drift.

### Router auto-injection (DX-02)
- **D-04:** When `--router` is omitted, auto-detect a single `lib/**/*router.ex` containing `use Phoenix.Router`. When exactly one match: inject `import Relyra.Phoenix.Router` (if missing) + `saml_routes()` at module level after the `use` block, wrapped in a `# --- Relyra SAML routes ---` marker for idempotency (sigra injector pattern).
- **D-05:** When `--router` is passed explicitly: attempt injection only if the file has a clear anchor; same marker/idempotency rules apply.
- **D-06:** Ambiguous cases — multiple routers, no detectable anchor, or `saml_routes()` already present — fall back to the existing print-instructions behaviour with **no file modification** (current contract at `relyra.install.ex:105-114`).
- **D-07:** Injection target shape matches `test/phoenix/router_test.exs`: `import Relyra.Phoenix.Router` at module level, `saml_routes()` as a top-level macro call (the macro defines its own inner scope).

### Doc navigation — `guides/overview.md` (DX-03)
- **D-08:** Create `guides/overview.md` as a job-shaped index with **Day-1 / Day-2 / Reference** sections linking to existing guides (`getting_started.md`, provider runbooks, identity mapping, troubleshooting, security docs).
- **D-09:** Wire `guides/overview.md` into `mix.exs` `docs/0` extras near the top; keep `main: "getting_started"` so the onboarding narrative remains the ExDoc landing page.
- **D-10:** Link from README "## Start Here" to `guides/overview.md` as the navigation hub; migrate the hand-written "proof journey" narrative from `guides/batteries_included.md` into overview's Day-1 section.

### BATTERIES_INCLUDED dedupe (DX-03)
- **D-11:** Root `BATTERIES_INCLUDED.md` stays the **primary** drift-tested artifact (`mix relyra.batteries_included --check` + `ci.docs` gate).
- **D-12:** Convert `guides/batteries_included.md` to a short stub linking to root `BATTERIES_INCLUDED.md`; eliminate duplicate narrative content.
- **D-13:** Update `lib/mix/tasks/relyra.batteries_included.ex` generator: artifact columns reference root doc (not `guides/batteries_included.md`); supported-provider scope includes ADFS (generator currently lists only 3 presets — stale vs README's 4).
- **D-14:** Document the canonical/stub choice in the phase SUMMARY per ROADMAP SC#4 so reviewers know root is authoritative.

### Test and CI gates
- **D-15:** Extend `test/mix/relyra_install_test.exs` with fixture routers: (1) unambiguous single-router → injection succeeds + idempotent re-run; (2) ambiguous multi-router → file byte-unchanged + instruction printed.
- **D-16:** Add `guides/overview.md` presence check to `mix ci.docs` alias.

### Claude's Discretion
- Exact anchor-detection heuristic for router injection (e.g. after `use ...Router` vs before last `end`) — sigra's `find_last_end/1` is the reference pattern.
- Whether overview gets a second link from ExDoc sidebar grouping vs flat extras list ordering.
- Exact stub length for `guides/batteries_included.md` (minimal redirect vs brief summary + link).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 46 goal, success criteria, DX-01/02/03 requirements.
- `.planning/REQUIREMENTS.md` — DX-01, DX-02, DX-03 definitions and v1.5 milestone goal.
- `.planning/STATE.md` — Phase 41 D-09 provider framing; Phase 42/46 separation rationale.
- `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md` — Original wedge-3 DX assessment (oban/bandit README pattern, installer injection, overview index, batteries dedupe).

### Prior Phase Context
- `.planning/phases/41-pre-publish-hygiene-tech-debt-sweep-security-hardening/41-CONTEXT.md` — D-09 provider-count truth Phase 46 inherits.
- `.planning/phases/43-hex-publish-prep-version-bump-changelog-backfill/43-CONTEXT.md` — getting_started pin deferred README DX to Phase 46.
- `.planning/phases/45-post-publish-parity-verification/45-CONTEXT.md` — README/installer explicitly out of scope for parity phase.

### Implementation Touchpoints
- `README.md` — DX-01 above-the-fold snippet insertion point.
- `lib/mix/tasks/relyra.install.ex` — DX-02 router auto-injection target.
- `lib/relyra/phoenix/router.ex` — `saml_routes/0` macro contract.
- `lib/relyra/provider.ex` — `apply_defaults/2` API for README snippet.
- `guides/recipes/okta.md` — Canonical snippet shape for DX-01.
- `guides/getting_started.md` — Day-1 onboarding narrative; stays ExDoc main.
- `mix.exs` — `docs/0` extras list and `ci.docs` alias.
- `BATTERIES_INCLUDED.md` — Primary drift-tested batteries proof artifact.
- `guides/batteries_included.md` — Becomes stub per D-12.
- `lib/mix/tasks/relyra.batteries_included.ex` — Generator to update per D-13.
- `test/mix/relyra_install_test.exs` — Install test extension target per D-15.

### Sibling-Lib Pattern (DNA source)
- `/Users/jon/projects/sigra/lib/sigra/install/injector.ex` — Marker + anchor injection idempotency pattern.
- `/Users/jon/projects/sigra/test/support/install_fixture.ex` — Golden-diff installer test discipline (reference; Relyra may use lighter fixture-router approach).
- `prompts/relyra-engineering-dna-from-prior-libs.md` — Sigra installer golden-diff and guides-split conventions.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.Provider.apply_defaults/2` — documented public API; README snippet should call this directly (`lib/relyra/provider.ex:119-127`).
- `Relyra.Phoenix.Router.saml_routes/0` — self-contained macro defining scope + routes; injection is import + macro call only (`lib/relyra/phoenix/router.ex`).
- `Mix.Tasks.Relyra.Install` — already scaffolds connections/user_mapper/config with sentinel markers; router path is the missing auto-inject seam (`lib/mix/tasks/relyra.install.ex`).
- `Mix.Tasks.Relyra.BatteriesIncluded` — generates drift-checked root artifact; update rather than replace (`lib/mix/tasks/relyra.batteries_included.ex`).
- `test/phoenix/router_test.exs` — canonical `saml_routes()` usage shape for injection tests.

### Established Patterns
- Installer uses `# --- Relyra START/END ---` sentinels in config for idempotent injection — router should follow same marker discipline.
- `mix ci.docs` gates doc file presence + drift tests; new overview and batteries stub changes must stay green.
- Provider-count copy is locked to Phase 41 framing; generator and README must agree on 4 first-class presets + generic runbook.
- Phase 42 trace LiveView is intentionally separate from DX polish — do not fold trace work into this phase.

### Integration Points
- README → overview.md → getting_started.md navigation chain for Day-1 adopters.
- `mix relyra.install` → host router + generated seams (connections, user_mapper, config).
- ExDoc extras list → hexdocs navigation for published package.
- `mix relyra.batteries_included --check` → root BATTERIES_INCLUDED.md drift gate in CI.
</code_context>

<specifics>
## Specific Ideas

- "Oban/bandit landing-page tradition" = code snippet above the fold, narrative walkthrough below — not a marketing paragraph.
- Sigra injector uses marker comments + anchor resolution; Relyra install should adopt the same idempotency model without building a full feature-walker architecture.
- Generator currently omits ADFS from supported-provider scope despite README and `Provider.list/0` including it — fix as part of batteries dedupe, not a separate phase.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within Phase 46 scope.
</deferred>

---

*Phase: 46-adopter-dx-ergonomics*
*Context gathered: 2026-05-27*
