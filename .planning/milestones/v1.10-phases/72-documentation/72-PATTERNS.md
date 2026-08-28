# Phase 72: Documentation - Pattern Map

**Mapped:** 2026-08-27  
**Files analyzed:** 5  
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/docker_dev_dx.md` | config (adopter guide) | transform | `/Users/jon/projects/scoria/docs/docker_dev_dx.md` | role-match |
| `demo/ledger_loop/README.md` | config (evaluator README) | transform | `guides/demo.md` + its existing sections | exact |
| `guides/demo.md` | config (published-doc router) | transform | `guides/batteries_included.md` | role-match |
| `README.md` | config (GitHub evaluator / Day-2 router) | transform | its `Start Here` and `Day-2 And Operator Guides` sections | exact |
| `test/docs/demo_guide_drift_test.exs` | test | transform | its existing static launcher-contract cases | exact |

## Pattern Assignments

### `guides/docker_dev_dx.md` (config, transform)

**Analog:** `/Users/jon/projects/scoria/docs/docker_dev_dx.md` (same sibling-library Docker guide pattern); runtime facts must derive from Relyra's `Makefile`, not the sibling's commands.

**Opening gameplan and operator framing** (Scoria guide lines 1-43):

```markdown
# Docker dev DX - multi-instance, no port conflicts

This guide is for the solo maintainer running many Phoenix/Elixir demo repos
on one Mac.

## TL;DR

```bash
make proxy
make up-build
make up
make url
make open
make fleet
make doctor
```
```

Copy the short title, persona/JTBD framing, `TL;DR` command block, then turn the Relyra sequence into an intentionally asymmetric two-path gameplan: Solo/FakeIdP first; Fleet and Keycloak afterwards as optional proof.

**Mental model / browser boundary** (Scoria guide lines 45-62):

```markdown
Three rules remove the recurring local-development collision class:

1. **One shared reverse proxy, routes by instance.**
2. **No published database ports in the Docker stack.**
3. **Ephemeral loopback is only a fallback.**
```

Use this compact explanatory structure, but state Relyra's actual contract from [`Makefile`](../../../Makefile): Solo is `http://localhost:$PORT`; Fleet is `http://$RELYRA_HOST`; `*.localhost` is browser-facing while health checks and internal probes use Docker service DNS (lines 75-98).

**Cache-model and recovery sections** (Scoria guide lines 193-242; 301-355):

```markdown
## Caching guarantees

Commands:

```bash
make up
make up-build
make up-d
make up-d-build
```

Footguns:

- `.dockerignore` must exclude host `_build/`, `deps/`, and ...

Recovery:

```bash
make up-build
make doctor
```
```

Retain the heading → commands → expected-output/mental-model → footguns → recovery rhythm. Replace sibling-specific claims with Relyra's bind-mounted source, `relyra_deps`/`relyra_build` named volumes, and lock-hash gate: [`docker-compose.yml` lines 19-28](../../../docker-compose.yml) and [`docker-entrypoint.sh` lines 10-24](../../../demo/ledger_loop/docker-entrypoint.sh).

**Evidence-labelled end states:** use explicit `Receipt:` lines after the Solo and optional Keycloak walkthroughs. The source boundary is [`session_adapter.ex` lines 24-40](../../../demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex): `principal_verified_by: "Relyra"`, `mapping_owner: "LedgerLoop"`, `session_owner: "LedgerLoop"`, and failure is typed as `:session_establishment_failed`. The required prose is: “Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt.”

**Operational source of truth:** [`Makefile` lines 21-98](../../../Makefile) provides public targets, URLs, walkthrough order, and the DNS caveat; lines 132-208 provide `doctor` remediation; lines 44-69 define the preservation/destructive ladder. Document those commands and meanings, never raw Compose as a competing normal workflow.

---

### `demo/ledger_loop/README.md` (config, transform)

**Analog:** existing `demo/ledger_loop/README.md` (same file; preserve its evaluator ownership) with router form from `guides/demo.md`.

**Evaluator framing and ownership boundary** (lines 1-14, 18-29):

```markdown
> This is adoption evidence: a fictional Phoenix B2B SaaS showing Relyra embedded in a real
> host application. ... exactly where your app takes over.

## At a Glance

| Demonstrates | Does Not Demonstrate |
|---|---|
| ... Host-app boundary: Relyra verifies; LedgerLoop owns mapping/session/authz | ... |
```

Preserve this precise scope statement and table. Refresh only the Docker entry point below it; retain the Local Mix path as a supported alternative.

**Quick-start layout** (lines 33-69):

```markdown
## Quick Start

### Option A — Docker (Recommended)

```bash
...
```

### Option B — Local Mix

```bash
mix setup
```
```

Keep the two-option hierarchy. Replace stale `scripts/demo` commands with Make-first Solo commands and route detailed Docker/Fleet material to `guides/docker_dev_dx.md`; do not remove the Local Mix paragraph and setup explanation.

**Walkthrough and route tables** (lines 73-98, 130-155): retain the headed walkthrough followed by clearly owned “Success path”, “Rejection path”, and “Audit trail”, then route tables. Correct the success language to the required `Receipt:` ownership wording and route optional Keycloak to the proxy public origin.

**Honesty pattern** (lines 214-229 and 233-255): retain the owner matrix and separate “What this demo proves” / “What this demo does not cover” lists. Do not claim that Relyra establishes the browser session or authorizes the user.

---

### `guides/demo.md` (config, transform)

**Analog:** [`guides/demo.md`](../../../guides/demo.md) itself (lines 1-21), which is intentionally concise, plus the link style in [`guides/jtbd_user_flows.md` lines 458-473](../../../guides/jtbd_user_flows.md).

**Published-router pattern** (current file lines 1-21):

```markdown
# LedgerLoop Demo App

A runnable reference app ships in this repository ... It is **not part of the Hex package** ...

The full guide ... lives in the demo README in the repository:

**[LedgerLoop Demo App README](https://github.com/szTheory/relyra/blob/main/demo/ledger_loop/README.md)**

That file is the canonical evaluator entry point. Start there.
```

Keep this short, source-repository-oriented explanation. Add the Docker DX guide as the Make-first operational route and retain the absolute GitHub URL for the demo README: a published guide must not use a relative link into `demo/`, because the package link gate rejects paths outside package files.

---

### `README.md` (config, transform)

**Analog:** [`README.md` lines 37-53](../../../README.md) and lines 113-136.

**Day-1 router pattern** (lines 37-49):

```markdown
## Start Here

Use one Day-1 route:

1. Browse the [documentation overview](guides/overview.md) — Day-1, Day-2, and Reference sections.
2. Install the library and scaffold the host app with `mix relyra.install`.
3. Follow [Getting Started](guides/getting_started.md).
...

The README is the router. The full onboarding narrative lives in
[guides/getting_started.md](guides/getting_started.md).
```

Leave this canonical library Day-1 sequence intact. Add Docker-demo/Fleet evaluation routing without presenting it as the library installation path.

**Day-2 index pattern** (lines 113-132):

```markdown
## Day-2 And Operator Guides

These surfaces matter after Day-1, but they should not compete with onboarding:

- [Production Ecto path](guides/production_ecto_path.md) — cluster-safe stores and migrations.
...
- [LedgerLoop demo app](guides/demo.md) — a runnable reference app, not part of the Hex package,
  showing Relyra embedded in a Phoenix SaaS host with Ecto-backed stores and browser-visible receipts.
```

Add a sibling bullet for the Docker demo/Fleet guide with this compact link-and-purpose format, and retain the existing demo router.

---

### `test/docs/demo_guide_drift_test.exs` (test, transform)

**Analog:** existing static launcher/documentation contract cases in the same file.

**Module setup and source-at-runtime pattern** (lines 1-30):

```elixir
defmodule Relyra.Docs.DemoGuideDriftTest do
  @moduledoc """
  Static contract for the repository-local demo launcher.
  ... assertions read that source at runtime ... without needing Docker to be running.
  """
  use ExUnit.Case, async: true

  @makefile_path "Makefile"
```

Add documentation assertions here, keeping `async: true`, file reads at test runtime, and deterministic text/link assertions—no Docker/browser/manual validation.

**Ordered contract assertion helper** (lines 60-87, 537-550):

```elixir
assert_in_order(url_recipe, [
  "==> Browser origins",
  "http://$${RELYRA_HOST}",
  "http://localhost:$${PORT}",
  ...
])

defp assert_in_order(text, tokens) do
  Enum.reduce(tokens, -1, fn token, previous_index ->
    case :binary.match(text, token) do
      {index, _length} when index > previous_index -> index
      {index, _length} -> flunk(...)
      :nomatch -> flunk(...)
    end
  end)
end
```

Use direct `File.read!` plus `assert`/`refute`/`assert_in_order` for guide content and links: existence of the new guide; Make targets/origins; Solo-before-Fleet ordering; recovery words; exact receipt sentence; and links from all three routers.

**Package-safe link constraint:** [`test/docs/markdown_link_smoke_test.exs` lines 81-126](../../../test/docs/markdown_link_smoke_test.exs) resolves every published-doc relative link and fails links that lead outside `package.files`. Preserve absolute GitHub links from `guides/demo.md` to `demo/ledger_loop/README.md`.

## Shared Patterns

### Makefile as the sole operational source

**Source:** [`Makefile` lines 21-98](../../../Makefile)

**Apply to:** `guides/docker_dev_dx.md`, `demo/ledger_loop/README.md`, `guides/demo.md`, `README.md`, and drift tests.

```make
## proxy: start the shared Traefik proxy and its external network
proxy:
	docker network inspect "$${DEMO_PROXY_NETWORK}" >/dev/null 2>&1 || docker network create "$${DEMO_PROXY_NETWORK}"
	$(PROXY_COMPOSE) up -d

## up-build: build and start the loopback solo demo in the foreground
up-build:
	$(SOLO_COMPOSE) up --build
...
## url: print browser origins, routes, walkthrough, and topology notes
```

Documents explain and route to this public command surface; tests protect it.

### Receipt ownership

**Source:** [`demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex` lines 24-40](../../../demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex)

**Apply to:** new Docker guide and refreshed evaluator README.

```elixir
receipt_proof = %{
  receipt_id: receipt.id,
  principal_verified_by: "Relyra",
  mapping_owner: "LedgerLoop",
  session_owner: "LedgerLoop",
  authorization_owner: "LedgerLoop"
}

{:ok, receipt_proof}
```

### Published Markdown / adopter-voice gates

**Source:** [`test/docs/markdown_link_smoke_test.exs` lines 81-126](../../../test/docs/markdown_link_smoke_test.exs) and [`test/docs/adopter_voice_test.exs` lines 8-30](../../../test/docs/adopter_voice_test.exs)

**Apply to:** every edited Markdown file.

```elixir
@guide_globs ["guides/**/*.md", "README.md"]

@forbidden_patterns [
  {~r/\.planning/, ".planning path"},
  {~r/\bPhase\s+\d+/, "phase number"},
  {~r/\bADOPT-\d+/, "ADOPT requirement id"},
  {~r/Relyra repository/, "Relyra repository maintainer phrase"},
  {~r/\/gsd-/, "GSD command reference"},
  {~r/release-please/, "release-please maintainer note"}
]
```

## No Analog Found

None. Every scoped file extends an established documentation/router or deterministic docs-test pattern.

## Metadata

**Analog search scope:** `README.md`, `guides/`, `demo/ledger_loop/`, `test/docs/`, `Makefile`, Docker runtime contracts, and the sibling Scoria Docker guide.  
**Files scanned:** 14  
**Pattern extraction date:** 2026-08-27
