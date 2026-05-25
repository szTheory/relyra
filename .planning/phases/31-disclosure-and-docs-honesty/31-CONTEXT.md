# Phase 31: Disclosure and docs honesty - Context

**Gathered:** 2026-05-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Correct the security docs that overstate the verification guarantee, record the
confirmed signature-verification bypass in the findings ledger with a disposition,
and **stage** (do not publish) the coordinated advisory — GHSA draft + requested
CVE + CHANGELOG security note — marking hex `1.0.0`/`1.1.0` affected. Outward
publication happens at the fixed-release ship time (fix-first posture).

**In scope:** doc-text corrections (`docs/security_boundary.md`, `SECURITY_REVIEW.md`,
`docs/security_findings.md`), one ledger finding row, one checked-in advisory draft
artifact, the CHANGELOG note *text* (staged, not merged into the generated file).

**Out of scope:** the crypto fix itself (done, Phases 28–30); filing the GHSA /
requesting the CVE / cutting the release / running `gh` to publish; merging the
branch to `main`. Those are ship-time actions, not Phase 31.
</domain>

<decisions>
## Implementation Decisions

### Doc-correction framing (DISC-01)
- **D-01:** Correct the three named docs to **precisely** state the now-real crypto
  guarantee — genuine `:public_key.verify` over the canonicalized `SignedInfo`
  against the **configured** IdP certificate (never document `KeyInfo`) + constant-time
  `DigestValue` recompute/compare, bound to the exact consumed node, on **both** the
  assertion (`verify/4`) and metadata-root (`verify_metadata_root/4`) paths. Replace
  vague "signature verification" language with the named primitive.
- **D-02:** Honesty is forward-looking — the docs describe what is **now true**
  post-fix; the *historical* gap in shipped hex `1.0.0`/`1.1.0` is captured **once**,
  in the findings ledger (D-03), not scattered as redundant caveats across every doc.
- **D-03:** `SECURITY.md` is left as-is — its "Signatures are verified against
  configured certificates only" line (line 18) is now true post-fix; no correction
  needed. (Touch only the three DISC-01-named files.)

### Findings-ledger entry (DISC-01)
- **D-04:** Replace the `none yet` placeholder in `docs/security_findings.md` with one
  **Critical** finding row:
  - Exploit path: forged `SignatureValue` carrying an attacker-controlled `NameID`
    accepted as `{:ok}` — full SAML authentication bypass.
  - Disposition: Confirmed → Fixed in v1.1 (hex `1.2.0`).
  - Owner: maintainers. Blocker state: resolved.
  - Regression proof: the `@tag :adversarial_crypto` corpus
    (`test/security/xml/adversarial_crypto_test.exs`) + the anti-hollow gate
    (`test/security/ci_gate_integrity_test.exs`), green under `mix ci.security`.
- **D-05:** Severity is **Critical** (full auth bypass on the trust boundary), not High.
- **D-06:** The ledger finding ID should cross-reference the eventual GHSA/CVE id once
  assigned; until then use a stable internal id (e.g. `RELYRA-2026-001`) and note that
  the GHSA/CVE numbers attach at publication.

### Advisory artifact: GHSA + CVE + CHANGELOG (DISC-02)
- **D-07:** Stage **one checked-in draft** at
  `docs/advisories/2026-001-xmldsig-signature-not-verified.md` (new `docs/advisories/`
  directory) containing: GHSA body (summary, impact, affected `1.0.0`/`1.1.0`, patched
  `1.2.0`, severity/CVSS, workaround = upgrade, credits, references), a "CVE request"
  subsection, and the exact CHANGELOG security-note prose.
- **D-08:** Do **not** hand-edit the release-please-generated `CHANGELOG.md` — it is
  regenerated from conventional commits and would clobber manual edits. Keep the
  canonical note text in the draft (D-07); rely on the fix commit's conventional-commit
  security footer to surface it at release. (No manual "Unreleased" block.)
- **D-09:** **Fix-first / no premature publication.** Phase 31 produces only
  checked-in/staged artifacts. Do not run `gh` to file the GHSA, request the CVE, or
  publish — those happen at the fixed-release ship time. (Embargo posture: solo dev,
  no adopters → no secrecy needed; commit messages/PRs may describe the bug plainly.
  This is record-keeping, not embargo.)

### ci.security doc-gate compatibility (DISC-01)
- **D-10:** Preserve the `mix ci.security` doc checks: keep `SECURITY_REVIEW.md` +
  `docs/security_boundary.md` present, and keep the
  `docs/security_findings.md|Findings Ledger` cross-reference grep-matchable in
  `SECURITY_REVIEW.md` (alias step: `cmd grep -nE "docs/security_findings.md|Findings Ledger" SECURITY_REVIEW.md`).
- **D-11:** Do **not** hand-edit the **generated** `SECURITY_REVIEW_EVIDENCE.md`
  (header: "Generated from executable security state"; produced by
  `mix relyra.security_review --check`). If its content must change, update the
  generator task `lib/mix/tasks/relyra.security_review.ex` so `--check` does not drift.

### Claude's Discretion
- Exact wording/microcopy of the corrected doc sections (brand voice: calm, exact,
  falsifiable — never "bulletproof"/"unhackable"/"military-grade" per PROJECT.md brand).
- CVSS vector/score for the advisory (auth-bypass on the trust boundary → expect
  Critical, ~9.x; planner/researcher may refine).
- Whether the advisory draft additionally links the Phase 29/30 SECURITY.md threat
  verifications as supporting evidence.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

Files to correct (DISC-01):
- `docs/security_boundary.md` — trust-boundary map (line 8 / Trust Seams table overstate the guarantee)
- `SECURITY_REVIEW.md` — reviewer packet (Named Code Seams table; keep findings-ledger cross-ref)
- `docs/security_findings.md` — findings ledger (replace `none yet` placeholder → D-04 row)

Read-only references (do NOT hand-edit):
- `SECURITY_REVIEW_EVIDENCE.md` — GENERATED; change via `lib/mix/tasks/relyra.security_review.ex` only (D-11)
- `CHANGELOG.md` — release-please generated; do not hand-edit (D-08)
- `SECURITY.md` — already accurate post-fix; left as-is (D-03)

Gate / generator references:
- `mix.exs` — `ci.security` alias (doc checks at the `cmd test -f` / `cmd grep -nE` / `relyra.security_review --check` steps)
- `lib/mix/tasks/relyra.security_review.ex` — evidence generator

Requirement + proof references:
- `.planning/REQUIREMENTS.md` — DISC-01, DISC-02 (and the v1.1 origin/governing decision)
- `.planning/ROADMAP.md` — Phase 31 detail (success criteria 1–3)
- `test/security/xml/adversarial_crypto_test.exs` — regression proof (the corpus closing the bypass)
- `test/security/ci_gate_integrity_test.exs` — anti-hollow CI gate
- `.planning/phases/29-cryptographic-xmldsig-verification/29-SECURITY.md` — 24/24 threats closed
- `.planning/phases/30-adversarial-crypto-assurance/30-SECURITY.md` — 18/18 threats closed
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The crypto fix is already complete and verified on this branch (Phases 28–30):
  real exclusive-C14N + `:public_key.verify` + constant-time `DigestValue` recompute
  behind the `Relyra.Security.XML` seam (`lib/relyra/security/*`, FROZEN/byte-unchanged
  per D-10 fence). `FakeIdP` performs real XMLDSig signing. This phase only documents
  and discloses that fix — it changes **no** `lib/` security code.
- The `@tag :adversarial_crypto` corpus + the anti-hollow meta-gate are the citable
  regression proofs for the ledger row and the advisory.

### Established Patterns
- `ci.security` doc checks are file-existence + cross-ref-grep + generated-evidence
  drift-check — edits must satisfy all three (D-10/D-11).
- `SECURITY_REVIEW_EVIDENCE.md` is generated; `CHANGELOG.md` is release-please-driven.
  Honesty corrections go in the hand-maintained docs, not the generated ones.
- Brand/security language is locked: precise, falsifiable claims only; no
  marketing-grade absolutes (PROJECT.md brand constraint).

### Integration Points
- No runtime/code integration — outputs are markdown docs + one new advisory draft
  file under `docs/advisories/`.
- Ship-time hand-off (out of this phase): merge `security/xmldsig-real-verification`
  → `main`, release-please cuts `1.2.0`, then file GHSA / request CVE / publish note.
</code_context>

<specifics>
## Specific Ideas

- Advisory draft path: `docs/advisories/2026-001-xmldsig-signature-not-verified.md`.
- Internal finding id placeholder: `RELYRA-2026-001` (GHSA/CVE numbers attach at publish).
- Affected: hex `1.0.0` and `1.1.0`; patched: `1.2.0` (release-please-driven, decoupled
  from the v1.1 planning label).
</specifics>

<deferred>
## Deferred Ideas

- Actual publication of the GHSA, the CVE request, and the GitHub Release / CHANGELOG
  note — deferred to the fixed-release ship step (post-merge), per D-09.
- Merging `security/xmldsig-real-verification` → `main` and cutting `1.2.0` — ship step,
  not Phase 31.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
