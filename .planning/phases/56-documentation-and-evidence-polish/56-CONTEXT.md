# Phase 56: Documentation And Evidence Polish - Context

**Gathered:** 2026-06-13 (assumptions mode + per-area deep research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Docs-only, final phase of the v1.7 Adoption Evidence Demo milestone. Make the runnable
`demo/ledger_loop` Phoenix app useful as evaluator evidence and adopter onboarding —
without replacing the normal Hex installation path. Requirements: DOCS-01, DOCS-02, DOCS-03,
plus Success Criterion 4 (scope honesty).

**In scope:** rewriting the demo app README, adding a thin hexdocs pointer, wiring demo links
into the existing README/getting_started router, framing evidence/scope honesty, explaining the
host-app boundary, and one tightly-scoped doc-drift gate.

**Out of scope:** any new protocol surface, production IdP behavior, hosted-broker behavior,
security relaxation, or new demo app features. This phase only documents what already exists.
</domain>

<decisions>
## Implementation Decisions

### Demo Guide Placement & Authority
- **D-01:** The authoritative, full demo guide is a **complete rewrite of `demo/ledger_loop/README.md`**
  (currently still the 18-line `mix phx.new` scaffold), co-located with the runnable app it documents.
- **D-02:** Add a **thin `guides/demo.md`** to ExDoc `extras` + a `groups_for_extras` group. Its only
  job: tell the hexdocs reader the demo exists, that it is **repo-only / not part of the Hex package**,
  and bounce them to the demo README. It does NOT duplicate boot/reset/creds/routes detail.
- **D-02b:** All links from `guides/demo.md` into the demo MUST be **absolute GitHub URLs pinned to
  `main`** (`https://github.com/szTheory/relyra/blob/main/demo/ledger_loop/README.md`), never relative
  `../demo/...` paths. Rationale: `mix.exs` `package.files` ships `guides/` to hexdocs but excludes
  `demo/`; a relative link into `demo/` passes the on-disk `markdown_link_smoke_test.exs` but 404s on
  hexdocs (silent divergence footgun). `main` (not a version tag) is correct for a demo that evolves.
- **D-02c (recommended hardening, planner discretion):** Extend `test/docs/markdown_link_smoke_test.exs`
  to FAIL any relative link from a published extra that resolves outside `package.files` (i.e. into
  `demo/`). Converts the silent disk-passes/hexdocs-breaks gap into a CI failure. Low effort, consistent
  with the repo's gate-it-in-CI culture. Optional but advised.

### Linking Strategy (preserve the Hex install path — DOCS-01 / SC1)
- **D-03:** Root `README.md` keeps the `{:relyra, "~> 1.5"}` install snippet and the "Start Here"
  router **exactly where they are (top, untouched)**. The demo appears only as a **secondary
  "see it running" reference placed below "Start Here"** (or in the existing "Day-2 And Operator
  Guides" block), linking to `guides/demo.md` (relative, shipped) — NEVER directly into `demo/`.
- **D-04:** `guides/getting_started.md` adds the demo only to its **§5 production follow-on references**,
  NOT into the numbered install→proof→provider spine. The canonical Day-1 path must not be displaced.
- **D-05:** Label discipline everywhere: always **"runnable reference app, not part of the Hex package."**
  Never "quickstart," "starter," or "scaffold" — those words pull readers away from `mix relyra.install`,
  which is the real scaffold path. Frame cloning the demo as the *evaluation* path, not the *adoption* path.

### Demo README Content & Structure (DOCS-02 / DOCS-03)
- **D-06:** The rewritten README follows an **evaluator-first 11-section outline** (the 10-minute
  auth/security reviewer = JTBD persona #4):
  1. One-paragraph "what this is" (LedgerLoop = fictional Phoenix B2B SaaS embedding Relyra)
  2. At-a-glance scope strip (demonstrates / does not — pointer to scope section)
  3. Quick start — dual option: **Option A Docker (recommended)** `scripts/demo doctor → up → urls`;
     **Option B Local Mix** `mix setup → mix phx.server`
  4. "What you'll see" — the receipt section (login → verified assertion → typed rejection scenario → audit row)
  5. Seeded data — credentials table + the no-password/identity-keyed caption + four connection scenarios
  6. Key routes table — grouped by owner (LedgerLoop vs Relyra) + health probes
  7. Reset & test (`scripts/demo reset` / `scripts/demo test`, plus `mix ecto.reset`)
  8. Optional Keycloak profile (`--profile keycloak`, `localhost:8080`, why optional)
  9. "Who owns what" host-boundary table (see D-09)
  10. Scope & honesty / evidence note (see D-08)
  11. Where to go next — link UP to the library (hexdocs, Getting Started, runbooks)
- **D-07:** Document the **exact verified surface** (cite from source, do not paraphrase):
  - Subcommands: `doctor | up | reset | test | urls | down` (`scripts/demo`)
  - URLs/ports: `localhost:4000` (app), `localhost:8080` (Keycloak); Compose profiles `core` (default),
    opt-in `keycloak` / `browser`; env overrides `PORT` / `PGPORT` / `KC_PORT` (`docker-compose.yml`)
  - In-repo Mix path: `mix setup` (already chains `priv/repo/seeds.exs`) / `mix ecto.reset`
  - Seeded story: Northstar Health tenant (slug `northstar`), users `sarah@northstar.example.com` (admin)
    + `chen@northstar.example.com` (clinical), four connection scenarios
    (Enabled / Draft / Staged Rollover / Support Failure) — all from `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex`
  - Routes (verified from `router.ex`): `/`, `/setup/sso`, `/login/test`, `/login/admin`,
    `/support/scenario`, `/relyra/admin`, `/saml/*`, `/healthz`, `/readyz`, plus the local FakeIdP routes

### Evidence Framing — "adoption proof only" (Success Criterion 4)
- **D-08:** Place the scope note in **BOTH places, asymmetric**:
  - **Top:** a one-sentence, positively-framed blockquote callout ("this is adoption evidence, not the
    library, not new capability, not production hardening, not a hosted service").
  - **Bottom:** a fuller "Scope & honesty" two-list section mirroring the root README's
    **"What Does Not Ship"** voice (`README.md:103-109`) — a brand asset, not an apology. Hit all four
    ROADMAP items explicitly: no protocol expansion, no production IdP behavior, no hosted-broker behavior,
    no security relaxation. Tie the security point to the strict-defaults invariant ("the same strict
    defaults gate this demo; the FakeIdP signs with a real key and Relyra verifies it — nothing weakens
    validation").
  - Echo ONE sentence of this in `guides/demo.md`.
  - Voice: positive "what this evidence proves" framing, never defensive "what this isn't."

### Host-App Boundary (DOCS-03)
- **D-09:** Explain the boundary as a **two-column "Who owns what" table** (Concern | Owner | Where you
  see it in this demo), placed after the evidence section and before the final scope note. Use the
  canonical JTBD sentence verbatim as caption: *"Relyra gets you to 'this assertion is valid for this
  connection.' LedgerLoop gets you to 'this person may now do these things in our product.'"* Rows cover:
  parse/verify signature → Relyra; audience/recipient/replay/typed-rejection → Relyra; tenant identity &
  provisioning → LedgerLoop; principal→local-user mapping → LedgerLoop; session establishment → LedgerLoop;
  downstream authorization → LedgerLoop.

### Doc-Drift Test (tightly scoped)
- **D-10:** ADD a drift gate scoped to the **`scripts/demo` subcommand set ONLY**. Skip routes and seeded
  creds — they appear as prose ("log in as Dr. Sarah"), not verbatim contracts, so asserting them invites
  brittleness on a low-stakes, out-of-package, end-of-milestone guide. The subcommand list is the unique
  surface that is a closed enumerable set, the literal thing evaluators copy-paste, and the most likely to
  be renamed without a guide update (freshly added in Phase 55).
  - File: `test/docs/demo_guide_drift_test.exs`, modeled on `troubleshooting_drift_test.exs` (bidirectional
    set-difference) with `logout_recipe_drift_test.exs`'s fenced-code-block scoping.
  - Runtime-extract the subcommand set from `scripts/demo` `case "$COMMAND"` arms at test time — NEVER
    hardcode the list (project convention D-05). Scan only ```bash fenced blocks in the README for
    `scripts/demo <token>` mentions (anti-brittleness: ignore prose).
  - Bidirectional: every subcommand in the script appears in the README (missing-in-doc) AND every
    documented `scripts/demo <token>` exists in the script (stale-in-doc). Handle `{:error, :enoent}`
    as an empty doc set.
- **D-11:** Lane = **`ci.docs`** (NOT `ci.demo_app`), as its own dedicated
  `cmd mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` line, placed right after the
  `logout_recipe_drift_test.exs` line, with a `cmd test -f demo/ledger_loop/README.md` presence guard
  ahead of it. **This is forced, not stylistic:** `ci.demo_app` runs every step with
  `--cd demo/ledger_loop`, so a test there cannot read the repo-root `scripts/demo`; `ci.docs` runs at
  repo root where all files are reachable, and the dedicated `cmd mix test` form satisfies the Phase 30
  hollow-gate invariant (each suite its own process). The README at `demo/ledger_loop/README.md` is
  readable from root cwd, so D-01's placement is compatible.

### Content-Accuracy Constraint (must reconcile before writing the walkthrough)
- **D-12:** The bundled FakeIdP currently signs **`evaluator@example.com`**
  (`demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex:17,28`), while the seeded
  users and SAML identities are `sarah@` / `chen@northstar.example.com` (`fixtures.ex`). The "What you'll
  see" walkthrough MUST match the actual default login outcome. The planner/executor must verify the real
  landing user before writing §4 — either frame it as "you land as the evaluator user," or reconcile the
  FakeIdP subject to a seeded identity. **Do NOT claim "you land as Dr. Sarah" unless verified true.**

### Claude's Discretion
- Exact heading wording / microcopy (research provided ready-to-use brand-voice lines in DISCUSSION-LOG;
  treat as strong defaults, refine to fit).
- Whether to include the optional prose flow diagram above the boundary table.
- Whether to implement the D-02c link-smoke hardening this phase or defer (small, advised, not required).
- Restrained badge row on the demo README (link back to relyra hex/docs; `ci.demo_app` status only if meaningful).

### Folded Todos
None — `todo.match-phase` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 56 goal + Success Criteria (1-4)
- `.planning/REQUIREMENTS.md` — DOCS-01, DOCS-02, DOCS-03
- `.planning/phases/55-docker-ci-and-optional-keycloak-proof/55-CONTEXT.md` — Compose/CLI/CI decisions this phase documents
- `prompts/relyra-brand-book.md` — voice, microcopy, scope-honesty framing (load-bearing for README rewrite)
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — example-app doc conventions
- Source to document (cite, don't paraphrase): `scripts/demo`, `docker-compose.yml`,
  `demo/ledger_loop/lib/ledger_loop_web/router.ex`, `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex`,
  `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex`, `demo/ledger_loop/mix.exs`
- Drift-test templates: `test/docs/troubleshooting_drift_test.exs`, `test/docs/logout_recipe_drift_test.exs`,
  `test/docs/markdown_link_smoke_test.exs`
- Wiring points: `mix.exs` (`ci.docs` alias, `docs.extras` / `groups_for_extras`, `package.files`),
  `README.md`, `guides/getting_started.md`, `guides/jtbd_user_flows.md` (evaluator persona #4)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/demo` — Bash CLI (`doctor|up|reset|test|urls|down`); the `urls` subcommand already prints
  canonical URLs/ports (good source for the README's URL table).
- `docker-compose.yml` (repo root) — profiles `core`/`keycloak`/`browser`; env overrides.
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` + `LedgerLoop.Demo.Reset.reset!()` — deterministic seed
  (Northstar tenant, two users, four connection scenarios).
- `test/docs/troubleshooting_drift_test.exs` + `logout_recipe_drift_test.exs` — exact templates for the new
  drift test (bidirectional set-diff + fenced-block scoping + runtime introspection, no hardcoded literals).
- Root `README.md` "What Does Not Ship" section — the proven scope-honesty voice to mirror.

### Established Patterns (constrain this phase)
- **Doc-drift convention (D-05):** drift tests read values from source at runtime, never hardcode.
- **Hollow-gate invariant (Phase 30):** each suite is its own `cmd mix test` process in the CI alias.
- **`package.files` ships `guides/` but excludes `demo/`** — drives the absolute-URL rule (D-02b).
- **`markdown_link_smoke_test.exs`** globs all `guides/**/*.md`; resolves relative links against repo root
  on disk — passes for `demo/` paths on disk but they break on hexdocs (the silent footgun → D-02b/D-02c).
- ExDoc only documents the `:relyra` app; it will not render `demo/ledger_loop` modules/README — correct
  and desired; the demo is a destination you link to, not inlined content.

### Integration Points
- `mix.exs`: add `guides/demo.md` to `docs.extras` + `groups_for_extras`; add the drift-test `cmd mix test`
  line (and a `test -f` presence guard) to the `ci.docs` alias; consider a `test -f guides/demo.md` parity
  gate consistent with existing `ci.docs` `-f` checks.
- `README.md` + `guides/getting_started.md`: secondary demo references only (D-03/D-04/D-05).
- `demo/ledger_loop/README.md`: full rewrite (D-06/D-07).
</code_context>

<specifics>
## Specific Ideas

Research produced ready-to-use brand-voice microcopy (title one-liner, top scope callout, dual-quickstart
intro, "what you'll see" receipt paragraph, no-password credentials caption, reset/test copy, optional
Keycloak intro, "where to go next" handoff) and the recommended 11-section outline + boundary table — all
captured in `56-DISCUSSION-LOG.md`. Treat these as strong defaults for the writer.

Real-world demo READMEs that informed the structure: Stripe Samples (at-a-glance + support matrix + dual
quickstart), gothinkster Phoenix RealWorld (blunt expectation-setting sentence), Auth0 SDK quickstarts
(credentials → callback → run ordering), Supabase examples ("what you'll build"), Cal.com/cal.diy
(top blockquote scope callout).
</specifics>

<deferred>
## Deferred Ideas

- PORTAL-01, SCREENSHOT-01 — future requirements, out of v1.7 scope.
- Reconciling the FakeIdP subject to a seeded identity (vs documenting "evaluator user") is a content
  decision for this phase per D-12, but any *behavior* change to the demo login flow beyond what's needed
  for accurate docs would be its own phase, not a docs task.

### Reviewed Todos (not folded)
None — `todo.match-phase` returned 0 matches.
</deferred>
