# Doc reader experience audit — 2026-05-29

**Scope:** Informal pass; adopter-facing corpus per `mix.exs` ExDoc extras + `guides/**`.  
**Baseline:** `mix ci.docs` green; Hex **1.5.4** shipped (#23 automerge + publish dispatch validated).

## Persona summary

| Persona | Verdict | Top friction |
|---------|---------|--------------|
| Evaluator | Good on GitHub README; weak on hexdocs landing | `batteries_included.md` not in Hex extras; no homepage URL on GitHub |
| Integrator Day-1 | Strong spine; some maintainer noise | release-please line; §3 backtick render; runbook path gaps (P0 bridge out of scope) |
| Operator Day-2 | Hub exists in overview | Troubleshooting conflates diagnostic vs trace (P0); trace absent from troubleshooting intro |
| Security reviewer | Strong SECURITY → CONFORMANCE chain | `mix ci.*` in generated docs OK for audience |
| JTBD navigator | Scenes align with Getting Started | Footer links `batteries_included.md` (broken on Hex) |

## Findings matrix

| ID | Pri | Issue | Fix in PR |
|----|-----|-------|-----------|
| D-01 | P0 | `overview.md` / `jtbd_user_flows.md` link `guides/batteries_included.md` — not in Hex extras | Retarget to `BATTERIES_INCLUDED.md` |
| D-02 | P0 | Troubleshooting “When in doubt” equates diagnostic bundle with login trace | Reword; point to playbook `#evidence-surfaces` |
| D-03 | P1 | GitHub `homepageUrl` empty | `gh repo edit --homepage https://hexdocs.pm/relyra` |
| D-04 | P1 | Getting Started L19–20 release-please maintainer note | Remove |
| D-05 | P1 | Getting Started §3 broken inline backticks across lines | Single-line / fenced code |
| D-06 | P1 | Overview Day-2 lists provider runbooks (Day-1 step) | Move runbooks to Day-1 section |
| D-07 | P1 | Getting Started §5 missing overview hub + logout | Add links |
| D-08 | P1 | Troubleshooting intro omits login trace | Add one sentence + playbook link |
| D-09 | P1 | Link smoke test skips Hex-only extras | Extend `markdown_link_smoke_test.exs` |
| D-10 | P1 | No guard against planning voice in guides | Add `adopter_voice_test.exs` |
| D-11 | P1 | `production_ecto_path` in ExDoc “Day-1” group | Move to Operations group |
| D-12 | P2 | README missing Elixir version / CI badges | Deferred (subjective) |
| D-13 | P2 | Okta runbook missing login wiring steps | Deferred (large scope) |
| D-14 | P2 | Overview Reference duplicate playbook link | Remove duplicate |
| D-15 | P2 | `#24` planning close-out blocked on branch protection | Included in this PR |

## Fixed / wontfix (post-PR)

| ID | Status |
|----|--------|
| D-01 … D-11 | Fixed in `docs/reader-experience-audit` PR |
| D-12 | wontfix this pass |
| D-13 | wontfix — needs runbook bridge design, not copy edit |
| D-14 | Fixed |
| D-15 | Fixed via PR merge |

## Verification

- `mix ci.docs`
- `mix docs` (local HTML)
- `gh repo view` homepage set
