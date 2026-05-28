# Doc reader experience audit — 2026-05-29

**Scope:** Informal pass; adopter-facing corpus per `mix.exs` ExDoc extras + `guides/**`.  
**Baseline:** `mix ci.docs` green; Hex **1.5.4** shipped (#23 automerge + publish dispatch validated).

## Persona summary

| Persona | Verdict | Top friction |
|---------|---------|--------------|
| Evaluator | Good on GitHub README; hexdocs landing improved | Getting Started now opens with library pitch + doc routing |
| Integrator Day-1 | Strong spine | Runbook wiring bridges in all five Day-1 runbooks |
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
| D-12 | P2 | README missing Elixir version / CI badges | Fixed in #26 |
| D-13 | P2 | Runbooks missing login wiring steps | Fixed micro-polish pass — all five runbooks |
| D-16 | P2 | Hexdocs landing weak for evaluators | Fixed — Getting Started intro + README cross-ref |
| D-14 | P2 | Overview Reference duplicate playbook link | Remove duplicate |
| D-15 | P2 | `#24` planning close-out blocked on branch protection | Included in this PR |

## Fixed / wontfix (post-PR)

| ID | Status |
|----|--------|
| D-01 … D-11 | Fixed in `docs/reader-experience-audit` PR (#25) |
| D-12 | Fixed in #26 (README badges) |
| D-13 | Fixed — Okta in #26; Entra/Google/ADFS/generic in micro-polish pass |
| D-16 | Fixed — Getting Started evaluator landing blurb |
| D-14 | Fixed |
| D-15 | Fixed via PR merge |

## Post-audit polish (2026-05-29)

Micro doc pass closed remaining P2 backlog:

- **Runbook wiring bridges:** `Wire the host app` in entra, google_workspace, adfs, generic_saml (Okta already in #26)
- **Hexdocs landing:** evaluator intro at top of `guides/getting_started.md`; README clarifies hexdocs home vs GitHub router
- **Planning sync:** v1.6 audit addendum, STATE, session-handoff updated

## Verification

- `mix ci.docs`
- `mix docs` (local HTML)
- `gh repo view` homepage set
