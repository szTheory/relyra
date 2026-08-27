# Phase 72: Documentation - Research

**Researched:** 2026-08-27
**Domain:** Repository-local Docker onboarding and documentation-contract testing
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Guide journey and topology
- **D-01:** Make the Solo FakeIdP path the guide's complete, deterministic zero-to-login journey.
  A reader following only `guides/docker_dev_dx.md` must be able to check prerequisites, launch the
  demo, open the login-test route, complete the FakeIdP sign-in, and inspect the resulting receipt.
- **D-02:** Present Fleet plus optional Keycloak as the second path: Fleet is for running sibling
  library demos together behind the shared proxy, and Keycloak is the optional real-IdP proof.
  Neither may become a prerequisite for the Solo/FakeIdP success path.

### Commands, URL map, and troubleshooting
- **D-03:** Document the repo-root `Makefile` as the primary Docker interface. Lead with the
  relevant public targets (`make doctor`, `make up-build`, `make up`, `make url`, `make proxy`,
  `make fleet`, lifecycle/recovery targets); mention `scripts/demo` only as the retained
  compatibility entry point, not as a parallel canonical workflow.
- **D-04:** Reproduce the launcher's browser contract accurately: Solo uses the loopback origin,
  Fleet uses `http://relyra.localhost`, optional Keycloak uses
  `http://keycloak.relyra.localhost`, and Traefik's dashboard remains on loopback port 8080.
  State plainly that `*.localhost` names are browser-facing; container health checks, bootstrap,
  and internal probes continue to use Docker service DNS.

### Cache model and recovery guidance
- **D-05:** Explain fast edits as three cooperating mechanisms: source is bind-mounted, Linux
  `deps/` and `_build/` stay in container-private named volumes, and the entrypoint reruns
  dependency resolution only when `mix.lock` changes. BuildKit download caches are supporting
  detail, not the whole explanation.
- **D-06:** Troubleshooting follows a graduated recovery ladder. Start with `make doctor` and the
  concrete corrective command it reports; use ordinary shutdown/restart next; explain that
  `reset` and `reseed` share the existing destructive database-refresh behavior; reserve
  `make nuke` for a deliberately labelled cold rebuild that deletes demo data and build/dependency
  volumes. Cover port conflicts, a missing external proxy network, the browser-only localhost
  caveat, and Keycloak public-host mismatch without inventing unsupported recovery paths.

### Receipts, honesty, and documentation routing
- **D-07:** Every proof line must keep ownership exact: Relyra verifies the assertion and produces
  the validation trace; LedgerLoop maps the user and records the host-owned session-establishment
  receipt. Do not imply that Relyra establishes a conventional browser cookie session, and do not
  collapse the FakeIdP deterministic proof into the optional Keycloak proof.
- **D-08:** Use the established house structure: a short gameplan at the top, persona/JTBD framing,
  copy-pasteable commands and URLs, and explicit `Receipt:` lines that name reproducible evidence.
  Voice remains calm, exact, transparent, operator-friendly, and open-source serious; avoid magic,
  absolutist security claims, and vague success language.
- **D-09:** Update all three existing routers coherently. The demo README owns the detailed
  evaluator Quick Start and retains Local Mix; `guides/demo.md` routes to both the Docker DX guide
  and the canonical demo README; the top-level README adds the Docker demo/Fleet guide to its
  evaluator and Day-2/operator routing without displacing the library's canonical Day-1 Getting
  Started path.

### the agent's Discretion
- Exact heading names, prose length, table layout, command grouping, cross-link placement, and the
  number of `Receipt:` lines are open provided D-01..D-09 and DOC-01..02 remain directly visible.
- The planner may extend focused documentation drift tests when needed to make the new acceptance
  criteria deterministic, but must not add manual-only or human-blocking verification.

### Deferred Ideas (OUT OF SCOPE)

- TLS/mkcert, hashed per-checkout hostnames, and a production multi-stage release Dockerfile remain
  outside v1.10.
- Any change to launcher behavior, Compose topology, Keycloak provisioning, application routes,
  browser tests, `lib/`, public API, security posture, or Hex packaging belongs outside Phase 72.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | New Docker DX guide covers paths, caching, URL map, troubleshooting, and house voice. | Makefile, Compose, entrypoint, receipt boundary, and focused drift-test contracts identify the exact facts and automated checks. [VERIFIED: codebase grep] |
| DOC-02 | Existing demo README, guide router, and top-level routing point to Make/Fleet while Local Mix remains. | Existing document ownership and link-gate rules identify the required routing edits and prevent HexDocs-relative-link breakage. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 72 is a documentation-and-focused-test phase: it must describe the already-shipped Docker surface without changing it. The source of truth is the root `Makefile`: its public targets provide the command vocabulary, its `url` target owns the ordered browser route map and walkthrough, and `doctor` emits the next recovery command for each checked failure. [VERIFIED: codebase grep]

The guide must be deliberately asymmetric. Solo is the complete deterministic first run: Docker/Compose prerequisites, `make doctor`, `make up-build`, loopback `/login/test`, FakeIdP, then visible validation-trace and LedgerLoop receipt evidence. Fleet and Keycloak are follow-on paths: Fleet introduces `make proxy` plus the proxy Compose shape and `relyra.localhost`; Keycloak remains an optional real-IdP proof at `keycloak.relyra.localhost`. [VERIFIED: codebase grep]

The needed automated evidence is static and deterministic, not a new manual gate. Extend the focused docs drift test to assert required guide phrases/commands/routes/receipt wording and router links; retain the existing Markdown link smoke test and adopter-voice test. This matches the project requirement that new acceptance criteria have deterministic CI evidence. [VERIFIED: codebase grep]

**Primary recommendation:** Create one Make-first `guides/docker_dev_dx.md` that walks Solo to a FakeIdP receipt, then explains Fleet/optional Keycloak and recovery; update the three router documents and add only focused static drift assertions.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Docker command vocabulary and URL map | Repository tooling | Docker/Compose | `Makefile` centralizes public targets and emits the browser contract. [VERIFIED: codebase grep] |
| Solo evaluator journey | Browser / Client | Docker/Compose | The reader opens the loopback app and completes the browser-facing FakeIdP flow after Compose starts it. [VERIFIED: codebase grep] |
| Fleet ingress | CDN / Static | Docker/Compose | Traefik owns host-based ingress on the external `proxy` network; the demo only supplies labels. [VERIFIED: codebase grep] |
| Assertion verification / trace | API / Backend | Browser / Client | Relyra verifies the assertion and provides trace evidence; the browser displays the result. [VERIFIED: codebase grep] |
| Session-establishment receipt | API / Backend | Database / Storage | LedgerLoop's session adapter writes a `LoginReceipt` row after verification. [VERIFIED: codebase grep] |
| Documentation correctness | Repository tooling | CI | ExUnit docs tests can inspect documentation and launcher contracts without a live Docker stack. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

- Stay within the active phase scope: documentation and focused test updates only; do not change application/library behavior. [VERIFIED: AGENTS.md]
- Preserve all SAML security invariants, including configured-cert trust, one `saxy` parse path, pre-parse guards, required cryptographic verification, audited trust mutation, and production replay protection. [VERIFIED: AGENTS.md]
- Do not alter the named architecture seams or public API/behaviour signatures. [VERIFIED: AGENTS.md]
- New acceptance criteria require deterministic automated evidence in a mandatory CI lane; do not add blocking manual verification or human-needed completion. [VERIFIED: AGENTS.md]
- Keep `mix qa`, `mix ci.security`, `mix test --warnings-as-errors`, and `mix format --check-formatted` green; do not weaken adversarial crypto tests. [VERIFIED: AGENTS.md]
- Use conventional commits, and do not run Hex publishing commands. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Repository Markdown | N/A | Guide and routing documents | All Phase 72 deliverables are Markdown documentation; no new runtime dependency is warranted. [VERIFIED: codebase grep] |
| ExUnit | project-managed | Static documentation-contract tests | Existing `test/docs/*` tests already validate launcher, links, and adopter voice deterministically. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GNU Make | 3.81 installed | Canonical user-facing Docker launcher | Document public Make targets; do not duplicate raw Compose command shapes for normal users. [VERIFIED: local environment + codebase grep] |
| Docker Compose | v5.1.3 installed | Runs the Solo/Fleet topology | Required only for the documented Docker paths. [VERIFIED: local environment + codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Make-first guide | `scripts/demo`-first guide | Rejected by locked D-03: `scripts/demo` is compatibility-only and exposes fewer verbs. [VERIFIED: codebase grep] |
| Static docs drift assertions | Browser/manual acceptance gate | Rejected by project testing rules; static contracts are deterministic and the live topology already has owned harnesses. [VERIFIED: AGENTS.md + codebase grep] |

**Installation:** None — this phase must not install packages. [VERIFIED: CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Fresh checkout
    |
    v
guides/docker_dev_dx.md
    |
    +--> Solo (required) -----------------------------------------+
    |    make doctor -> make up-build -> http://localhost:4000    |
    |    -> /login/test -> FakeIdP -> validation trace + receipt  |
    |                                                             v
    |                                                     LedgerLoop LoginReceipt
    |
    +--> Fleet (optional) -> make proxy -> make up-build
    |                         -> http://relyra.localhost
    |                         -> make fleet / Traefik dashboard
    |
    +--> Keycloak (optional, after Fleet) -> proxy profile
         -> http://keycloak.relyra.localhost -> real-IdP proof

Documentation edits -> focused ExUnit drift tests -> CI docs lanes
```

The Makefile remains the only canonical source for launcher commands and emitted URLs; documents link and explain rather than recreate implementation logic. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
guides/
├── docker_dev_dx.md            # New full Docker Solo/Fleet guide
└── demo.md                     # Concise HexDocs/source-repo router
demo/ledger_loop/
└── README.md                   # Detailed evaluator entry and Local Mix path
README.md                       # GitHub evaluator and Day-2 router
test/docs/
└── demo_guide_drift_test.exs   # Focused deterministic launcher/docs contract
```

### Pattern 1: Single source of operational truth

**What:** Use the public Make targets, the `make url` output contract, and `make doctor` remediation lines verbatim as the guide's operational source. [VERIFIED: codebase grep]

**When to use:** For every command, URL, and recovery instruction in the new guide and its router summaries. [VERIFIED: codebase grep]

**Example:**

```bash
make doctor
make up-build
# Open http://localhost:4000/login/test
```

Source: `Makefile`. [VERIFIED: codebase grep]

### Pattern 2: Required deterministic path, clearly subordinate optional paths

**What:** Present Solo/FakeIdP first as the complete journey. Put Fleet and Keycloak after its receipt, labelled optional and with their own prerequisites. [VERIFIED: CONTEXT.md]

**When to use:** In the gameplan, path comparison, URL map, and README routing copy. [VERIFIED: CONTEXT.md]

### Pattern 3: Evidence-labelled documentation

**What:** Every journey endpoint gets a `Receipt:` line that identifies reproducible, correctly owned evidence. Relyra owns assertion verification/validation trace; LedgerLoop owns user mapping and the session-establishment receipt. [VERIFIED: codebase grep]

**When to use:** At the end of Solo/FakeIdP and optional Keycloak walkthroughs, without claiming a Relyra-owned cookie session or authorization decision. [VERIFIED: CONTEXT.md + codebase grep]

### Anti-Patterns to Avoid

- **A second launcher vocabulary:** Do not tell readers to use raw `docker compose` commands when a Make target exists; the paths then drift from `Makefile`. [VERIFIED: CONTEXT.md + codebase grep]
- **Fleet as a prerequisite:** Do not place `make proxy`, Keycloak, or `relyra.localhost` before the Solo success path. [VERIFIED: CONTEXT.md]
- **Unqualified success claims:** Do not say Relyra created a browser session or authorized a user; LedgerLoop records the host-owned receipt after Relyra verification. [VERIFIED: codebase grep]
- **Publishing repo-only links from HexDocs:** `guides/demo.md` must use an absolute GitHub URL for `demo/ledger_loop/README.md`, because `demo/` is outside the package-file allowlist used by the link smoke test. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docker lifecycle instructions | A new shell-script or raw Compose API | Existing public Make targets | The Makefile owns topology selection, URL output, recovery, and compatibility routing. [VERIFIED: codebase grep] |
| Documentation validation | A new browser/manual checklist | `test/docs/demo_guide_drift_test.exs`, `markdown_link_smoke_test.exs`, and `adopter_voice_test.exs` | Existing deterministic lanes inspect the relevant contracts without host-state flakiness. [VERIFIED: codebase grep] |
| Receipt semantics | New shorthand such as “Relyra session” | Existing exact host-boundary wording | The session adapter and UI tests encode the correct ownership boundary. [VERIFIED: codebase grep] |

**Key insight:** The implementation is already self-documenting at the launcher seam. Phase 72 should expose that seam to readers and test the docs against it rather than fork it. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Stale command and origin documentation

**What goes wrong:** README text refers to `scripts/demo`, direct `docker compose`, or `localhost:8080` Keycloak even though Make owns the stable interface and Keycloak is proxy-hosted. [VERIFIED: codebase grep]

**Why it happens:** The old docs predate the launcher/proxy work; `scripts/demo` deliberately retains a limited compatibility map. [VERIFIED: codebase grep]

**How to avoid:** Use `make doctor`, `make up-build`, `make up`, `make url`, `make proxy`, and `make fleet` as the canonical flow. Keep `scripts/demo` only as a compatibility note. [VERIFIED: CONTEXT.md]

**Warning signs:** Any new docs occurrence of `scripts/demo` as the primary path, `docker compose --profile keycloak up -d`, or `http://localhost:8080` as the Keycloak UI. [VERIFIED: codebase grep]

### Pitfall 2: Explaining only BuildKit cache

**What goes wrong:** A reader expects source edits to rebuild images or cannot understand why Linux artifacts remain fast and safe. [VERIFIED: codebase grep]

**Why it happens:** BuildKit cache mounts are visible in the Dockerfile but are not the runtime cache that masks host artifacts. [VERIFIED: codebase grep]

**How to avoid:** Explain the three-part model in this order: bind-mounted source; named `deps/`/`_build/` Linux artifacts; lock-hash-gated dependency refresh. Mention Hex/rebar BuildKit caches as supporting build-time detail. [VERIFIED: CONTEXT.md + codebase grep]

**Warning signs:** The guide claims `make up` rebuilds dependencies for ordinary source edits, or omits `mix.lock` from the rebuild decision. [VERIFIED: codebase grep]

### Pitfall 3: Treating browser hostnames as container DNS

**What goes wrong:** Readers attempt to use `relyra.localhost` for internal health checks, provisioning, or service-to-service access. [VERIFIED: codebase grep]

**Why it happens:** Public host routes and Docker service DNS deliberately have distinct consumers. [VERIFIED: CONTEXT.md]

**How to avoid:** State the split-horizon rule next to the URL map: `*.localhost` is browser-facing; Docker health checks, bootstrap, and internal probes use service DNS. [VERIFIED: CONTEXT.md + codebase grep]

**Warning signs:** Documentation tells a container to reach `http://relyra.localhost` or changes the health-check domain from `localhost`/service DNS. [VERIFIED: codebase grep]

### Pitfall 4: Overstating the receipt

**What goes wrong:** The guide collapses cryptographic verification, mapping, session establishment, and authorization into a single “logged in by Relyra” statement. [VERIFIED: codebase grep]

**How to avoid:** Use the exact sentence: “Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt.” [VERIFIED: codebase grep]

### Pitfall 5: Destructive recovery without escalating labels

**What goes wrong:** A reader loses demo data or dependency/build caches by treating `reset`, `reseed`, and `nuke` as ordinary restart commands. [VERIFIED: codebase grep]

**How to avoid:** Document the ladder: doctor’s `Next:` command → `make down` / normal relaunch → `make reset` or `make reseed` (database refresh) → explicitly confirmed `make nuke` (cold rebuild that deletes named volumes). [VERIFIED: CONTEXT.md + codebase grep]

## Code Examples

Verified patterns from the executable surface:

### Deterministic Solo journey

```bash
make doctor
make up-build

# Browser: http://localhost:4000/login/test
# Choose FakeIdP, complete the sign-in, then inspect the operator trace.
```

Source: `Makefile` route banner and walkthrough. [VERIFIED: codebase grep]

### Fleet with optional Keycloak proof

```bash
make proxy
make up-build
make url
make fleet

# Browser app: http://relyra.localhost/login/test
# Optional real IdP: http://keycloak.relyra.localhost/admin
# Proxy dashboard: http://localhost:8080/dashboard/
```

Source: `Makefile`, `docker-compose.proxy.yml`, and `docker/traefik/compose.yml`. [VERIFIED: codebase grep]

### Focused documentation drift gate

```bash
mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors
mix test test/docs/markdown_link_smoke_test.exs --warnings-as-errors
mix test test/docs/adopter_voice_test.exs --warnings-as-errors
```

Source: `mix.exs` CI aliases and existing test files. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `scripts/demo` and direct Compose instructions | Root Makefile as primary launcher; compatibility script delegates into it | Phase 71 | Docs must teach Make first and avoid a competing workflow. [VERIFIED: codebase grep] |
| Solo-only published host / direct Keycloak host port | Solo loopback plus opt-in Traefik Fleet; Keycloak proxy origin | Phases 69–70 | URL maps must distinguish loopback, Fleet, optional Keycloak, and dashboard origins. [VERIFIED: codebase grep] |
| Runtime docs without a dedicated Docker guide | Dedicated Make-first Docker DX guide and docs contract tests | Phase 72 (planned) | The guide becomes the complete zero-to-login narrative. [VERIFIED: CONTEXT.md] |

**Deprecated/outdated:**

- `scripts/demo` as the primary documented Docker interface: retained only as compatibility delegation to Make. [VERIFIED: CONTEXT.md + codebase grep]
- Direct Keycloak `localhost:8080` browser instruction: replace with proxy-hosted `keycloak.relyra.localhost`; port 8080 is Traefik’s loopback dashboard. [VERIFIED: CONTEXT.md + codebase grep]

## Assumptions Log

All material implementation claims are grounded in the repository, locked context, or official Docker documentation. The only unavailable source was Context7; it was not used as authority because its MCP and CLI were absent. [VERIFIED: local environment]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None | — | — |

## Open Questions

1. **RESOLVED — Should `guides/docker_dev_dx.md` be added to ExDoc extras?**
   - Decision: No. The locked no-new-Hex-surface boundary governs: keep `mix.exs` and its ExDoc extras unchanged. `guides/demo.md` must route to the repository-only guide with the absolute canonical URL `https://github.com/szTheory/relyra/blob/main/guides/docker_dev_dx.md`. [VERIFIED: CONTEXT.md + plan boundary]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Docker | Solo/Fleet guide and live verification | ✓ | 29.5.2 | — |
| Docker Compose plugin | Solo/Fleet guide and live verification | ✓ | v5.1.3 | — |
| GNU Make | Canonical public launcher | ✓ | 3.81 | `scripts/demo` only for legacy verb compatibility, not a complete workflow. [VERIFIED: codebase grep] |
| Elixir / Mix | Focused docs tests | ✓ | Elixir 1.19.5 / OTP 28 | — |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment]

**Missing dependencies with fallback:** None. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (project-managed) [VERIFIED: codebase grep] |
| Config file | `mix.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: AGENTS.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOC-01 | Docker guide includes Solo/Fleet distinction, cache model, URL map, recovery caveats, and exact receipt ownership. | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extend existing file |
| DOC-01 | Guide retains house voice, no planning vocabulary, and valid local guide links. | static contract | `mix test test/docs/adopter_voice_test.exs test/docs/markdown_link_smoke_test.exs --warnings-as-errors` | ✅ existing files automatically scan `guides/**/*.md` |
| DOC-02 | Demo README, demo guide, and root README route to Make-first Docker/Fleet while retaining Local Mix. | static contract | `mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` | ✅ extend existing file |
| DOC-02 | Published-doc relative links do not resolve outside package files. | static contract | `mix test test/docs/markdown_link_smoke_test.exs --warnings-as-errors` | ✅ existing file |

### Sampling Rate

- **Per task commit:** focused docs commands above. [VERIFIED: codebase grep]
- **Per wave merge:** `mix test --warnings-as-errors`. [VERIFIED: AGENTS.md]
- **Phase gate:** `mix qa`, `mix ci.security`, `mix format --check-formatted`, and full test suite green before verification. [VERIFIED: AGENTS.md]

### Wave 0 Gaps

- [ ] Extend `test/docs/demo_guide_drift_test.exs` with static assertions for new-guide existence/content, canonical commands and origins, optional-path ordering, recovery terms, ownership sentence, and all three router links. [VERIFIED: codebase grep]
- [ ] Keep `mix.exs` and its ExDoc extras unchanged under the locked no-new-Hex-surface boundary; assert that `guides/demo.md` uses the absolute canonical repository URL `https://github.com/szTheory/relyra/blob/main/guides/docker_dev_dx.md`. [VERIFIED: CONTEXT.md + resolved Open Question]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Docs preserve the signed-assertion and FakeIdP/Keycloak proof boundary; no authentication behavior changes. [VERIFIED: AGENTS.md + CONTEXT.md] |
| V3 Session Management | yes | Docs name LedgerLoop, not Relyra, as the owner of session establishment and its persisted receipt. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Docs must not claim Relyra owns downstream authorization. [VERIFIED: codebase grep] |
| V5 Input Validation | no implementation change | No input-handling code is in scope; preserve the documented strict validation posture. [VERIFIED: CONTEXT.md + AGENTS.md] |
| V6 Cryptography | yes | Do not weaken or overstate cryptographic verification; docs say Relyra verifies the assertion, not merely that a structural response was accepted. [VERIFIED: AGENTS.md + codebase grep] |

### Known Threat Patterns for documentation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misleading trust/session ownership claim | Spoofing / Elevation of privilege | Use exact receipt wording and static drift assertions; retain host-boundary tests. [VERIFIED: codebase grep] |
| Browser hostname presented as internal endpoint | Tampering / Denial of service | Document public `*.localhost` versus Docker service-DNS split and keep command/URL tests. [VERIFIED: CONTEXT.md + codebase grep] |
| Destructive reset described as safe restart | Denial of service | Label reset/reseed as data refresh and nuke as explicit confirmed cold rebuild. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `Makefile` — public target inventory, routes, walkthrough, doctor remediation, recovery semantics. [VERIFIED: codebase grep]
- `docker-compose.yml`, `docker-compose.override.yml`, `docker-compose.proxy.yml`, and `docker/traefik/compose.yml` — Solo/Fleet/Keycloak topology and public/internal boundaries. [VERIFIED: codebase grep]
- `demo/ledger_loop/docker-entrypoint.sh` — lock-hash dependency gate and runtime cache behavior. [VERIFIED: codebase grep]
- `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex` plus associated controller tests — receipt ownership boundary. [VERIFIED: codebase grep]
- `test/docs/demo_guide_drift_test.exs`, `test/docs/markdown_link_smoke_test.exs`, and `test/docs/adopter_voice_test.exs` — deterministic validation seams. [VERIFIED: codebase grep]
- `AGENTS.md` and Phase 72 `CONTEXT.md` — non-negotiable scope, security, testing, and locked documentation decisions. [VERIFIED: AGENTS.md + CONTEXT.md]

### Secondary (MEDIUM confidence)

- [Docker Compose Quickstart](https://docs.docker.com/compose/gettingstarted/) — Compose debugging practice: inspect resolved configuration and use lifecycle/log/exec commands. [CITED: https://docs.docker.com/compose/gettingstarted/]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — documentation-only phase with existing repository tools and no package selection. [VERIFIED: codebase grep]
- Architecture: HIGH — Makefile, Compose files, entrypoint, and receipt code directly define the documented system. [VERIFIED: codebase grep]
- Pitfalls: HIGH — stale current docs, locked decisions, and tests expose the exact drift risks. [VERIFIED: codebase grep]

**Research date:** 2026-08-27
**Valid until:** 2026-09-26 (repository-contract research; refresh after any launcher/topology change)
