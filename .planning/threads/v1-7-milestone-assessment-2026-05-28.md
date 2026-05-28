# Investigation: Post-v1.6 Milestone Assessment — "Done enough? What's next?"

Status: COMPLETE — assessment 2026-05-28, post v1.6 ship; routing verdict recorded
Re-validated: 2026-05-28 — spot-check (mix.exs 1.5.0, Hex 1.5.0 live, conformance 9 pass / 0 deferred); verdict unchanged
Priority: HIGH (milestone routing decision)
Depends: v1.6 shipped (Phases 47-49.2, Adoption Truth doc-only)

## Trigger

Adopter-first milestone-next assessment at v1.6 close. v1.6 closed the Adoption Truth doc wedge (TestSupport-first Getting Started, production Ecto path, login trace in incident playbook, CONFORMANCE honesty, jtbd_gap_map refresh, preset taxonomy). The question is whether any **important** wedge remains before additional work hits diminishing returns.

## Method

Repo-local inspection: `lib/`, `test/`, `priv/conformance/sp_manifest.json`, key guides, `.planning/` threads. Parallel subagent passes on docs, shipped capabilities, and planning state. No GitHub issue queue inspected (medium confidence on "what adopters will ask next").

## Done-% verdict

**~93% (band: 90–95% near-done / diminishing returns soon)**

| Rubric | Score | Notes |
|--------|-------|-------|
| Core JTBD coverage | 95% | SP/IdP-init, ENC, redirect-signed AuthnRequest, SLO API, presets — verified in `lib/relyra.ex`, `validation_pipeline.ex` |
| Breadth vs category | 90% | 4 presets + generic runbook; security posture exceeds Elixir peers |
| Docs / onboarding | 92% | v1.6 Adoption Truth criteria MET per `docs/jtbd_gap_map.md`; residual `guides/jtbd_user_flows.md` Scene 3 omits ADFS |
| Operator / diagnostic | 93% | Trace LiveView + `mix relyra.trace` in playbook; 8× `mix relyra.*` |
| Proof / CI honesty | 96% | Permanent adversarial corpus; CONFORMANCE 9 pass / 0 deferred; scope boundary in generator |

## Recommended default: Pause (no new feature milestone)

**Rational next move:** Stay between-milestones until external demand signal (GitHub issue, adopter request) or Hex/security maintenance forces a patch release.

Do **not** run `/gsd-new-milestone` for v1.7 feature work without a trigger. Protocol candidates remain save-for-demand; building AUTHN-POST / KMS / SIGNED-META without signal = coverage-gating (rejected at v1.x done-enough line).

## Single pick

**Pause / react** — highest leverage now.

## Ranked wedges (when triggered)

| Rank | Wedge | When | Estimate |
|------|-------|------|----------|
| 0 | Pause / maintenance | Now | — |
| 1 | AUTHN-POST-01 | IdP rejects redirect-signed AuthnRequests | ~1 week |
| 2 | KMS-01 | Enterprise SP key custody requirement | ~1–1.5 weeks |
| 3 | SIGNED-META-01 | InCommon / academic federation | ~1.5–2 weeks |
| 4 | Micro doc polish | Optional annoyance fix only | hours |
| 5 | Preset / case study | Named adopter | varies |

Phase numbering when next milestone starts: continue from **Phase 50** (do not reset).

## Optional alternative (momentum only)

**v1.7 Reader Experience** — doc-only pass executed 2026-05-28 in-repo: public voice (CHANGELOG, CONFORMANCE generator, `jtbd_gap_map` off Hex extras), four-preset coherence, README/operator routing, recipe footers, grouped Hex extras, `markdown_link_smoke_test` in `ci.docs`. **No protocol.** Run `/gsd-new-milestone` only if you want formal phased tracking in ROADMAP/STATE.

## Demand-gated candidates (unchanged verdict: save-for-demand)

| ID | Verdict | Trigger | Investigation |
|----|---------|---------|---------------|
| AUTHN-POST-01 | Save-for-demand | IdP rejects redirect-signed AuthnRequests | `signed-authn-requests-investigation.md` |
| KMS-01 | Save-for-demand | Enterprise blocked on SP key custody | `encrypted-assertions-investigation.md` |
| SIGNED-META-01 | Save-for-demand | InCommon / academic federation | `signed-sp-metadata-investigation.md` |

## Residual doc drift (low severity)

| Issue | Evidence |
|-------|----------|
| Security reviewer "quick arch" | Still thin in gap map; SECURITY + conformance strong |

v1.6 closed all **important** adoption-truth gaps flagged in v1-6 assessment.

## Explicitly NOT recommended

- Second Adoption Truth milestone without new gap evidence
- Bundling AUTHN-POST + KMS + SIGNED-META without separate triggers
- More first-class presets, HTTP-Artifact/ECP, standalone demo app, customer-admin portal

## Graduation candidates

- Post-ship milestone assessment thread before `/gsd-new-milestone` when `milestone_pause_when_done_enough` is true
- `jtbd_user_flows` must track Getting Started preset taxonomy on doc milestones
- Adoption Truth pattern is one-time at done-enough; do not repeat without new gap evidence

## Cross-references

- `.planning/threads/v1-6-milestone-assessment-2026-05-27.md` — COMPLETE (v1.6 shipped per user choice)
- `.planning/RETROSPECTIVE.md` — Post-v1.6 assessment section
- `.planning/STATE.md` — post-assessment position
- `.planning/PROJECT.md` — Key Decisions row 2026-05-28

## Verdict

**Honest answer: nothing major is missing for the stated scope.** v1.6 closed the last important adoption-truth asymmetry. Pause is the rational default; watch the issue tracker; pull one protocol thread when a real trigger lands (AUTHN-POST most likely first).
