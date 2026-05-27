# Phase 43: Hex publish prep — version bump & CHANGELOG backfill — Research

**Researched:** 2026-05-27  
**Phase:** 43 — Hex publish prep — version bump & CHANGELOG backfill  
**Requirements:** PUB-01 (partial — staging only), PUB-02  
**Context:** `43-CONTEXT.md` (USER DECISIONS — authoritative for scope)

## Summary

Phase 43 is a **staging-only** release-prep wedge: bump the version sources to `1.4.0`, fix the stale install pin, and hand-write `[1.3.0]` / `[1.4.0]` CHANGELOG sections from milestone evidence. It does **not** cut `v1.4.0`, publish to Hex, or diagnose the stalled release-please pipeline (Phases 44–45).

The repo is **adopter-blocked**: Hex latest is `1.2.0` (2026-05-25) while git carries v1.3 + v1.4 feature work, a non-SemVer `v1.4` tag, and ExDoc `extras:` that already advertise v1.3/v1.4 guides. Phase 41 (tarball hygiene) and Phase 42 (login trace) are complete — the tree is ready for a honest `1.4.0` publish once automation runs.

**Primary recommendation:** One atomic release-prep change set touching exactly four files (`mix.exs`, `.release-please-manifest.json`, `guides/getting_started.md`, `CHANGELOG.md`). Optionally add a pin/version drift guard in a second plan if the planner wants long-term hygiene beyond D-10.

---

## 1. Current State Audit

### Version sources (must agree at `1.4.0` before Phase 44)

| Source | Path | Current | Target | Notes |
|--------|------|---------|--------|-------|
| Mix project version | `mix.exs:6` `@version` | `"1.2.0"` | `"1.4.0"` | Drives `version:` in `project/0` |
| ExDoc GitHub links | `mix.exs:123` `source_ref:` | `"v1.2.0"` | `"v1.4.0"` | Derived via `"v#{@version}"` — updates automatically with `@version` |
| Release Please manifest | `.release-please-manifest.json` | `"1.2.0"` | `"1.4.0"` | **Must be hand-set** — incremental minor bumps from `1.2.0` cannot reach `1.4.0` without skipping |
| Hex published | `mix hex.info relyra` | `1.2.0` (2026-05-25) | — | Phase 44 outcome |
| Git tags (SemVer) | `git tag -l 'v1*'` | `v1.2.0` latest SemVer release tag | — | Also `v1.4` (non-SemVer milestone marker) |
| No `v1.3.0`, no `v1.4.0` tags | — | absent | Phase 44 creates `v1.4.0` |

**Drift diagnosis (assessment 2026-05-27):**

- `PROJECT.md` / milestone roadmaps declare v1.3 and v1.4 **shipped to git**.
- `mix.exs` and manifest still read **1.2.0** — the last successful release-please + Hex cycle.
- `docs/0` `extras:` lists v1.3 guides (`generic_saml.md`, `identity_mapping_and_provisioning.md`, `adfs.md`) and v1.4 guides (`logout.md`, `troubleshooting.md`, `incident_playbook.md`) while Hex **code** for `1.2.0` lacks those implementations — docs/code mismatch on hexdocs.pm.

### Install pin drift

| Location | Current | Target | In Phase 43? |
|----------|---------|--------|--------------|
| `guides/getting_started.md:26` | `{:relyra, "~> 0.1.0"}` | `{:relyra, "~> 1.4"}` | **Yes** (D-03) |
| `README.md` | No version dep example | — | Phase 46 (DX-01) |
| `mix hex.info` suggested config | `~> 1.2` (Hex metadata) | Updates on publish | Phase 44 side effect |

Repo-wide grep confirms **no other** `~> 0.1.0` Relyra pins in tracked source (discussion log verified).

### CHANGELOG gaps

| Section | Status | Notes |
|---------|--------|-------|
| `[1.4.0]` | **Missing** | Must be hand-written; includes single-jump rationale (D-07) |
| `[1.3.0]` | **Missing** | Historical milestone record only — **no Hex release** (D-05, out-of-scope table) |
| `[1.2.0]` | Present (line 8) | Release-please style: `Features` / `Bug Fixes` with commit links — last merged release |
| `[Unreleased]` | Present (line 235), **empty** | **Must remain** — `release_hardening_test.exs` asserts `## [Unreleased]` exists |
| `[0.1.0]` | Present (line 237) | Keep-a-Changelog `Added` format — good structural precedent for backfill categories |

**Structural anomaly:** `[Unreleased]` sits **below** `[1.2.0]`…`[1.0.0]`, not at the top. Keep-a-Changelog convention prefers Unreleased first; this repo's release hardening test only requires presence, not position. Phase 43 inserts `[1.4.0]` and `[1.3.0]` **immediately above** `[1.2.0]` (newest-first among versioned sections) and **does not move** `[Unreleased]` unless a separate hygiene task is explicitly scoped.

**Gap span:** `1.2.0` (2026-05-25, Phases 28–30) → HEAD covers Phases 32–42 (~9 phases). Release-please never merged a PR for this gap — a conventional-commit dump is **explicitly rejected** (D-04).

### Preconditions satisfied (Phase 43 depends on 41 + 42)

| Prerequisite | Status | Why it matters for 1.4.0 tarball |
|--------------|--------|----------------------------------|
| TD-02 test_support exclusion | ✅ Phase 41-02 | Without it, published tarball ships dev modules |
| Login trace LiveView + CLI + security gate | ✅ Phase 42 | Adopter-facing "every login explains itself" ships in 1.4.0 |
| `mix test --warnings-as-errors` | Expected green | D-10 gate |

---

## 2. Exact Files to Modify and Verification Commands

### Files to modify (Phase 43 scope only)

| File | Change |
|------|--------|
| `mix.exs` | `@version "1.4.0"` (line 6); `source_ref` follows automatically |
| `.release-please-manifest.json` | `"."` → `"1.4.0"` |
| `guides/getting_started.md` | Line 26: `{:relyra, "~> 1.4"}` |
| `CHANGELOG.md` | Insert `## [1.4.0]` and `## [1.3.0]` above `## [1.2.0]`; preserve `## [Unreleased]` |

### Files read-only (inform planning; Phase 44 owns edits)

| File | Role |
|------|------|
| `.release-please-config.json` | `release-type: elixir`, `changelog-path: CHANGELOG.md`, `include-v-in-tag: true` |
| `.github/workflows/release-please.yml` | Opens release PR on push to `main`; `publish-hex` gated on `release_created` |
| `.github/workflows/publish-hex.yml` | Manual recovery publish (`workflow_dispatch`) |
| `test/release/release_hardening_test.exs` | Artifact presence + `[Unreleased]` guard |

### Optional (planner discretion — D-10 / CONTEXT discretion)

| File | Purpose |
|------|---------|
| `test/docs/version_pin_drift_test.exs` (new) | Assert `getting_started.md` pin matches `@version` major or `~> 1.4` pattern |
| `mix.exs` `ci.docs` | Wire drift test if added (follow `logout_recipe_drift_test.exs` hollow-gate pattern) |

### Verification commands (run after implementation)

```bash
# Core phase gate (D-10)
mix test --warnings-as-errors

# Release discipline lane (unchanged expectations post-bump)
mix ci.release

# Version coherence — manual grep checks (acceptance criteria)
grep -n '@version "1.4.0"' mix.exs
grep '"1.4.0"' .release-please-manifest.json
grep '~> 1.4' guides/getting_started.md
grep -n '## \[1.3.0\]' CHANGELOG.md
grep -n '## \[1.4.0\]' CHANGELOG.md
grep '## \[Unreleased\]' CHANGELOG.md

# Confirm no stale 1.2.0 in version sources (should only hit CHANGELOG history / docs advisories)
rg '@version "1\.2\.0"' mix.exs .release-please-manifest.json
rg '~> 0\.1\.0' guides/

# ExDoc source_ref derives correctly
mix help docs 2>/dev/null || true
# Or: elixir -e 'Code.require_file("mix.exs"); v = Relyra.MixProject.project()[:version]; IO.puts("v#{v}")'

# Full QA (recommended before Phase 44, not strictly Phase 43 unless planner adds)
mix qa
mix format --check-formatted
```

**Explicitly do NOT run in Phase 43:**

```bash
mix hex.publish          # CLAUDE.md forbids manual publish
git tag v1.4.0           # Phase 44
```

---

## 3. CHANGELOG Backfill Content Outline

Backfill sections use **Keep a Changelog** headings (`### Added`, `### Changed`, `### Security`) with **narrative milestone bullets** — not release-please commit links (D-04). Security items must be prominent where material (CONTEXT specifics).

Insert order (newest first among versioned sections):

```
[intro paragraphs — unchanged]

## [1.4.0]                    ← NEW (with jump rationale paragraph first)
### Added / Changed / Security

## [1.3.0]                    ← NEW (historical — no Hex release)
### Added / Changed / Security

## [1.2.0]                    ← existing
...
## [Unreleased]               ← preserve (empty OK)
## [0.1.0]
```

### `[1.3.0]` — Advanced Federation (Phases 32–37)

**Scope:** ENC-01, ENC-02, AUTHN-01, DOCS-02, DOCS-03 per `v1.3-ROADMAP.md` and PUB-02.

#### Added (outline)

- **Encrypted assertions (ENC-01/02):** `KeyResolver` behaviour + `KeyResolver.Default` (SP private key from app config only); `Relyra.Security.XMLEnc.decrypt/3` with RSA-OAEP + AES-GCM behind `AlgorithmPolicy`; decrypt-then-reparse pipeline stage in `ValidationPipeline` (`:decrypt_assertion` pre-stage); cleartext+encrypted ambiguity guard (`:ambiguous_assertion` before crypto); SP metadata encryption `KeyDescriptor`; 7-fixture ENC-01 adversarial corpus in `mix ci.security`.
- **Signed AuthnRequests (AUTHN-01):** HTTP-Redirect query signing (`sign_redirect_query/3` raw-octet invariant); `sign_authn_requests` connection toggle; SP metadata `AuthnRequestsSigned` + signing `KeyDescriptor`; ADFS provider preset + `guides/recipes/adfs.md`; 5-fixture AUTHN-01 adversarial corpus in `mix ci.security`.
- **AlgorithmPolicy + schema (ENC-03/04, AUTHN-02):** Key-transport and content-encryption enforcement; RSA-PKCS1v1.5 blocked; AES-CBC blocked by default with time-boxed escape hatch; GCM auth-tag length guard; cert `party`/`use` columns; `sign_authn_requests` migration.
- **Documentation (DOCS-02):** `guides/recipes/generic_saml.md` — SP/IdP metadata reference, decoder tables for IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, CA SiteMinder; ADFS/Shibboleth subsections; security checklist, debugging flow, cert rotation.
- **Documentation (DOCS-03):** `guides/identity_mapping_and_provisioning.md` — NameID vs attribute mapping patterns, JIT decision tree, `UserMapper` examples, SCIM non-goal.

#### Changed (outline)

- `PureBeam.build_parsed_doc/1` tolerates encrypted-only Responses pre-decrypt (`encrypted_pending` path) without weakening cleartext gates.
- SP metadata build order: signing + encryption `KeyDescriptor`s before ACS (schema-valid).

#### Security (outline)

- **Decrypt-then-reparse invariant:** decrypted bytes MUST pass `PureBeam.parse_safely/2` AND `Signature.do_verify/4` before identity fields — CVE-2025-54419 class read-before-verify rejected by adversarial corpus.
- **Single opaque `:decryption_failed`** for all decryption failure modes (no padding oracle via distinct atoms).
- **Document `KeyInfo` ignored** for decryption key material — configured `KeyResolver` only (CLAUDE.md invariant #1 preserved for ENC path).
- **Ambiguity guard:** cleartext + encrypted assertion → `:ambiguous_assertion` pre-crypto (CVE-2026-2092 class).
- **Redirect AuthnRequest signing:** golden corpus enforces no re-serialization before sign; ADFS `+`-encoding variant covered.
- **AlgorithmPolicy:** RSA-OAEP SHA-256 URI blocked pending OTP support; zero new Hex deps for XML-Enc (OTP stdlib only).

### `[1.4.0]` — Full SLO + ops polish + v1.5 pre-publish work (Phases 38–42)

**Opening paragraph (required — D-07):**

> Document that Hex publishes **1.4.0** directly from **1.2.0** with no intermediate **1.3.0** Hex release. Rationale: adopter clarity — one install line `{:relyra, "~> 1.4"}` receives Advanced Federation + SLO + trace UI. The `[1.3.0]` section below is **changelog archaeology** for the v1.3 milestone, not a skipped Hex version adopters must hunt for.

**Scope:** SLO-01, DOCS-04/05/06 (Phases 38–40.1) **plus** Phase 41 hygiene and Phase 42 trace (already in tree before publish — D-06).

#### Added (outline)

**v1.4 milestone (38–40.1):**

- **Single Logout (SLO-01):** `SessionAdapter.index_session/4` + `terminate_by_session_index/4`; SP- and IdP-initiated logout via `Relyra.consume_logout/3`; HTTP-Redirect + HTTP-POST bindings; strict logout validation pipeline (`Parse → Verify → Replay → Execute` / redirect variant); `LogoutRequest`/`LogoutResponse` on `SaxyTree` (single parse path).
- **Documentation (DOCS-04):** `guides/recipes/logout.md` — ITP/ETP/Privacy Sandbox caveats, durable session prerequisite, absolute-timeout boundary, IdP-polling anti-pattern; host-owned session-index linkage (Section 3.1).
- **Documentation (DOCS-05):** `guides/operations/incident_playbook.md` — six Triage→Diagnose→Recover scenarios; five-surface operator stitching.
- **Documentation (DOCS-06):** `guides/troubleshooting.md` Error Atom Decoder (78 atoms, 7 buckets); bidirectional drift test in `ci.docs`.
- **Audit closure (40.1):** `logout_recipe_drift_test.exs` AST arity gate; retroactive `38-VERIFICATION.md` / `39-VERIFICATION.md`.

**v1.5 pre-publish (41–42 — ships inside 1.4.0 tarball):**

- **Login trace UI (TRACE-01):** `ConnectionTraceLive` at `/connections/:connection_id/trace`; six-step expandable rows from audit + telemetry.
- **Headless trace (TRACE-03):** `mix relyra.trace --repo --connection [--last N]`.
- **Shared export:** `Relyra.LoginTrace.Export` redaction path shared by LiveView and CLI.
- **Pre-publish hygiene (TD-01..05):** metadata attribute escaping (`AttributeEscape` + security corpus); `test_support` excluded from prod compile and Hex `package.files`; parse-tree byte spans for encrypted assertion wire extraction (regex retired); README/doc preset honesty; adversarial crypto test formatting.

#### Changed (outline)

- Trust audit timeline excludes `domain: :login` rows (login traces separate from trust mutations).
- `LoginResult.validation_trace` populated on successful consume via `LoginTrace` telemetry handler.
- Production `elixirc_paths` uses explicit lib file list (excludes `test_support`).

#### Security (outline)

- **Logout crypto:** XMLDSig verification before session termination; redirect signatures verified against raw query octets (mirror of AuthnRequest invariant); replay protection on logout messages.
- **Login trace redaction (TRACE-02):** `test/security/login_trace_test.exs` — LiveView and CLI never render raw XML, PEM, cert bodies, signature values, or key material; wired as dedicated `cmd mix test` in `ci.security`.
- **Metadata XSS defense-in-depth (TD-01):** interpolated SP metadata attributes XML-escaped (`metadata_attribute_injection_test.exs`).
- **One trust path (TD-03):** `locate_encrypted_assertion` uses parse-tree byte spans only — no regex alongside tree.

---

## 4. Release-Please Integration Notes

### What Phase 43 stages

| Artifact | Phase 43 action | Consumed by |
|----------|-----------------|-------------|
| `mix.exs` `@version` | Set `1.4.0` | Release Please PR body, Hex publish grep check |
| `.release-please-manifest.json` | Set `1.4.0` | Release Please next-release calculation |
| `CHANGELOG.md` | Hand backfill `[1.3.0]` + `[1.4.0]` | Release PR changelog section; adopters |
| `guides/getting_started.md` pin | `~> 1.4` | Adopter install docs |

Commit packaging: **single release-prep commit or one PR batch** (D-09) so automation sees coherent state.

### What Phase 44 owns (do not plan in Phase 43)

| Item | Requirement | Notes |
|------|-------------|-------|
| Diagnose stalled pipeline | PUB-03 | Release PR never merged after v1.2.0; write `RELEASE-PLEASE-DIAGNOSIS.md` |
| Open/merge release-please PR | PUB-03 | May need token, branch, or manifest reconciliation fixes |
| Create `v1.4.0` git tag | PUB-01 (tag portion) | Distinct from existing `v1.4`; `include-v-in-tag: true` |
| `mix hex.publish` via CI | PUB-03 | `release-please.yml` `publish-hex` job; **never manual** |
| Post-publish parity | PUB-04 | Phase 45 |

### Release-please workflow behavior (read-only reference)

On push to `main`, `googleapis/release-please-action@v4` reads manifest + config:

1. Compares manifest version to conventional commits since last release.
2. Opens/updates a Release Please PR bumping version + CHANGELOG.
3. On merge, sets `release_created=true`, creates tag, triggers `publish-hex`.

**Publish job checks (Phase 44 must pass):**

```yaml
grep -n "@version \"${{ needs.release-please.outputs.version }}\"" mix.exs
mix ci.release
mix ci.security
mix hex.publish --dry-run --yes
mix hex.publish --yes   # if not already on Hex
```

**Manual manifest jump to `1.4.0`:** Because Phase 43 sets manifest to final target **before** Phase 44, release-please should treat `1.4.0` as the next release baseline. Risk: if Phase 43 lands on `main` without merging an open stale release PR, Phase 44 diagnosis must reconcile duplicate/conflicting PRs (document in diagnosis artifact).

**Recovery path:** `.github/workflows/publish-hex.yml` supports `workflow_dispatch` with tag + expected version — fallback if automation fails after tag exists.

### PUB-01 split across phases

| PUB-01 criterion | Phase |
|------------------|-------|
| `@version` → `1.4.0` | **43** |
| `getting_started.md` → `~> 1.4` | **43** |
| Single-jump rationale in CHANGELOG | **43** (`[1.4.0]` header) |
| SemVer `v1.4.0` git tag exists | **44** |

Planner should mark PUB-01 **partially complete** after Phase 43; full closure requires Phase 44 tag.

---

## 5. Pitfalls

| Pitfall | Impact | Mitigation |
|---------|--------|------------|
| **Creating `v1.4.0` tag in Phase 43** | Scope creep; publish job may fire on wrong commit | Explicit deferral to Phase 44 (D-02); no `git tag` in plans |
| **Manual `mix hex.publish`** | Violates OSS discipline | CLAUDE.md + PROJECT.md; CI-only publish |
| **Removing or renaming `[Unreleased]`** | `mix ci.release` fails | Keep empty section at line ~235 (or anywhere file — test is substring match) |
| **Manifest / mix.exs mismatch** | Publish grep step fails | Change both in same commit; verify with paired grep |
| **Only bumping mix.exs, not manifest** | Release-please proposes wrong version | Always pair per D-01 |
| **Release-please conventional-commit dump for gap** | Unreviewable CHANGELOG; wrong format | Hand-write from milestone roadmaps (D-04) |
| **Treating `[1.3.0]` as a Hex release** | Adopter confusion | Jump rationale at top of `[1.4.0]` (D-07) |
| **Inserting sections below `[1.2.0]`** | Violates newest-first + success criteria | Insert **above** `[1.2.0]` (D-08) |
| **Stale `~> 0.1.0` left elsewhere** | Future drift | Grep gate; optional `version_pin_drift_test.exs` |
| **Editing `[1.2.0]` release-please section** | Rewrites shipped history | Append-only above existing sections |
| **Expecting release-please to backfill 1.3/1.4** | Gap never merged; automation won't reconstruct milestone narratives | Phase 43 manual backfill |
| **Open release PR from pre-43 state** | Version conflict when 43 lands | Phase 44 diagnosis must close/rebase stale PR |
| **Non-SemVer `v1.4` tag confusion** | Hex rejects or wrong anchor | Phase 44 creates proper `v1.4.0`; document in diagnosis |
| **hexdocs `source_ref` before tag exists** | Broken GitHub links until tag cut | Acceptable during 43→44 window; links live after Phase 44 |
| **Adding version literal tests for `1.2.0`** | Brittle | Use `Mix.Project.config()[:version]` if drift tests added |

---

## 6. Validation Architecture

> Nyquist dimension-8 contract: every plan task needs grep-able acceptance criteria and a verification command.

### Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Phase gate** | `mix test --warnings-as-errors` (D-10) |
| **Release lane** | `mix ci.release` → `test/release/release_hardening_test.exs` |
| **Full QA** | `mix qa` (format + compile + test) |
| **Estimated runtime** | ~2–5 min full suite; `<1s` release hardening |

### Per-requirement verification map

| Requirement | Acceptance pattern | Automated command | File / guard |
|-------------|-------------------|-------------------|--------------|
| PUB-01 `@version` | `grep '@version "1.4.0"' mix.exs` exits 0 | `mix test --warnings-as-errors` | `mix.exs:6` |
| PUB-01 manifest | `grep '"1.4.0"' .release-please-manifest.json` | same | `.release-please-manifest.json` |
| PUB-01 install pin | `grep '~> 1.4' guides/getting_started.md` | same | `guides/getting_started.md:26` |
| PUB-01 tag | `git tag -l v1.4.0` non-empty | **Phase 44** | defer |
| PUB-02 `[1.3.0]` | `grep '## \[1.3.0\]' CHANGELOG.md` + Added/Changed/Security headings | `mix ci.release` | `CHANGELOG.md` |
| PUB-02 `[1.4.0]` | `grep '## \[1.4.0\]' CHANGELOG.md` + jump rationale text | `mix ci.release` | `CHANGELOG.md` |
| PUB-02 format | Milestone keywords: ENC-01, AUTHN-01, SLO-01, DOCS-02..06, login trace | manual / `rg` in plan verify | `CHANGELOG.md` bullets |
| Unreleased guard | `grep '## \[Unreleased\]' CHANGELOG.md` | `mix test test/release/release_hardening_test.exs` | existing test line 44–48 |
| No stale version sources | `rg '@version "1\.2\.0"' mix.exs .release-please-manifest.json` → no matches | plan verify step | grep |
| ExDoc source_ref | `@version` drives `source_ref: "v#{@version}"` | read `mix.exs` docs/0 | derived |
| Optional pin drift | pin major matches project major | `mix test test/docs/version_pin_drift_test.exs` | if planner adds |

### Drift guards (existing — must stay green)

| Guard | Command |
|-------|---------|
| Release artifacts | `mix ci.release` |
| `[Unreleased]` present | `release_hardening_test.exs` |
| Keep a Changelog header | `release_hardening_test.exs` |
| Release-please workflow wired | `release_hardening_test.exs` |
| CI security hollow-gate | `mix ci.security` (unchanged by 43 unless optional test added) |

### Wave gates (recommended)

| Wave | Gate command | Must pass before |
|------|--------------|------------------|
| Post-commit | `mix test test/release/release_hardening_test.exs --warnings-as-errors` | declaring plan done |
| Phase verify | `mix test --warnings-as-errors` | `/gsd-verify-work` |
| Pre-Phase-44 | `mix qa` + version grep checklist | handoff to Phase 44 |

### Nyquist notes

- Phase 43 is **docs + metadata** heavy; automated proof is primarily **grep + release_hardening + full test suite**, not new feature tests.
- PUB-02 prose quality is **human-verified** during `/gsd-verify-work` (milestone keyword checklist).
- Do not mark PUB-01 complete until Phase 44 tag exists — track partial satisfaction in VERIFICATION.md.

---

## 7. Recommended Plan Split

Phase 43 is small, cohesive, and D-09 requests a **single release-prep batch**. Two planning options:

### Option A — Single plan (recommended default)

| Plan | Wave | Scope | Commit |
|------|------|-------|--------|
| **43-01** | 1 | `mix.exs` + manifest + pin + CHANGELOG backfill | 1 atomic `chore(release): prep v1.4.0` (or `feat` if project prefers) |

**Rationale:** All four files are one logical "stage for release-please" unit; splitting creates merge ordering noise without parallelization benefit.

### Option B — Two plans (if CHANGELOG review wants isolation)

| Plan | Wave | Scope | Depends |
|------|------|-------|---------|
| **43-01** | 1 | Version trifecta: `mix.exs`, manifest, `getting_started.md` pin | — |
| **43-02** | 2 | CHANGELOG `[1.4.0]` + `[1.3.0]` backfill | 43-01 (version context for jump rationale) |

**Still land in one PR** per D-09 even with two plan commits.

### Optional Plan 03 — Drift guard (low priority)

| Plan | Wave | Scope |
|------|------|-------|
| **43-03** | 3 (optional) | `test/docs/version_pin_drift_test.exs` + optional `ci.docs` wire |

Only if planner wants regression prevention beyond grep-at-verify time; not required by CONTEXT.

### Plan count recommendation

**1 plan (43-01)** for execution; **2 plans** if the maintainer wants CHANGELOG prose in a separate review commit; **+1 optional** for pin drift test.

---

## RESEARCH COMPLETE
