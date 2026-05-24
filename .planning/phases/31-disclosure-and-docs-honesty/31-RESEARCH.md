# Phase 31: Disclosure and docs honesty - Research

**Researched:** 2026-05-24
**Domain:** Coordinated security disclosure (GHSA / CVE / CVSS / CWE) + doc honesty + release-please CHANGELOG mechanics for an Elixir/hex SAML library
**Confidence:** HIGH (release-please mechanics, GHSA form, CWE, doc-gate); HIGH (CVSS — anchored to a near-identical NVD-scored precedent)

## Summary

Phase 31 is a documentation-and-disclosure phase. The crypto fix (real XMLDSig
signature verification closing a SAML authentication bypass) is already complete and
verified on this branch (Phases 28–30); **no `lib/` security code changes here**. The
phase has two requirements: DISC-01 (correct three security docs + add one Critical
findings-ledger row) and DISC-02 (stage — not publish — one checked-in advisory draft
containing a GHSA body, a CVE-request subsection, and the exact CHANGELOG security-note
prose). DISC-01 is fully specified by CONTEXT.md decisions D-01..D-11; the real research
value is the advisory artifact (DISC-02), which CONTEXT.md leaves to discretion.

The disclosure domain is well-trodden: the GitHub repository-security-advisory form has a
fixed, documented field set, and there is a near-identical, recently-scored precedent —
**ruby-saml CVE-2025-25292** (SAML authentication bypass via a signature-verification
flaw in a library), which NVD scored **CVSS:3.1 9.8 Critical** under
**CWE-347 (Improper Verification of Cryptographic Signature)**. Relyra's vulnerability is
the same class (forged `SignatureValue` carrying an attacker-controlled `NameID` accepted
as `{:ok}` = full SP authentication bypass), so the advisory can be drafted with high
confidence by mirroring that precedent's framing, CVSS metrics, and CWE.

The one place a *process* fact could trip the plan is D-08 (CHANGELOG). Relyra uses
**release-please with `release-type: "elixir"`** and the default
`conventional-changelog-conventionalcommits` preset. Under that preset **only `feat:`
(→ "Features") and `fix:` (→ "Bug Fixes") produce changelog sections by default; there is
NO built-in "security" section**, and `docs/chore/test/ci/refactor/style/perf/build` are
hidden. This means a staged "security note" only renders at release if the fix commit
already exists as a recognized type (it does: the fix landed as `fix(29-…)` / `feat(29-…)`
commits) — the advisory draft holds the *canonical note text*, but D-08 is correct that
hand-editing the generated `CHANGELOG.md` would be clobbered. There is one nuance the plan
must surface (see Common Pitfall 1).

**Primary recommendation:** Stage one checked-in draft at
`docs/advisories/2026-001-xmldsig-signature-not-verified.md` structured to map 1:1 onto the
GitHub repository-advisory form (Summary, Severity/CVSS, Affected Products, Weaknesses/CWE,
Description with Impact + Workarounds + References + Credits, plus a "CVE request" and a
"CHANGELOG security note" subsection). Use **CWE-347** and a Critical CVSS 3.1 vector that
mirrors the ruby-saml precedent. Correct the three named docs to the precise post-fix
primitive (D-01). Replace the `none yet` ledger row with one Critical finding (D-04). Keep
all three `ci.security` doc-gate checks green and do not touch the two generated files.

## Architectural Responsibility Map

This is a docs-only phase; "tiers" here are document/artifact roles, not runtime layers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Forward-looking guarantee description | Hand-maintained reviewer docs (`docs/security_boundary.md`, `SECURITY_REVIEW.md`) | — | These are author-owned prose; honesty corrections belong here (D-02). |
| Historical-gap record + disposition | Findings ledger (`docs/security_findings.md`) | — | Captured ONCE in the ledger, not scattered (D-02/D-04). |
| Coordinated outward advisory | Checked-in draft (`docs/advisories/2026-001-…md`) | GitHub GHSA form / CVE / GitHub Release (ship-time) | Phase 31 stages text; publication is a ship-time hand-off (D-09). |
| Release CHANGELOG note | release-please generated `CHANGELOG.md` (do NOT hand-edit) | conventional-commit footers on the fix commit | Generated artifact; canonical note text lives in the draft (D-08). |
| Executable security evidence | Generated `SECURITY_REVIEW_EVIDENCE.md` (do NOT hand-edit) | `lib/mix/tasks/relyra.security_review.ex` | Drift-checked by `--check`; change only via the generator (D-11). |
| Doc-gate enforcement | `mix ci.security` doc-check steps in `mix.exs` | — | File-existence + cross-ref-grep + generator drift-check (D-10/D-11). |

## Standard Stack

No packages are installed in this phase. **`## Package Legitimacy Audit` is intentionally
omitted** — Phase 31 adds zero dependencies (docs-only). The relevant "stack" is the
disclosure framework / external standards the advisory draft references:

### Disclosure standards referenced (not installed)
| Standard | Version | Purpose | Why standard |
|----------|---------|---------|--------------|
| GitHub Security Advisory (GHSA) | repo-level advisory form (current) | The publish target the draft maps to; supports CVSS 3.1 + 4.0, CWE, affected/patched ranges, "Request CVE" | GitHub is a CNA; GHSA → CVE is the standard path for OSS libraries [CITED: docs.github.com creating-a-repository-security-advisory] |
| CVE (via GitHub CNA) | — | Public, citable vulnerability id | GHSA "Request CVE" is the documented assignment flow for repo advisories [CITED: docs.github.com] |
| CVSS | 3.1 (primary) + 4.0 (optional) | Severity scoring; GHSA form computes from the calculator | GitHub Advisory Database supports both 3.1 and 4.0 [CITED: docs.github.com about-the-github-advisory-database] |
| CWE | MITRE current | Weakness classification — CWE-347 here | GHSA requires ≥1 CWE; NVD curates one per vuln [CITED: docs.github.com] |
| release-please | action `@v4`, `release-type: elixir` | Generates `CHANGELOG.md` from conventional commits at release | Already wired in `.github/workflows/release-please.yml` [VERIFIED: repo] |
| conventional-changelog-conventionalcommits | preset bundled with release-please | Defines which commit types surface as CHANGELOG sections | The default preset release-please's `default` changelog-notes builder calls [CITED: github.com/googleapis/release-please customizing.md] |

## Architecture Patterns

### Artifact Flow Diagram

```
                         Phase 31 (this phase — STAGE only)
                         ────────────────────────────────────
  CONTEXT.md D-01..D-11 ─┐
                         │
  Phase 29/30 proofs ────┤   (corpus + anti-hollow gate = regression evidence)
   - adversarial_crypto  │
   - ci_gate_integrity   │
                         ▼
        ┌──────────────────────────────────────────────────────────┐
        │ DISC-01: correct 3 hand-maintained docs (precise primitive)│
        │   docs/security_boundary.md  (line 8 + Trust Seams row)    │
        │   SECURITY_REVIEW.md         (Named Code Seams row)        │
        │   docs/security_findings.md  (none-yet → 1 Critical row)   │──┐
        └──────────────────────────────────────────────────────────┘  │
                         │                                              │ cross-ref
                         ▼                                              │ id RELYRA-2026-001
        ┌──────────────────────────────────────────────────────────┐  │
        │ DISC-02: ONE checked-in draft                              │◄─┘
        │   docs/advisories/2026-001-xmldsig-signature-not-verified.md│
        │   ├─ GHSA body (summary/severity/affected/patched/impact/  │
        │   │   workaround/credits/references/CWE/CVSS)              │
        │   ├─ "CVE request" subsection (pre-staged form fields)     │
        │   └─ exact CHANGELOG security-note prose                   │
        └──────────────────────────────────────────────────────────┘
                         │
                         ▼   (must stay green throughout)
        ┌──────────────────────────────────────────────────────────┐
        │ mix ci.security doc-gate:                                  │
        │   cmd test -f SECURITY_REVIEW.md                           │
        │   cmd test -f docs/security_boundary.md                    │
        │   cmd grep -nE "docs/security_findings.md|Findings Ledger" │
        │            SECURITY_REVIEW.md                              │
        │   relyra.security_review --check  (generated-evidence drift)│
        └──────────────────────────────────────────────────────────┘

                         ══════ SHIP-TIME (NOT this phase, D-09) ══════
   merge branch → release-please cuts 1.2.0 → CHANGELOG.md regenerated from commits
   → file GHSA (paste draft) → Request CVE → publish GitHub Release / note
```

### Pattern 1: Draft mirrors the GitHub repository-advisory form 1:1
**What:** Structure the markdown draft so each section maps to a GHSA form field, so the
ship-time step is copy/paste, not re-derivation.
**When to use:** Always — this is the whole point of staging.
**GHSA form fields (in order, current GitHub UI)** [CITED: docs.github.com creating-a-repository-security-advisory]:

| GHSA form field | Required | Draft section | Relyra value |
|-----------------|----------|---------------|--------------|
| Title | Required | H1 / Summary | "Relyra SAML SignatureValue not cryptographically verified → authentication bypass" |
| CVE identifier | Required (choose: have one / request later) | "CVE request" subsection | Request later → placeholder `RELYRA-2026-001` |
| Description | Required | Body: Summary, Impact, Patches, Workarounds, References | full prose |
| Affected products | Required | Affected Products table | ecosystem `Erlang` (hex), package `relyra` |
| └ ecosystem | — | — | `Erlang` (GitHub's hex ecosystem label) `[ASSUMED]` (verify dropdown label at file time) |
| └ package name | — | — | `relyra` |
| └ affected versions | — | — | `>= 1.0.0, < 1.2.0` (covers 1.0.0 and 1.1.0) |
| └ patched versions | — | — | `1.2.0` |
| Severity | Required | Severity / CVSS section | Critical — CVSS 3.1 vector (below) |
| Weaknesses (CWE) | Optional | Weaknesses section | CWE-347 (primary); CWE-287 companion |
| Credits | Optional | Credits section | maintainers (Finder/Reporter) |

### Pattern 2: GHSA body section order (matches real SAML advisories)
**What:** The de-facto GHSA body structure used by comparable SAML advisories.
**Source:** ruby-saml GHSA-9v8j-x534-2fx3 and samlify GHSA-r683-v43c-6xqv both use a
Summary → Details → Impact → Patches → Workarounds → References shape (samlify's public
display collapsed some, but the editor template offers all)
[CITED: github.com/SAML-Toolkits/ruby-saml advisory; github.com/advisories/GHSA-r683-v43c-6xqv].

Recommended draft body sections:
1. **Summary** — one sentence: what is broken and the effect (auth bypass).
2. **Details** — the exact primitive that was missing in 1.0.0/1.1.0: `:public_key.verify`
   over canonicalized `SignedInfo` was not performed; `DigestValue` was not recomputed;
   `canonicalize/2` was an unused passthrough. Name the trust boundary.
3. **Impact** — a forged `SignatureValue` carrying an attacker-controlled `NameID` is
   accepted as `{:ok}`; any relying-party app using Relyra 1.0.0/1.1.0 can be logged into
   as an arbitrary user. (Brand voice: state the fact plainly; no "catastrophic"/marketing.)
4. **Patches** — fixed in hex `1.2.0` (real exclusive-C14N + `:public_key.verify` +
   constant-time `DigestValue` recompute on both `verify/4` and `verify_metadata_root/4`).
5. **Workarounds** — none other than upgrade (D-07: "workaround = upgrade"). Be honest:
   there is no safe configuration of 1.0.0/1.1.0.
6. **References** — link the fix commits, the adversarial corpus, the anti-hollow gate, and
   (optionally, D-discretion) the Phase 29/30 SECURITY.md threat verifications.
7. **Credits** — maintainers.

### Pattern 3: Findings-ledger row shape (preserve the existing table columns)
**What:** The ledger table already has fixed columns; the new row must match exactly so the
markdown table stays valid and the cross-reference grep keeps matching.
**Existing columns** [VERIFIED: repo `docs/security_findings.md` line 14]:
`Finding ID | Severity | Exploit Path | Disposition | Owner | Regression Proof | Blocker State | Revisit Date`

Recommended row (from D-04/D-05/D-06):
- **Finding ID:** `RELYRA-2026-001` (note: GHSA/CVE attach at publish)
- **Severity:** Critical
- **Exploit Path:** forged `SignatureValue` + attacker-controlled `NameID` accepted as `{:ok}` → full SAML authentication bypass
- **Disposition:** Confirmed → Fixed in v1.1 (hex `1.2.0`)
- **Owner:** maintainers
- **Regression Proof:** `test/security/xml/adversarial_crypto_test.exs` (`:adversarial_crypto`) + `test/security/ci_gate_integrity_test.exs`, green under `mix ci.security`
- **Blocker State:** resolved
- **Revisit Date:** at v1.2.0 ship / GHSA publish

> Note: also update the prose at `docs/security_findings.md` line 3 ("Current state: no
> external findings recorded yet.") so it no longer contradicts the new row.

### Anti-Patterns to Avoid
- **Hand-editing `CHANGELOG.md`** — release-please regenerates it; manual blocks are clobbered (D-08).
- **Hand-editing `SECURITY_REVIEW_EVIDENCE.md`** — `relyra.security_review --check` fails on drift; change the generator instead (D-11).
- **Scattering historical caveats across every doc** — capture the historical gap ONCE in the ledger (D-02).
- **Editing `SECURITY.md`** — line 18 is already true post-fix; out of scope (D-03).
- **Marketing absolutes** — never "bulletproof"/"unhackable"/"military-grade" (PROJECT.md brand; locked).
- **Removing the findings-ledger cross-reference string from `SECURITY_REVIEW.md`** — breaks the `ci.security` grep step (D-10).
- **Publishing now** — no `gh` GHSA file, no CVE request, no Release; ship-time only (D-09).

## CVSS 3.1 Vector (for the advisory)

CONTEXT.md (D-05) locks **Critical**; the CVSS vector/score is researcher/planner
discretion. The strongest anchor is the near-identical recently-scored precedent.

**Precedent anchor — ruby-saml CVE-2025-25292** (SAML auth bypass, same library class,
CWE-347): NVD assigned **`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` = 9.8 Critical**
[CITED: nvd.nist.gov/vuln/detail/CVE-2025-25292]. samlify CVE-2025-47949 (signature
wrapping, CWE-347) scored **CVSS 4.0 9.9 Critical** [CITED: github.com/advisories/GHSA-r683-v43c-6xqv].

**Recommended Relyra vector — CVSS 3.1:**
`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` → **Base 9.1, Critical**

Per-metric justification:
| Metric | Value | Justification |
|--------|-------|---------------|
| **AV** Attack Vector | **N** (Network) | The forged SAML Response arrives over the network (HTTP-POST/Redirect binding) at the SP ACS. |
| **AC** Attack Complexity | **L** (Low) | No special conditions; an attacker who can craft a SAML Response (no valid key needed) succeeds deterministically — verification never ran. |
| **PR** Privileges Required | **N** (None) | The attacker needs no account or privilege on the target; they forge the assertion. |
| **UI** User Interaction | **N** (None) | Auth-bypass requires no victim action (IdP-initiated / direct POST to ACS). |
| **S** Scope | **U** (Unchanged) | **Mirrors the ruby-saml NVD scoring.** The vulnerable component (Relyra) and the impacted authority (the relying-party app's authn decision) are the same security authority — the library *is* the authn gate. (A defensible Critical results either way; see note below.) |
| **C** Confidentiality | **H** (High) | Logging in as an arbitrary user fully discloses that user's data within the app. |
| **I** Integrity | **H** (High) | The attacker acts as any user — full integrity impact on that user's actions/state. |
| **A** Availability | **N** (None) | No direct availability impact from the bypass itself. |

**Scope decision (the only judgment call):**
- **`S:U` (recommended)** → **9.1 Critical**. Matches how NVD scored the directly-analogous
  ruby-saml auth-bypass; defensible and conservative; the library and the protected resource
  are the same authority. This is the recommended choice for credibility (a reviewer can
  diff it against CVE-2025-25292).
- **`S:C`** (arguable, since a *library* compromise impacts the *consuming app*) →
  `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:N` computes to **10.0 Critical**. Valid
  reasoning (the vulnerable component is the SAML library; the impacted component is the host
  application's session/identity), but scoring a library auth-bypass at a flat 10.0 reads as
  aggressive and diverges from the NVD precedent. **Avoid unless deliberately justified.**

Either way the rating is **Critical**, confirming D-05. **Recommendation: `S:U` → 9.1
Critical** as the primary, with a one-line note that a `S:C` reading would reach 10.0.

**Optional CVSS 4.0 (GHSA also accepts 4.0):** mirror ruby-saml's
`CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N` (9.3 Critical) — optional,
not required; 3.1 is sufficient for the staged draft.

> Calculation note: the 9.1 figure for `S:U/.../A:N` follows the FIRST.org CVSS 3.1 base
> formula (ISC base from C:H,I:H,A:N → Impact 5.873 unchanged-scope; Exploitability 3.887;
> base = roundUp(min(Impact+Exploit, 10)) = 9.1). [VERIFIED: first.org/cvss/v3-1 formula]

## CWE Classification

**Primary: CWE-347 — Improper Verification of Cryptographic Signature** [CITED: NVD
CVE-2025-25292; NVD CVE-2025-47949; cwe.mitre.org/data/definitions/347]. This is the exact,
standard classification for "the cryptographic signature of data is not verified or
incorrectly verified," which is precisely Relyra 1.0.0/1.1.0 (`:public_key.verify` never
ran; `DigestValue` never recomputed). Every comparable recent SAML library advisory uses
CWE-347 (ruby-saml CVE-2025-25292, samlify CVE-2025-47949, Zscaler CVE-2025-54982).

**Companion (optional, strengthens the framing): CWE-287 — Improper Authentication**
(the user-facing effect is an authentication bypass). ruby-saml's NVD entry pairs CWE-347
with CWE-436 (Interpretation Conflict) because its specific root cause was a *parser
differential* — Relyra's root cause is NOT a parser differential (it was a total absence of
the verify step), so **CWE-436 does not apply here**; use CWE-347 (+ optionally CWE-287),
not CWE-436. [VERIFIED: NVD CVE-2025-25292 CWE list vs Relyra root cause in REQUIREMENTS.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Severity scoring | A bespoke "critical-ish" label | CVSS 3.1 vector mirroring CVE-2025-25292 | Reviewers expect a vector string; ad-hoc severity is not citable. |
| Weakness taxonomy | A prose "signature not checked" label | CWE-347 | Standard, machine-indexable, matches every peer advisory. |
| Advisory body shape | A free-form security memo | The GHSA form field order (Pattern 1) | Ship-time becomes paste, not rewrite. |
| CHANGELOG security note | A hand-edited `## [Unreleased]` block | conventional-commit footers + canonical text in the draft | release-please clobbers manual edits (D-08). |
| Evidence-table edits | Editing `SECURITY_REVIEW_EVIDENCE.md` | The `relyra.security_review` generator | `--check` enforces drift-freedom (D-11). |

**Key insight:** The entire value of this phase is *credibility through convention* —
using the standard disclosure primitives (GHSA fields, CVSS vector, CWE-347) so the staged
draft reads like a real, citable advisory and pastes cleanly into GitHub's form at ship time.

## Common Pitfalls

### Pitfall 1: Assuming a "security" CHANGELOG section will appear automatically
**What goes wrong:** Planner assumes the staged security note text will surface verbatim in
the release-please CHANGELOG via some "security" footer/section.
**Why it happens:** Many changelog tools (e.g. Keep a Changelog) have a "Security" heading;
release-please's default preset does **not**.
**The fact:** Relyra uses `release-type: "elixir"` with the default
`conventional-changelog-conventionalcommits` preset. By default **only `feat:` → "Features"
and `fix:` → "Bug Fixes" render**; `chore/docs/style/refactor/perf/test/build/ci` are
`hidden: true`; **there is no `security` type/section** [CITED: github.com/googleapis/release-please
customizing.md; conventionalcommits preset defaults]. The Relyra CHANGELOG confirms this —
it has only "Features" and "Bug Fixes" sections [VERIFIED: repo CHANGELOG.md].
**How to avoid:** The advisory draft holds the *canonical* security-note prose (D-07). At
ship time the note surfaces in the release because **the fix already landed as recognized
`fix(...)`/`feat(...)` commits** (e.g. `feat(29-03): wire real XMLDSig crypto into the
[candidate] arm (D-01)`, `2e45689`) [VERIFIED: git log] — those WILL appear in the 1.2.0
"Features"/"Bug Fixes" sections. D-08 is therefore correct: do not hand-edit `CHANGELOG.md`.
The plan should state plainly that the rendered CHANGELOG entry will be the conventional
"Features/Bug Fixes" lines for the fix commits, and the human-readable security-note prose
lives in the advisory draft + the GitHub Release notes (added at publish), **not** as a
separate generated CHANGELOG "Security" section.
**Warning sign:** A task that says "add a Security section to CHANGELOG.md" — that would be
clobbered and is out of scope.

### Pitfall 2: Breaking the `ci.security` doc-gate grep
**What goes wrong:** Editing `SECURITY_REVIEW.md` and removing/altering the strings the gate
greps for, turning the build red.
**Why it happens:** The gate is an exact regex over `SECURITY_REVIEW.md`.
**The fact:** `mix ci.security` runs
`cmd grep -nE "docs/security_findings.md|Findings Ledger" SECURITY_REVIEW.md`
[VERIFIED: mix.exs line 157]. `SECURITY_REVIEW.md` currently contains both
`docs/security_findings.md` (multiple links) and a `## Findings Ledger` heading
[VERIFIED: repo]. Either substring must remain.
**How to avoid:** When correcting the `SECURITY_REVIEW.md` "Named Code Seams" row, keep the
`## Findings Ledger` heading and at least one `docs/security_findings.md` reference intact.

### Pitfall 3: Touching the generated evidence file
**What goes wrong:** Editing `SECURITY_REVIEW_EVIDENCE.md` directly to reflect the new
guarantee → `relyra.security_review --check` reports drift → build red.
**Why it happens:** The file looks like a normal doc but is generated (header: "Generated
from executable security defaults…") [VERIFIED: repo line 2-3].
**The fact:** `ci.security` runs `relyra.security_review --check`, which byte-compares the
file against the generator's render and `Mix.raise`s on any difference
[VERIFIED: mix.exs line 158 + lib/mix/tasks/relyra.security_review.ex `check_report!/2`].
**How to avoid:** Don't touch it. If its content must change, edit
`lib/mix/tasks/relyra.security_review.ex` and regenerate (D-11). **For Phase 31 the
evidence file likely needs NO change** — its tables describe strict-default/escape-hatch
policy and KeyInfo trust rejection (all still true); the "signature *verification* now
performs real crypto" honesty lives in the hand-maintained docs + ledger, not the generator.
Confirm during planning whether any evidence-table claim overstates verification; if not,
leave the generator untouched.

### Pitfall 4: Markdown table corruption in the ledger
**What goes wrong:** The new ledger row has a different column count than the header → table
renders broken and any future tooling mis-parses it.
**How to avoid:** Match the existing 8-column header exactly (Pattern 3). Also update the
contradicting prose on line 3 of `docs/security_findings.md`.

### Pitfall 5: Affected-version range expression for hex
**What goes wrong:** Listing "1.0.0, 1.1.0" as discrete versions when GHSA expects a range,
or using an npm-style range on a hex package.
**The fact:** GHSA "Affected products" takes ecosystem + package + a vulnerable version
*range* and a first-patched version. For Relyra: ecosystem hex (GitHub labels it `Erlang`),
package `relyra`, vulnerable range `>= 1.0.0, < 1.2.0`, first patched `1.2.0`. The
`[ASSUMED]` part is the exact ecosystem dropdown label — verify at file time.
**How to avoid:** Express the range as `>= 1.0.0, < 1.2.0` (which covers exactly 1.0.0 and
1.1.0, the two published versions) and patched `1.2.0` in the draft's Affected Products table.

## CVE Request Fields (pre-stage in the draft)

The standard path is **GHSA → "Request CVE"** (GitHub is a CNA; requesting a CVE on a draft
GHSA assigns a CVE id) [CITED: docs.github.com creating-a-repository-security-advisory]. The
draft's "CVE request" subsection should pre-stage exactly what the request needs (which is
the same data the GHSA form already captures):

| CVE/GHSA field | Pre-staged value |
|----------------|------------------|
| Internal id (until assignment) | `RELYRA-2026-001` |
| Title | Relyra SAML `SignatureValue` not cryptographically verified → authentication bypass |
| Ecosystem / package | hex (`Erlang`) / `relyra` |
| Affected range | `>= 1.0.0, < 1.2.0` |
| First patched | `1.2.0` |
| Severity (CVSS 3.1) | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` → 9.1 Critical |
| CWE | CWE-347 (primary), CWE-287 (companion, optional) |
| Description | the GHSA body summary + impact |
| Credits | maintainers |
| Request mechanism | GitHub "Request CVE" on the draft GHSA (ship-time, D-09) |

State in the draft that GHSA and CVE numbers attach at publication and replace the internal
`RELYRA-2026-001` placeholder (D-06).

## Code Examples

### Corrected primitive language (D-01) — drop-in for the three docs
The current overstatement is the bare phrase **"signature verification"** /
"Signed nodes must bind to configured trust only" [VERIFIED: repo]:
- `docs/security_boundary.md` line 8 (In Scope): "…signature verification, and document-provided `KeyInfo` trust rejection."
- `docs/security_boundary.md` line 32 (Trust Seams, Signed-content trust row).
- `SECURITY_REVIEW.md` line 45 (Named Code Seams: "Document-provided `KeyInfo` and signed-node trust rejection").

Replace the vague phrase with the named post-fix primitive (planner owns exact microcopy;
brand voice: calm/exact/falsifiable). Suggested factual core to encode (D-01):

> Inbound Response/assertion and metadata-root (`EntityDescriptor`/`EntitiesDescriptor`)
> signatures are cryptographically verified: `:public_key.verify` over the exclusive-C14N
> canonicalized `SignedInfo` against the **configured** IdP certificate's public key (never
> document-provided `KeyInfo`), plus a constant-time `DigestValue` recompute/compare over
> the canonicalized referenced element, bound to the exact consumed node — on both the
> `verify/4` and `verify_metadata_root/4` paths.

### Advisory front-matter / id block (draft)
```markdown
# Relyra: SAML SignatureValue not cryptographically verified (authentication bypass)

- Internal ID: RELYRA-2026-001  (GHSA/CVE attach at publication)
- Status: STAGED — not published (fix-first; publish at the 1.2.0 release)
- Ecosystem: hex (Erlang) — package `relyra`
- Affected: >= 1.0.0, < 1.2.0   (published 1.0.0, 1.1.0)
- Patched: 1.2.0
- Severity: Critical — CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N (9.1)
- Weakness: CWE-347 (Improper Verification of Cryptographic Signature)
```

## State of the Art

| Old Approach | Current Approach | When | Impact |
|--------------|------------------|------|--------|
| Keep-a-Changelog manual "Security" heading | release-please conventional-commit sections (feat/fix only by default) | release-please standard | No auto "Security" section; note text lives in advisory + Release notes |
| CVSS 3.1 only | GHSA accepts CVSS 3.1 AND 4.0; recent SAML CVEs publish 4.0 | 2024+ | Optional 4.0 vector strengthens the draft but is not required |
| CVE-first | GHSA-first, then "Request CVE" from the GHSA (GitHub is a CNA) | GitHub repo advisories | The draft maps to GHSA; CVE flows from it |

## Validation Architecture

This phase is documentation-only; `workflow.nyquist_validation` is `true` (config), so this
section is required — but "validation" here means **doc-gate compatibility**, not test
coverage. The validation surface is the doc-check portion of the `mix ci.security` alias.

### "Test Framework" (doc-gate)
| Property | Value |
|----------|-------|
| Framework | `mix ci.security` alias (doc-check steps) + ExUnit meta-gate |
| Config file | `mix.exs` `aliases/0` → `"ci.security"` [VERIFIED: lines 152–180] |
| Quick run command | The four doc-gate steps below (or full `mix ci.security`) |
| Full suite command | `mix ci.security` |

### Exact `ci.security` doc-gate steps (captured verbatim from `mix.exs`)
[VERIFIED: repo `mix.exs` lines 153–158]:
```
"compile --warnings-as-errors",
"ci.conformance",
"cmd test -f SECURITY_REVIEW.md",
"cmd test -f docs/security_boundary.md",
"cmd grep -nE \"docs/security_findings.md|Findings Ledger\" SECURITY_REVIEW.md",
"relyra.security_review --check",
```
(The remaining `ci.security` steps are the crypto/corpus suites — frozen, unchanged this
phase — run as their own `cmd mix test` lines, plus `deps.audit … --ignore-advisory-ids
GHSA-rhv4-8758-jx7v`, `hex.audit`, `sobelow --config`.)

### Phase Requirements → Doc-gate Map
| Req | Behavior | Check type | Automated command | Exists? |
|-----|----------|-----------|-------------------|---------|
| DISC-01 | `SECURITY_REVIEW.md` still present | file-existence | `mix cmd test -f SECURITY_REVIEW.md` | ✅ |
| DISC-01 | `docs/security_boundary.md` still present | file-existence | `mix cmd test -f docs/security_boundary.md` | ✅ |
| DISC-01 | findings-ledger cross-ref still grep-matchable in `SECURITY_REVIEW.md` | grep | `mix cmd grep -nE "docs/security_findings.md\|Findings Ledger" SECURITY_REVIEW.md` | ✅ |
| DISC-01 | generated evidence not drifted | generator drift-check | `mix relyra.security_review --check` | ✅ |
| DISC-01 | corrected docs still compile/format-clean (markdown is not compiled, but the lane recompiles) | compile gate | `mix compile --warnings-as-errors` | ✅ |
| DISC-01/02 | full lane green after edits | full gate | `mix ci.security` | ✅ |
| DISC-02 | advisory draft is a valid new file (no gate asserts its content) | manual / file-existence | `test -f docs/advisories/2026-001-xmldsig-signature-not-verified.md` | ❌ (new file this phase) |

### Sampling Rate
- **Per doc edit:** re-run the four doc-gate steps (fast) — especially the grep after any `SECURITY_REVIEW.md` change.
- **Per task / before commit:** `mix ci.security` (full lane; proves no crypto/corpus regression and doc-gate green).
- **Phase gate:** `mix ci.security` green + full `mix test` green before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `docs/advisories/` directory does not exist yet — created when the draft lands (no test infra needed; it is a doc).
- [ ] No automated check asserts advisory-draft *content* — content correctness is a human/reviewer concern (no gate is required or expected by CONTEXT.md). Do NOT add a brittle content-grep gate for the draft.
- [ ] Confirm during planning whether any `SECURITY_REVIEW_EVIDENCE.md` table claim overstates "verification" — if yes, change the generator (D-11) and regenerate; if no (likely), leave it untouched. (No new test file needed either way.)

*No new ExUnit test files are required for this phase — the doc-gate is the validation surface.*

## Security Domain

`security_enforcement` is not in config, but this is itself a *security disclosure* phase
with no code change. ASVS does not map to a docs-only disclosure phase, and no new threat
surface is introduced. The relevant security control is **disclosure accuracy**: the docs
must not overstate the guarantee (the original sin this phase corrects), and the advisory
must be staged fix-first (no premature publication, D-09). The vulnerability being disclosed
maps to **ASVS V1/V2 (authentication) failure** and **CWE-347**; that mapping belongs in the
advisory body, not as a new control to implement here.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GHSA "Affected products" ecosystem dropdown for hex is labelled `Erlang` | GHSA form / Pitfall 5 | Low — visible at file time in the GitHub UI; only affects a label, not the draft's substance. Verify when filing. |
| A2 | The `relyra.security_review` generator output needs no change this phase (its tables don't overstate verification) | Pitfall 3 / Wave 0 | Medium — if a generated-evidence claim DOES overstate, the plan must edit the generator (D-11), not the file. Planner must inspect the evidence tables before deciding. |
| A3 | GHSA → "Request CVE" remains the active GitHub flow and assigns a CVE for repo advisories | CVE Request Fields | Low — documented GitHub flow; ship-time action (D-09), not exercised this phase. |

**Note:** The two load-bearing *process* facts — release-please default sections (no
"security" section) and the exact `ci.security` doc-gate steps — are **VERIFIED against the
repo**, not assumed.

## Open Questions

1. **Should the advisory draft additionally link the Phase 29/30 SECURITY.md threat verifications?**
   - What we know: CONTEXT.md (discretion bullet) explicitly leaves this open; the files exist
     (`29-SECURITY.md` 24/24, `30-SECURITY.md` 18/18) and are strong supporting evidence.
   - What's unclear: Whether the maintainer wants planning-internal `.planning/` paths
     referenced from a published-facing advisory (those paths are repo-internal, not hex-shipped).
   - Recommendation: In the **References** section, link the *shipped* proofs
     (`test/security/xml/adversarial_crypto_test.exs`, `test/security/ci_gate_integrity_test.exs`,
     the fix commits) as primary; optionally mention the Phase 29/30 threat verifications as
     internal corroboration but do not make the public advisory depend on `.planning/` paths.

2. **CVSS Scope: `S:U` (9.1) vs `S:C` (10.0)?**
   - What we know: Both are Critical; `S:U` mirrors NVD's ruby-saml scoring (most defensible).
   - Recommendation: Use `S:U` → 9.1 Critical; add a one-line note that an `S:C` reading
     reaches 10.0. (Confirm-or-refine is explicitly the researcher/planner's per D-86 discretion.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` (Elixir) | running `ci.security` doc-gate | ✓ (project toolchain) | elixir ~> 1.19 | — |
| `grep`, `test` (coreutils) | doc-gate `cmd` steps | ✓ (darwin/CI) | — | — |
| `gh` CLI | publishing GHSA / CVE | **not needed this phase** | — | N/A — publication is deferred to ship time (D-09) |
| network / GitHub UI | filing advisory | not needed this phase | — | N/A — staging is local files only |

**No external dependency blocks Phase 31.** All work is local file edits validated by the
existing `mix ci.security` lane. The only external systems (GitHub GHSA form, CVE assignment)
are ship-time actions explicitly out of scope (D-09).

## Sources

### Primary (HIGH confidence)
- Repo files (VERIFIED): `mix.exs` (`ci.security` alias, lines 152–180; release deps),
  `CHANGELOG.md` (only Features/Bug Fixes sections), `.release-please-config.json`
  (`release-type: elixir`), `.github/workflows/release-please.yml`,
  `docs/security_boundary.md`, `SECURITY_REVIEW.md`, `docs/security_findings.md`,
  `SECURITY.md`, `SECURITY_REVIEW_EVIDENCE.md`, `lib/mix/tasks/relyra.security_review.ex`,
  `test/security/xml/adversarial_crypto_test.exs`, `test/security/ci_gate_integrity_test.exs`,
  `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`,
  `.planning/phases/31-disclosure-and-docs-honesty/31-CONTEXT.md`.
- docs.github.com — Creating a repository security advisory (GHSA form fields, CVE request):
  https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/creating-a-repository-security-advisory
- docs.github.com — About the GitHub Advisory database (CVSS 3.1+4.0, CWE):
  https://docs.github.com/code-security/security-advisories/working-with-global-security-advisories-from-the-github-advisory-database/about-the-github-advisory-database
- NVD — CVE-2025-25292 (ruby-saml; CVSS:3.1 9.8 S:U; CWE-347): https://nvd.nist.gov/vuln/detail/CVE-2025-25292
- GitHub Advisory — GHSA-r683-v43c-6xqv / CVE-2025-47949 (samlify; CWE-347; CVSS 4.0 9.9): https://github.com/advisories/GHSA-r683-v43c-6xqv
- FIRST.org — CVSS v3.1 specification/examples (base-score formula): https://www.first.org/cvss/v3-1/examples

### Secondary (MEDIUM confidence)
- googleapis/release-please customizing.md (default changelog-notes builder groups by commit type): https://github.com/googleapis/release-please/blob/main/docs/customizing.md
- conventional-changelog-conventionalcommits default types (feat/fix visible; chore/docs/etc hidden; no security): conventionalcommits.org + preset defaults
- ruby-saml advisory GHSA-9v8j-x534-2fx3 (advisory body structure): https://github.com/SAML-Toolkits/ruby-saml/security/advisories/GHSA-9v8j-x534-2fx3
- Zscaler CVE-2025-54982 (CWE-347 SAML signature verification flaw — framing precedent): https://nvd.nist.gov/vuln/detail/CVE-2025-54982

### Tertiary (LOW confidence — flagged)
- Exact GHSA hex-ecosystem dropdown label "Erlang" — A1, verify at file time.

## Metadata

**Confidence breakdown:**
- Disclosure framework (GHSA fields, CVE flow): HIGH — official GitHub docs.
- CVSS vector/score: HIGH — anchored to NVD-scored near-identical precedent (CVE-2025-25292) + FIRST formula.
- CWE-347 classification: HIGH — three peer SAML advisories + MITRE definition.
- release-please CHANGELOG mechanics (D-08 process fact): HIGH — verified against repo config + actual CHANGELOG sections.
- Doc-gate / Validation Architecture: HIGH — exact steps read from `mix.exs`.
- Advisory body framing precedents: MEDIUM — representative real advisories, light-touch per scope.

**Research date:** 2026-05-24
**Valid until:** ~2026-06-23 (30 days; GHSA form + release-please defaults are stable; re-check the hex ecosystem label and GHSA "Request CVE" UI at ship time).
