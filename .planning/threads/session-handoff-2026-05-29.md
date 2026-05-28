# Session handoff — 2026-05-29

**Purpose:** Cold-start context after maintenance + doc audit session. Read this, then `.planning/STATE.md`.

## Current posture

| Item | Value |
|------|-------|
| Milestone | v1.6 complete — **between milestones, pause default** |
| Hex | **1.5.4** live; adopters use `{:relyra, "~> 1.5"}` |
| Done-enough | ~93% per [v1-7 assessment](v1-7-milestone-assessment-2026-05-28.md) |
| Next phase # when work resumes | **50** (continue numbering; do not reset) |
| Open PRs | None |

## What shipped this session arc (2026-05-28 → 2026-05-29)

### Release / CI (#13–#25)

- **1.5.2:** Logout replay test flake fix (isolated replay store + FakeIdP warmup)
- **1.5.3:** Hands-off release proof — doc trigger only ([#17](https://github.com/szTheory/relyra/pull/17) → bot PR → automerge)
- **CI fixes #19–#22:** `actions: write` for dispatch; check-name parsing; `gh pr checks` exit tolerance; automerge dispatches Release Please after merge; `cancel-in-progress: false` on `release-please-main`
- **1.5.4:** Validates full publish chain without manual `workflow_dispatch`

**Trusted automation path:**

```
change on main → Release Please opens bot PR
→ release-please-pr-checks (dispatch security-gates + PAT nudge if needed)
→ automerge merges bot PR
→ automerge dispatches release-please.yml on main
→ Publish to Hex.pm (mix qa + ci.security + idempotent skip)
```

Key workflows: `.github/workflows/release-please.yml`, `release-please-pr-checks.yml`, `release-please-automerge.yml`.

Proof thread: [hands-off-release-proof-2026-05-29.md](hands-off-release-proof-2026-05-29.md).

### Docs ([#25](https://github.com/szTheory/relyra/pull/25))

Reader experience audit — [doc-reader-audit-2026-05-29.md](doc-reader-audit-2026-05-29.md):

- Fixed broken Hex link to `guides/batteries_included.md` (retarget `BATTERIES_INCLUDED.md`)
- Troubleshooting: trace vs `mix relyra.diagnostic` no longer conflated
- Overview Day-1/Day-2 taxonomy; Getting Started §5 links overview + logout
- ExDoc: `production_ecto_path` under **Operations** group
- New tests: `test/docs/adopter_voice_test.exs`, extended `markdown_link_smoke_test.exs`
- GitHub homepage: https://hexdocs.pm/relyra

## Default next move

**Pause / react.** Do not open v1.7 feature milestone or Phase 50 without trigger.

Work only when forced by:

- GitHub issue or adopter request
- Hex/CVE maintenance (GHSA-jv46-xfwm-36j7 `cve_id` still null — weekly `cve-advisory-check` only)
- Demand-gated protocol: **AUTHN-POST-01**, **KMS-01**, **SIGNED-META-01**

## Optional backlog (not urgent)

| ID | Item | Notes |
|----|------|-------|
| D-12 | README Elixir version + CI/license badges | Done in #26 |
| D-13 | Provider runbook wiring bridge | Okta runbook §Wire the host app in #26 |
| — | Hexdocs home = README vs Getting Started | Evaluator persona; deferred |
| — | `guides/batteries_included.md` stub | Still in repo for ci.docs presence; not on Hex extras |

## Doc guardrails (do not weaken)

- `mix ci.docs` — hollow-gate: each suite is its own `cmd mix test` process
- `adopter_voice_test` — blocks planning voice in `guides/**` + README (content inside `<details>` skipped)
- `docs/jtbd_gap_map.md` — maintainers only; must stay **out** of `mix.exs` ExDoc extras
- `.planning/**` changes skip `security-gates` — merge via bypass or bundle with `guides/` change

## Non-negotiables (unchanged)

See `CLAUDE.md`: signature source, one parse path, pre-parse guards, crypto required, audit co-commit, replay in prod.

Escalate before: public API shape changes, default-tightening, security posture changes, SemVer major.

## Key file index

| Topic | Path |
|-------|------|
| Position | `.planning/STATE.md` |
| Assessment / pause verdict | `.planning/threads/v1-7-milestone-assessment-2026-05-28.md` |
| Release proof | `.planning/threads/hands-off-release-proof-2026-05-29.md` |
| Doc audit | `.planning/threads/doc-reader-audit-2026-05-29.md` |
| Adopter entry | `README.md`, `guides/getting_started.md`, `guides/overview.md` |
| ExDoc config | `mix.exs` `defp docs/0` |
| Maintainers JTBD map | `docs/jtbd_gap_map.md` (not on Hex) |
