# Interactive GSD new-project — Relyra (questions + research subagents)

Use this path when you want **deep questioning**, then **four parallel `gsd-project-researcher` agents** plus **`gsd-research-synthesizer`**, instead of `/gsd-new-project --auto` (which skips questioning).

**Repo root:** `/Users/jon/projects/relyra`
**Preconditions:** `git init` done (already complete); **no** `.planning/` yet (if a prior init exists, use `/gsd-progress` or intentionally remove `.planning/` only for a full reset).

---

## First message to send (slash + attachments)

Paste in **Claude Code / Cursor** from the relyra repo root with a cleared context:

```text
/gsd-new-project

@prompts/RELYRA-GSD-IDEA.md
@prompts/relyra-engineering-dna-from-prior-libs.md
@prompts/elixir-saml-lib-deep-research.md
@prompts/relyra-brand-book.md
```

**Optional** (more context, longer window — add if the cleared session has budget; all four primaries above are the minimum):

```text
@prompts/elixir-opensource-libs-best-practices-deep-research.md
@prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md
@prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md
@prompts/phoenix-best-practices-deep-research.md
@prompts/phoenix-live-view-best-practices-deep-research.md
@prompts/ecto-best-practices-deep-research.md
@prompts/elixir-best-practices-deep-research.md
@prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md
```

---

## How GSD splits questioning vs research

| Mode | Step 3 deep questioning | Step 6 parallel domain research |
|------|-------------------------|-----------------------------------|
| `/gsd-new-project --auto @idea.md` | Skipped | Always on (auto-approved downstream) |
| `/gsd-new-project` (no `--auto`) | On — until you choose **Create PROJECT.md** | Asked — choose **Research first** for 4× `gsd-project-researcher` + synthesizer → `.planning/research/*.md` |

Subagent types (fixed by GSD): `gsd-project-researcher`, `gsd-research-synthesizer`, `gsd-roadmapper`.

---

## Answering Step 3 without re-writing the pitch

When asked what you want to build, reply along the lines of:

> Use the attached Relyra prompts as the baseline product definition. Ask follow-ups focused on the **open decisions** in `RELYRA-GSD-IDEA.md` § "Open decisions for /gsd-discuss-phase / planning". In particular I want to lock:
> 1. The **XML security path ADR** (pure-BEAM XMLDSig vs NIF-over-xmlsec vs hybrid) — this is the single largest v0.1 risk per the deep-research doc.
> 2. The **package shape at v0.1** (single `relyra` with optional LiveView admin vs sibling `relyra` + `relyra_admin`).
> 3. The **request/replay store default** strategy.
> 4. The **scope line** between v0.1 (SP-initiated only) and v0.2 (Ecto schemas + metadata tooling + cert rollover) — confirm what ships in the first Hex release.
> 5. The **installer scope** (does `mix relyra.install` ship in v0.1, or wait for v0.2?).
>
> Do not re-debate strict defaults, IdP-initiated-off-by-default, SLO-deferred-to-v0.5, or any of the other non-negotiables listed in the deep-research and brand-book docs — those are locked.

Continue until you select **Create PROJECT.md**.

---

## Step 5 — workflow preferences (maximize research quality for a security-sensitive lib)

- **Research** = **Yes** — per-phase research during execution (separate from Step 6). Relyra is security-critical; do not skip.
- **Plan check** / **Verifier** = **Yes** — recommended strongly for a SAML library where the adversarial corpus matters.
- **AI models** = **Quality** — stronger researcher/roadmapper models pay for themselves on a security-sensitive lib.

Saved defaults: optionally maintain `~/.gsd/defaults.json` so Step 5 offers "Use as-is" — see GSD `new-project` workflow docs.

---

## Step 6 — research decision (this spawns the subagents)

Choose **Research first (Recommended)**.

That run creates `.planning/research/` with parallel dimensions and a **SUMMARY.md** after synthesis. Suggest asking the researchers to cover:

- **Stack** — Hex name availability for `relyra`, Elixir/OTP/Phoenix/Ecto/LiveView baselines cross-checked against the sibling repos and April 2026 ecosystem map, XML library options (sweet_xml / saxy / xmerl / xmlsec NIF bindings), crypto library choices, known-CVE list for existing Elixir and cross-ecosystem SAML libs.
- **Features** — MVP SP-initiated flow cut, which three provider presets matter for v0.1 (Okta / Entra / Google Workspace per deep research), installer scope, admin-UI v1 scope.
- **Architecture** — bounded contexts (protocol core vs Phoenix vs Ecto vs LiveView), the five public behaviours, optional-deps gateway strategy, request/replay store pluggability, XMLDSig path ADR.
- **Pitfalls** — SAML-specific: XXE, signature wrapping, parser differentials, SHA-1, RelayState open redirect, IdP-initiated misuse, SLO overpromise, NameID/email conflation, certificate-rollover UX, ETS-in-cluster footgun. OSS-specific: release-please on a security lib (SECURITY.md + private advisory interaction), post-publish parity check for a library with generators, installer-golden-diff discipline.

---

## After `/gsd-new-project` completes

```text
/gsd-plan-phase 1
```

On CLIs without `AskUserQuestion`, add **`--text`** where your GSD install documents it.

Expect phase 1 to be the XML-security-path ADR + minimal protocol core scaffold, before any Phoenix/Ecto surface work.

---

## Terminal alternative (if you use `gsd-sdk` instead of slash)

```bash
cd /Users/jon/projects/relyra
gsd-sdk init @prompts/RELYRA-GSD-IDEA.md
```

Interactive questioning is primarily via the **slash workflow** in the IDE; terminal init may differ — prefer the paste block above for the full interactive + research path.

---

## What "done" looks like for the bootstrap session

After `/gsd-new-project` completes you should have:

- `.planning/PROJECT.md` — north star, principles, non-goals, current milestone, tech baseline.
- `.planning/roadmap/ROADMAP.md` — milestones v0.1 → v1.0 with phase breakdowns.
- `.planning/research/` — 4 researcher outputs + SUMMARY.md.
- Fresh `mix.exs`, root files (README, LICENSE, CHANGELOG, SECURITY, CONTRIBUTING, CODE_OF_CONDUCT, MAINTAINING, CLAUDE.md, AGENTS.md, CONVENTIONS.md), `.formatter.exs`, `.credo.exs`, `.tool-versions`, initial `.github/workflows/ci.yml` skeleton — all per the DNA doc §5 starter skeleton.
- Initial commit with conventional-commit message so Release Please is happy on day 1.

Then `/gsd-plan-phase 1` to hit the XML security path ADR as the first real decision.
