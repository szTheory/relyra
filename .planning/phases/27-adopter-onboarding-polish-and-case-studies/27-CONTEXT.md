# Phase 27: Adopter Onboarding Polish and Case Studies - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a frictionless Day-1 experience for Relyra adopters through refined onboarding documentation, verified provider-specific runbooks, real-world case studies, and a falsifiable proof that the library's "batteries included" promise holds for the shipped adoption surface.

This phase does not deliver a marketing site, a broad provider-catalog expansion beyond shipped presets, or product-style customer testimonials. It also does not claim first-class support for providers that do not yet have shipped preset modules plus verified runbooks.

</domain>

<decisions>
## Implementation Decisions

### Golden-path shape
- **D-01:** Phase 27 should define one canonical Day-1 spine: `README.md` routes adopters into a narrative `Getting Started` guide, the guide verifies local success with `Relyra.TestSupport.FakeIdP`, then branches to exactly one provider runbook before returning to a short productionization tail.
- **D-02:** `README.md`, `guides/getting_started.md`, and provider runbooks should stop behaving like peer entry points. The docs IA should make the canonical path obvious and ordered, not choice-heavy.
- **D-03:** The golden path should sequence complexity rather than hide it: install, scaffold, local proof, one real provider, then operator-owned production seams.
- **D-04:** Optional surfaces such as LiveAdmin should appear late in the flow and be framed as optional, not as mandatory onboarding steps.
- **D-05:** Every major step in the Day-1 path should end with an explicit verification checkpoint so adopters know what success looks like before moving on.

### Runbook coverage and support contract
- **D-06:** For Phase 27, only `Okta`, `Microsoft Entra ID`, and `Google Workspace` count as "batteries included" providers because those are the only shipped preset modules with existing guide surfaces.
- **D-07:** Everything outside those three providers should move under an explicit `custom SAML` / generic fallback surface that is non-preset, non-verified, and non-promised.
- **D-08:** "Batteries included" should have a strict meaning: shipped preset module, verified runbook, provider-label translations, known-footgun guidance, and an honest support stance. If any part is missing, the provider is not batteries included.
- **D-09:** Provider runbooks should be authoritative operator documents, not short recipes. Each should cover exact field vocabulary, values Relyra owns, values the IdP owns, proof of success, common failures, and day-2 operational notes.
- **D-10:** Top-level project positioning should align with the shipped support matrix. Do not imply first-class provider coverage beyond what the code and verified docs actually support.

### Case-study style
- **D-11:** Case studies should be repo-native, scenario-led adopter narratives rather than testimonials, giant demo apps, or product-marketing stories.
- **D-12:** Each case study should be closer to an operations guide plus recipe: named situation, exact config/wiring, `Relyra owns` vs `Host owns` boundary, day-2 operations, failure/recovery notes, and evidence surfaces.
- **D-13:** The case-study set should stay small and opinionated. Prefer a few high-value archetypes over a broad catalog of shallow examples.
- **D-14:** Sample apps or Livebook material may exist as secondary support, but they should not replace the repo-native case-study docs as the primary truth surface.

### Proof of "batteries included"
- **D-15:** The phase should include one canonical "Batteries Included Proof" journey as a first-class guide, not just scattered recipes or a feature checklist.
- **D-16:** The proof journey should be backed by one CI-kept host fixture app generated from the blessed install path so the claim is executable against a fresh host integration.
- **D-17:** Every "batteries included" claim should end in a receipt: a command, page, event, audit row, telemetry emission, or generated artifact that an adopter can observe directly.
- **D-18:** The proof journey should traverse the actual shipped seams in adopter order: install, Phoenix mount, `FakeIdP` sign-in, provider preset path, optional admin surface, metadata/certificate lifecycle, audit/telemetry, scheduled refresh, and diagnostic bundle.
- **D-19:** A checklist or feature matrix may supplement the proof journey, but it cannot be the primary proof artifact because it does not show that the pieces compose cleanly in a host app.

### Decision posture and GSD preference
- **D-20:** Downstream planning and execution for this phase should be recommendation-first and low-friction. Low- and medium-impact documentation, IA, and formatting choices should be resolved by agents without reopening user discussion.
- **D-21:** Escalate only decisions that materially change support claims, trust-boundary semantics, release-critical architecture, or milestone scope.
- **D-22:** The preference above should be treated as the default posture for future similar GSD workflows where the project already has strong architecture and product direction, unless a decision is unusually impactful.

### the agent's Discretion
- Exact naming and file layout of the Day-1 guide, provider runbooks, proof guide, and case-study pages, provided there is one obvious canonical onboarding spine.
- Exact wording of support taxonomy labels, provided the distinction between verified preset support and generic/custom fallback remains unmistakable.
- Exact number of case studies, provided the set stays small, coherent, and high-signal.
- Exact verification receipts and fixture-app structure, provided every claim remains falsifiable and CI-verifiable.

</decisions>

<specifics>
## Specific Ideas

- The right docs architecture is a single spine with controlled branches: `README -> Getting Started -> FakeIdP proof -> one provider runbook -> production tail`.
- The support taxonomy should be explicit and visible: `Batteries included`, `Custom/generic SAML`, and `Not yet shipped`.
- Provider docs should speak the operator's language using the same vendor terminology the preset layer already encodes, rather than abstract SAML-only terminology.
- Case studies should optimize for "how do I run this safely in my app?" rather than "who used this successfully?"
- The proof story should feel like a Phoenix/Ecto adoption guide with receipts, similar in spirit to strong generator-driven onboarding in Phoenix, Oban, and other mature Elixir libraries.
- The user's strong preference here is one-shot, deeply researched, coherent recommendations with autonomous defaulting for non-critical choices. Future GSD work should bias toward that posture unless the decision changes trust, scope, or release posture.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and milestone anchors
- `.planning/ROADMAP.md` — Phase 27 goal, success criteria, and v1.0 ordering.
- `.planning/milestones/v1.0-REQUIREMENTS.md` — `DOCS-01` requirement anchor.
- `.planning/PROJECT.md` — project posture, exact-claims discipline, brand voice, support claims, and Day-1 operability principles.
- `.planning/STATE.md` — current project state after Phase 26.
- `.planning/milestones/v1.0-CONTEXT.md` — milestone-level v1.0 precedent and intent.

### Locked prior decisions and precedents
- `.planning/phases/06-delivery-hardening-and-adoption-surface/06-01-SUMMARY.md` — original adoption-surface deliverables, provider presets, installer, and docs baseline.
- `.planning/phases/15-admin-shell-connection-lifecycle/15-CONTEXT.md` — explicit risk visibility, operator-friendly posture, preset-driven connection flow, and recommendation-first preference.
- `.planning/phases/23-diagnostic-bundles/23-CONTEXT.md` — operator-facing diagnostic/export posture relevant to day-2 docs and proof.
- `.planning/phases/26-security-audit-preparation-and-remediation/26-CONTEXT.md` — repo-native, exact-claims, executable-proof posture that Phase 27 should preserve for adopter docs.
- `.planning/RETROSPECTIVE.md` — prior lessons on documentation drift, scope discipline, and closure-quality patterns.

### Current adopter-facing docs
- `README.md` — current top-level adopter entry point and operations sections that need re-architecture into a cleaner spine.
- `guides/getting_started.md` — current onboarding guide baseline.
- `guides/recipes/okta.md` — current Okta guide baseline.
- `guides/recipes/entra.md` — current Entra guide baseline.
- `guides/recipes/google_workspace.md` — current Google Workspace guide baseline.
- `docs/security_boundary.md` — trust-boundary language and library-owned seam definitions that docs must respect.
- `SECURITY.md` — security/non-goal posture and supported-algorithm constraints that adopter guidance must not dilute.

### Existing code and proof seams
- `lib/mix/tasks/relyra.install.ex` — blessed install/scaffold entry point.
- `lib/relyra/test_support.ex` — local test-support surface for the golden path.
- `lib/relyra/test_support/fake_idp.ex` — local proof path before involving a real IdP.
- `lib/relyra/provider.ex` — preset registry, guide URLs, label translations, and footgun checks.
- `lib/relyra/provider/okta.ex` — Okta-specific defaults, labels, and footguns.
- `lib/relyra/provider/entra.ex` — Entra-specific defaults, labels, and footguns.
- `lib/relyra/provider/google_workspace.ex` — Google Workspace-specific defaults, labels, and footguns.
- `lib/relyra/live_admin/router.ex` — optional admin mount surface that docs should present accurately.
- `lib/relyra/live_admin/query.ex` — operator-facing risk/admin information surface.
- `lib/relyra/metadata/` — metadata onboarding, refresh, and trust-lifecycle seams for runbooks and proof.
- `lib/relyra/telemetry.ex` — telemetry contract referenced by proof and day-2 guidance.
- `lib/relyra/diagnostic/` — diagnostic bundle seam that should appear in proof and operator case studies.
- `lib/relyra.ex` — core public login/consume surface that the Day-1 path wraps.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix relyra.install` already gives Relyra a natural blessed entry point for a generator-style onboarding flow.
- `Relyra.TestSupport.FakeIdP` provides the ideal local-first verification seam before adopters depend on real-provider admin setup.
- `Relyra.Provider` already encodes the right provider-doc contract: explicit registry, guide URLs, vendor labels, and known footguns.
- The shipped LiveAdmin, metadata, certificate, audit, telemetry, scheduled refresh, and diagnostic seams give Phase 27 real day-2 substance for proof and case studies.
- Earlier v1.0 phases already established a strong generated-proof and repo-native evidence posture that this phase can extend to adopter guidance.

### Established Patterns
- Relyra should prefer one canonical truth surface over scattered competing entry points.
- Claims are strongest in this repo when they are executable, falsifiable, and checked in CI.
- The project values exact support claims and clear trust-boundary ownership more than broad marketing language.
- Operator UX and developer UX should be explicit, staged, and principle-of-least-surprise oriented.

### Integration Points
- Phase 27 should restructure `README.md` and `guides/` into a coherent onboarding IA rather than merely adding more prose.
- Provider runbooks should derive terminology and support posture directly from the preset modules, not drift away from code reality.
- The proof guide and fixture app should connect install scaffolding, protocol verification, provider presets, admin/ops seams, and diagnostics into one end-to-end adoption story.
- Case studies should reuse the same canonical spine and support taxonomy so adopters see one coherent product story rather than parallel narratives.

</code_context>

<deferred>
## Deferred Ideas

- Expanding first-class provider support beyond `Okta`, `Microsoft Entra ID`, and `Google Workspace` before new preset modules, verified runbooks, and proof paths ship together.
- A broad public marketing/customer-story layer separate from repo-native technical case studies.
- Treating a full sample app or Livebook as the primary documentation source rather than as secondary support material.
- Project-level GSD config/schema changes to encode the user's preference shift more globally than this phase context currently captures; desirable, but separate from Phase 27 delivery.

</deferred>

---

*Phase: 27-adopter-onboarding-polish-and-case-studies*
*Context gathered: 2026-05-08*
