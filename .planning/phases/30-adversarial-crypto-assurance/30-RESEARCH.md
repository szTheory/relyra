# Phase 30: Adversarial crypto assurance - Research

**Researched:** 2026-05-24
**Domain:** XMLDSig adversarial test corpus + FakeIdP real-signing promotion + CI/conformance gate wiring (Elixir/OTP, pure-BEAM)
**Confidence:** HIGH (all findings verified against in-repo code; no external/training-data dependence)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `FakeIdP.sign/2` routes its emitted XML through the EXISTING `Relyra.TestSupport.XmldsigSigner.sign_response/1` (inject genuine `DigestValue` + `SignatureValue` in place), then base64-encodes. Do NOT re-implement crypto in `FakeIdP` (would create a divergent canonicalizer — the T-29-15 false-positive). Central Phase-30 integration decision (Phase 29 D-12).
- **D-02:** Reconcile the FakeIdP XML shape so signed bytes match what the verifier recomputes. FakeIdP currently omits `<CanonicalizationMethod>` in `<SignedInfo>` and collapses whitespace (`fake_idp.ex:128-134`); signer carries `<CanonicalizationMethod>` and is whitespace-free (`xmldsig_signer.ex:252-254`). Align FakeIdP's emitted shape or the positive control fails recompute.
- **D-03:** `FakeIdP` exposes its trust certificate (delegate `self_signed_cert_pem/0` or equivalent) so callers can configure the `cert_chain`.
- **D-04:** The four crypto categories live in a NEW test module, NOT in `priv/security_corpus.json` (the JSON corpus `evaluate_fixture/1` only evaluates to parse/select/canonicalize, never `Signature.verify/4`; the trust cert is a runtime `:persistent_term`, not serializable). Each case mints input FROM genuine FakeIdP/signer output and drives `PureBeam.parse_safely → Signature.verify/4`.
- **D-05:** Construction recipes (all demonstrated in `signature_crypto_test.exs`): wrong-key = throwaway cert → `:invalid_signature`; tampered/digest-mismatch = `tamper_name_id:` → `:digest_mismatch`; forged-sig = same-length random base64 SignatureValue → `:invalid_signature`; positive control = genuine signed → `{:ok, %SignedNode{}}`.
- **D-06:** c14n-differential case = post-signing canonically-significant tamper into the signed `<Assertion>` subtree → `verify_reference_digest` recomputes a different digest → `{:error, :digest_mismatch}`. Mutation MUST be one exclusive-C14N PRESERVES (added attribute / added element / visibly-utilized namespace decl) — NOT one C14N normalizes away (e.g. attribute reordering). Consult PROVENANCE.md.
- **D-07:** NO new out-of-band Docker golden required for the c14n-differential case (a REJECTION fixture claims no canonical byte string). CI stays pure-Elixir.
- **D-08:** Add the new adversarial crypto-verify suite to the `ci.security` alias (`mix.exs:152-169`) with a tag (reuse `:security_corpus` or add `:adversarial_crypto` — executor's choice), run with `--warnings-as-errors`. Today `ci.security` does NOT run `signature_crypto_test.exs` — the crypto proofs are currently OUTSIDE the gate.
- **D-09:** The c14n-differential REJECTION fixture is added to `priv/security_corpus.json` with full `provenance`/`requirement_ids`/`family`/`source_ref`, AND `CONFORMANCE.md` regenerated via `mix relyra.conformance`. `ci.security` runs `relyra.conformance --check` first (via `ci.conformance`) and fails on drift.
- **D-10:** Phase 29 follow-up warnings WR-02..WR-05 stay OUT of scope. WR-03 (Reference/@URI not bound to consumed node) is the one the corpus naturally brushes against; if a planned input exposes it, NOTE it as a follow-up — do not fix in-phase.

### Claude's Discretion
- Exact module name/location for the new adversarial suite; reuse `:security_corpus` tag or add `:adversarial_crypto` (D-08).
- The specific canonically-significant mutation for the c14n-differential fixture, from the PROVENANCE catalog (D-06).
- Whether to drive the four crypto categories through `FakeIdP.sign` end-to-end or through `XmldsigSigner` directly where FakeIdP delegates (must exercise the SAME signing path either way, per D-01).

### Deferred Ideas (OUT OF SCOPE)
- Phase 29 follow-ups WR-02..WR-05 (SignedInfo prefix-list scoping, Reference/@URI binding, enveloped metadata pruning, byte-guard ordering) — deferred phase; D-10.
- Full XMLDSig ECDSA support (`r‖s`→DER) — fast-follow after v1.1; ECDSA fail-closed today.
- Security-doc honesty corrections + GHSA/CVE/CHANGELOG advisory — Phase 31 (DISC-01/02).
- Signed-metadata adversarial cases beyond assertion/response path — optional extension via `verify_metadata_root/4`; add only if it strengthens the gate without scope creep.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ASSUR-02 | `Relyra.TestSupport.FakeIdP` performs real cryptographic XMLDSig signing with its generated keypair (emits real `DigestValue` + `SignatureValue`). | Promote via `FakeIdP.sign → XmldsigSigner.sign_response/1` (D-01). The signer already reuses `FakeIdP.keypair()` and binds the verifier's own C14N nodes (`xmldsig_signer.ex:208,275-281`). Blast radius is tiny: `FakeIdP.sign` is consumed only by `test_support_demo_test.exs` (stub controller, no real verify) — see Runtime State Inventory. The D-02 shape reconciliation is the load-bearing change. |
| ASSUR-01 | Permanent adversarial corpus proving rejection of forged-sig / tampered-content / wrong-key / digest-mismatch / canonicalization-differential, each `{:error, %Relyra.Error{}}`, plus a positive control `{:ok}`. Wired into `corpus_gate` + conformance manifest, green under `mix ci.security`. | All five recipes + positive control already exist and pass in `signature_crypto_test.exs:202-255` (forged at `:81-90`, wrong-key `throwaway_cert_pem/0` `:215-224`, tampered `:226-235`, positive `:203-213`). Phase 30 promotes them into a FakeIdP-driven, gated suite (D-04/D-05) and adds the genuinely-NEW digest-mismatch-via-C14N-preserved-mutation case (D-06) the current suite does not yet cover. |
</phase_requirements>

## Summary

Phase 30 is a **consolidation + gating** phase, not a crypto-correctness phase. Phase 29 already proved every adversarial recipe works against the real verify path; the residual risk is entirely in **wiring** and **two precise byte-alignment / corpus-routing landmines**. The crypto is done — the danger is that the planner under-specifies the FakeIdP shape reconciliation (D-02) or mis-routes the c14n-differential REJECTION case (D-06/D-09) into the wrong evaluator.

Two findings dominate the planning risk. **(1) The c14n-differential routing tension (HIGHEST RISK).** The JSON corpus evaluator (`corpus_security_test.exs:161-194 evaluate_fixture/1`) for class `parser_differential_and_c14n` runs ONLY `parse_safely → canonicalize` and never reaches `Signature.verify/4` — so a `:digest_mismatch` (which is produced only by `verify_reference_digest`, `signature.ex:346-374`) **cannot** be asserted by a JSON row under the existing evaluator. The `:digest_mismatch` proof MUST live in the new crypto-verify suite (D-04/D-06). What goes into the JSON (D-09) is a separate, complementary row that the existing `canonicalize`-only evaluator can satisfy (a `canonicalization_failed` row, OR a new `class` whose `evaluate_fixture` branch reaches verify). The plan must NOT add a JSON row asserting `:digest_mismatch` under the current `parser_differential_and_c14n` branch — it would fail the `evaluate_fixture` test. **(2) The D-02 shape reconciliation.** FakeIdP's `response_xml` differs from the signer's shape in THREE ways — missing `<CanonicalizationMethod>`, whitespace-collapse, and SAML namespace declarations (`xmlns="urn:oasis:names:tc:SAML:2.0:assertion"`) that the signer's shape omits. The cleanest reconciliation (D-01) is to make `FakeIdP.sign` delegate to `XmldsigSigner.sign_response/1`, which re-derives the digest/signature from the *emitted* bytes (self-parse), making byte-alignment structural regardless of FakeIdP's exact whitespace/namespace shape — but FakeIdP must still emit the `<CanonicalizationMethod>` element (the signer's `signed_info_prefix_list/1` and the verifier both read it).

**Primary recommendation:** Promote `FakeIdP.sign` to delegate to `XmldsigSigner.sign_response/1` (add `<CanonicalizationMethod>` to FakeIdP's `<SignedInfo>`, drop the post-template whitespace collapse); add `FakeIdP.self_signed_cert_pem/0` delegating to the signer. Build a NEW `:adversarial_crypto`-tagged suite that promotes the five existing recipes + positive control, FakeIdP-driven, adding the C14N-preserved digest-mismatch case (recommend: **add a new attribute to the `<Assertion>` apex element post-signing**, e.g. `Foo="bar"`). Add a complementary `canonicalization_failed` REJECTION row to `priv/security_corpus.json`, regenerate `CONFORMANCE.md`, and name the new suite into `ci.security`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Real XMLDSig signing (digest+signature mint) | Test support (`XmldsigSigner`) | FakeIdP (delegation seam) | Signing is a test fixture concern; production never signs assertions (SP role). The signer reuses the verifier's C14N engine to guarantee no canonicalizer differential (D-01/D-12). |
| Cryptographic verification | Security core (`Signature.do_verify`, Phase 29) | — | Already implemented and frozen for this phase. The corpus exercises it; it does not change. |
| Adversarial corpus evaluation (crypto categories) | New test module (`:adversarial_crypto`) | — | Must drive the full `PureBeam.parse_safely → Signature.verify/4` path with a runtime `:persistent_term` cert (D-04) — not serializable into static JSON. |
| Static-fixture corpus (parse/select/canonicalize) | `priv/security_corpus.json` + `corpus_security_test.exs` | `corpus_gate.ex` (runtime) | Pre-verify trust-discipline shapes only; evaluator stops at `canonicalize` (`:161-194`). The c14n-differential REJECTION row (D-09) lives here as a `canonicalization_failed`-class proof, distinct from the D-06 `:digest_mismatch` proof. |
| Conformance manifest + drift gate | `relyra.conformance` task + `CONFORMANCE.md` | `ci.conformance` alias | Doc regeneration is mandatory after a JSON row add (D-09); `--check` fails on drift. |
| CI gating | `ci.security` alias (`mix.exs:152-169`) | — | A suite not named in the alias does not gate (D-08). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:public_key` (OTP) | OTP 28 (erts 16.3) | RSA sign (`:public_key.sign/3`), self-signed cert mint (`:public_key.pkix_test_root_cert/2`), verify | Already the entire crypto base of Phase 29; no third-party crypto. `[VERIFIED: erl -version → OTP 28]` |
| `:crypto` (OTP) | OTP 28 | `:crypto.hash/2`, `:crypto.strong_rand_bytes/1` (forged-sig recipe), `:crypto.hash_equals/2` | Constant-time compare in `verify_reference_digest`. `[VERIFIED: signature.ex:349-352]` |
| `:json` (OTP) | OTP 27+ | Decode `priv/security_corpus.json` in `corpus_security_test.exs` + `corpus_gate.ex` | Native OTP JSON; already used (`corpus_security_test.exs:158`, `corpus_gate.ex:54`). `[VERIFIED: codebase grep]` |
| `Jason` | 1.4.5 | Decode manifests in `conformance_fixtures.ex` (`Jason.decode!`) | Transitively available (credo/sobelow/ecto/req all pull `jason ~> 1.x`; loaded in `:test`). `[VERIFIED: mix.lock:13]` |
| `Saxy` | 1.6 | Parse tree (`SaxyTree.parse/1`) the signer + verifier share | Phase 28 foundation. `[VERIFIED: mix.exs:57]` |
| `ExUnit` | bundled (Elixir 1.19.5) | The new adversarial suite | `[VERIFIED: elixir --version]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Relyra.TestSupport.XmldsigSigner` | in-repo (Phase 29) | The genuine signer to promote | Every adversarial recipe + the FakeIdP delegation seam |
| `Relyra.TestSupport.FakeIdP` | in-repo | The real-signing target (ASSUR-02) | `sign/2` delegates to the signer; `keypair/0` already the single key source |
| `Relyra.Security.Signature` | in-repo (Phase 29) | `verify/4` — the path under test | Frozen; corpus calls it, does not modify it |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Delegate `FakeIdP.sign → XmldsigSigner.sign_response/1` (D-01) | Re-implement digest/signature inside FakeIdP | REJECTED by D-01: a second signer = a divergent canonicalizer = the T-29-15 false-positive (positive control passes for the wrong reason). |
| New `:adversarial_crypto` tag | Reuse `:security_corpus` tag | Discretion (D-08). A dedicated tag is cleaner for the alias line and lets `ci.security` run the crypto suite distinctly; reusing `:security_corpus` means one fewer alias line. Recommend a dedicated tag for clarity (see Pitfall 4). |
| JSON row `canonicalization_failed` (D-09) | A new `class` with a verify-reaching `evaluate_fixture` branch | A new class requires editing `evaluate_fixture/1` to call `Signature.verify/4`, which needs a runtime cert (the same blocker as D-04). The `canonicalization_failed` row reuses the existing evaluator with zero evaluator changes. Strongly recommend the `canonicalization_failed` row. |

**Installation:** None. No external packages installed — OTP `:public_key`/`:crypto`/`:json` + already-present `Saxy`/`Jason`. No `mix deps.get` needed.

## Package Legitimacy Audit

> **Not applicable.** Phase 30 installs NO external packages. All crypto is OTP stdlib (`:public_key`, `:crypto`, `:json`), and `Saxy`/`Jason` are already vendored (`mix.lock`). The new suite is pure Elixir test code. There is no slopcheck surface. (Verified: `mix.exs` deps unchanged; `T-29-SC` in `29-04-SUMMARY.md` already accepted "No installs — OTP `:public_key`/`:crypto` only".)

## Validation Architecture

### Bypass Failure-Space Analysis (Nyquist sampling adequacy)

The phase's whole point is gating a PROOF. The question Nyquist asks: are the 5 named categories + positive control a dense enough sample of the XMLDSig bypass failure-space to catch real signature-wrapping / forgery / canonicalization failure modes?

**Crypto-error → adversarial-category coverage map.** Every typed `%Relyra.Error{}` the verify path can emit, mapped to which category exercises it:

| Relyra crypto error | Emitted by (`signature.ex`) | Covered by category | Recipe |
|---------------------|------------------------------|---------------------|--------|
| `:invalid_signature` | `verify_signature_math` `:317-325` (math fails) + `:328-334` (non-base64 SignatureValue) | **forged-sig** + **wrong-key** | forged = same-length random base64 (`:81-90`); wrong-key = throwaway cert (`:215-224`) |
| `:digest_mismatch` | `verify_reference_digest` `:355-360` (recompute ≠ declared) + `:363-369` (non-base64) | **tampered-content** + **digest-mismatch (c14n-differential)** | tampered = `tamper_name_id:` (`:226-235`); c14n-differential = C14N-preserved mutation (D-06, NEW) |
| `:untrusted_certificate` | `do_verify` `:111-113` (empty chain), `:115-121` (KeyInfo trust), `public_key_from_cert_chain` `:274-281` (malformed cert) | **wrong-key adjacent** (malformed-cert is a sub-case proven in `:52-73,144-153`) | — already proven; not one of the 5 named categories but in the suite |
| `:unsupported_signature_algorithm` | `digest_atom` `:254-261` (ECDSA / unknown) | **NOT in the 5 named categories** — see gap below | ECDSA fail-closed proven `:131-141` |
| `:canonicalization_failed` | `C14N.serialize`/`canonicalize_reference` (transform allowlist, non-bindable node) + `pure_beam.ex:478-484` (enveloped-sig unresolved) | partially — the JSON `c14n-differential-001` row (`:62-76`) + the new D-09 row | the parse-layer corpus, not the crypto suite |

**Where the 5 categories sample the bypass space (dense ENOUGH):**
- **SignatureValue forgery** — both "well-formed wrong bytes" (forged-sig) and "wrong signing key" (wrong-key) are covered → exercises the `:public_key.verify` core math AND the key-extraction trust source. This is the dense sample for the published-hex auth-bypass site (`signature.ex:170-187`).
- **Content tampering** — `tamper_name_id` covers the canonical case (referenced content changes, signature still well-formed → digest catches it). This is the SIGV-02 proof.
- **Canonicalization differential** — the D-06 NEW case proves a C14N-*preserved* mutation changes the recomputed digest (a tamper the canonicalizer does NOT normalize away). This is the subtle one: it proves the digest recompute is REAL, not a no-op that any-C14N-output passes.

**Failure modes the 5 categories do NOT cover (flag for planner decision):**

| Uncovered failure mode | STRIDE | Why it matters | Recommendation |
|------------------------|--------|----------------|----------------|
| **`:unsupported_signature_algorithm` (ECDSA fail-closed)** as a *FakeIdP-driven corpus* case | Spoofing | The 5 named ASSUR-01 categories are RSA-centric; ECDSA fail-closed is proven in `signature_crypto_test.exs:131-141` but is NOT one of the 5. If the new suite promotes only the 5, the ECDSA proof could fall outside the gate. | **Carry the ECDSA fail-closed assertion into the new gated suite** (it already exists; just include it). Low cost, closes the algorithm-substitution sample. Document as an explicit 6th assertion, not a 6th "category." |
| **Signature-wrapping (XSW) at the crypto layer** (two assertions, one signed) | Tampering | The JSON corpus covers XSW at parse/select (`duplicate_xml_id`, `ambiguous_signed_node`, `:32-61`) — but NOT through `Signature.verify/4` with a genuine signature on the wrong node. WR-03 (Reference/@URI not bound to consumed node) is the live gap here. | **NOTE WR-03 as a follow-up (D-10) — do NOT fix.** If a planned adversarial input (e.g. a genuine signature over assertion-A injected alongside attacker assertion-B) would expose WR-03, the plan should either (a) avoid that exact shape, or (b) assert the CURRENT behavior and annotate "WR-03 follow-up." The XSW-at-select coverage already gates via the JSON corpus; the crypto-layer XSW is the WR-03 territory. |
| **Metadata-root adversarial cases** (`verify_metadata_root/4`) | Tampering | The 5 categories are response/assertion-path. SIGV-04 metadata verify shares the same `do_verify` primitive but is not in the 5. | **Defer (per CONTEXT.md Deferred Ideas)** — optional extension only if it strengthens the gate without scope creep. The shared primitive means the response-path corpus already covers the crypto core. |
| **Digest-algorithm substitution** (e.g. SHA-1 digest method) | Spoofing | Distinct from signature-algorithm substitution; `enforce_digest_method` (`signature.ex:149-150`) gates it. Not in the 5 categories. | **Optional** — low risk (the allowlist already gates it and is unit-tested in `algorithm_policy_test.exs`). Note as covered-elsewhere; do not add unless trivial. |

**Verdict:** The 5 named categories + positive control are a DENSE-ENOUGH sample of the *RSA response/assertion crypto-verify* failure-space — they exercise every `signature.ex` crypto error branch except `:unsupported_signature_algorithm` (recommend carrying the existing ECDSA assertion into the gated suite as a 6th assertion) and the WR-03 XSW-at-crypto-layer (NOTE-as-followup per D-10, do not fix). No category should be *removed*.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled, Elixir 1.19.5 / OTP 28) |
| Config file | none (standard `mix test`; aliases in `mix.exs:130-186`) |
| Quick run command | `mix test <new_suite_path> --warnings-as-errors` |
| Full suite command (phase gate) | `mix ci.security` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ASSUR-02 | `FakeIdP.sign` emits real DigestValue + SignatureValue; positive control verifies `{:ok}` via FakeIdP cert | integration | `mix test <new_suite> --only adversarial_crypto -x` | ❌ Wave 0 (new suite); seam in `xmldsig_signer.ex` exists |
| ASSUR-01 forged-sig | same-length random SignatureValue → `:invalid_signature` | unit | (in new suite) | ✅ recipe at `signature_crypto_test.exs:81-90` — promote |
| ASSUR-01 wrong-key | genuine doc vs throwaway cert → `:invalid_signature` | unit | (in new suite) | ✅ `:215-224` — promote |
| ASSUR-01 tampered-content | `tamper_name_id:` → `:digest_mismatch` | unit | (in new suite) | ✅ `:226-235` — promote |
| ASSUR-01 digest-mismatch (c14n-differential) | C14N-preserved post-sign mutation → `:digest_mismatch` | unit | (in new suite) | ❌ Wave 0 — NEW (D-06); mechanism mirrors `maybe_tamper_name_id` `xmldsig_signer.ex:317-328` |
| ASSUR-01 positive control | genuine FakeIdP-signed → `{:ok, %SignedNode{}}` | integration | (in new suite) | ✅ `:203-213` — promote, FakeIdP-driven |
| ASSUR-01 c14n REJECTION row | JSON corpus row + CONFORMANCE.md regen | corpus | `mix test test/security/xml/corpus_security_test.exs --only security_corpus` + `mix relyra.conformance --check` | ❌ Wave 0 — NEW JSON row (D-09) |
| ASSUR-01 gating | new suite named in `ci.security` | gate | `mix ci.security` | ❌ Wave 0 — alias edit (D-08) |

### Sampling Rate
- **Per task commit:** `mix test <new_suite> --only adversarial_crypto --warnings-as-errors` (the new suite) + `mix test test/security/xml/corpus_security_test.exs --only security_corpus --warnings-as-errors` (if the JSON row changed).
- **Per wave merge:** `mix relyra.conformance --check` (drift) + `mix test --only security_corpus --only gate02_c14n --only adversarial_crypto --warnings-as-errors`.
- **Phase gate:** `mix ci.security` green (the full alias), AND `mix test --warnings-as-errors` (full suite — no regression to the 524/0 baseline; new suite raises the count).

### Wave 0 Gaps
- [ ] New adversarial crypto-verify suite file (e.g. `test/security/xml/adversarial_crypto_test.exs` or `test/relyra/security/adversarial_crypto_test.exs`) — covers ASSUR-01 (all 5 + positive + ECDSA carry-over)
- [ ] `FakeIdP.sign` promotion to delegate to `XmldsigSigner.sign_response/1` + `<CanonicalizationMethod>` + drop whitespace-collapse (D-02) — ASSUR-02
- [ ] `FakeIdP.self_signed_cert_pem/0` delegate (D-03)
- [ ] NEW `priv/security_corpus.json` row (`canonicalization_failed` class, D-09) + `CONFORMANCE.md` regen
- [ ] `ci.security` alias edit naming the new suite (D-08)
- [ ] Framework install: none — ExUnit bundled

## Architecture Patterns

### System Architecture Diagram

```
ASSUR-02 (real signing path):
  FakeIdP.build_response(opts)                 [test caller builds protocol fields]
        │
        ▼
  FakeIdP.sign/2  ──delegates──►  XmldsigSigner.sign_response/1   (D-01 promotion seam)
        │                              │
        │                              ├─ parse_tree! (Saxy)         [self-parse emitted bytes]
        │                              ├─ digest_for(Assertion)      [PureBeam.canonicalize — verifier's engine]
        │                              ├─ sign_signed_info(SignedInfo) [C14N.serialize — verifier's engine]
        │                              └─ inject DigestValue + SignatureValue in place
        ▼
  base64(signed_xml)  +  FakeIdP.self_signed_cert_pem/0  (D-03)

ASSUR-01 (adversarial corpus — NEW :adversarial_crypto suite):
  genuine signed doc ── mutate (per recipe) ──► XML
        │
        ▼
  PureBeam.parse_safely(xml, [])  ──►  parsed_doc
        │
        ▼
  Signature.verify(parsed_doc, connection, cert_chain)   [the FROZEN Phase-29 verify path]
        │
        ├─ forged-sig / wrong-key      → {:error, :invalid_signature}
        ├─ tampered / c14n-differential → {:error, :digest_mismatch}
        ├─ ECDSA (carry-over)          → {:error, :unsupported_signature_algorithm}
        └─ genuine (positive control)  → {:ok, %SignedNode{}}

Static corpus (JSON — separate path, canonicalize-only):
  priv/security_corpus.json ──► corpus_security_test.exs evaluate_fixture/1
        │                            (parse_safely → canonicalize; NEVER Signature.verify/4)
        ▼
  c14n REJECTION row (D-09) → {:error, :canonicalization_failed}   [NOT :digest_mismatch]
        │
        ▼
  mix relyra.conformance ──► CONFORMANCE.md ──► ci.conformance --check (drift gate)

Gate wiring:
  mix ci.security ─► ci.conformance (--check first) ─► ... ─► new :adversarial_crypto suite (D-08)
```

### Recommended Project Structure
```
lib/relyra/test_support/
├── fake_idp.ex            # MODIFY: sign/2 delegates to signer; add CanonicalizationMethod; drop whitespace-collapse; add self_signed_cert_pem/0
└── xmldsig_signer.ex      # UNCHANGED (the promotion target; already exposes sign_response/1, self_signed_cert_pem/0)

test/security/xml/         # OR test/relyra/security/ — executor's discretion
└── adversarial_crypto_test.exs   # NEW: @tag :adversarial_crypto — 5 categories + positive + ECDSA carry-over, FakeIdP-driven

priv/
└── security_corpus.json   # MODIFY: add 1 c14n-differential REJECTION row (canonicalization_failed class)

CONFORMANCE.md             # REGENERATE via mix relyra.conformance (mandatory, D-09)
mix.exs                    # MODIFY: name the new suite into ci.security (D-08)
```

### Pattern 1: FakeIdP real-signing promotion (D-01/D-02/D-03)
**What:** Make `FakeIdP.sign` produce a genuinely-signed Response by delegating to the existing signer; the signer re-derives digest/signature from the emitted bytes (self-parse), so byte-alignment is structural.
**When to use:** ASSUR-02.
**Example:**
```elixir
# Source: synthesized from fake_idp.ex:65-75 + xmldsig_signer.ex:161-194
# FakeIdP.sign — promoted (D-01). The signer's sign_response/1 reads the
# <Reference URI="#..."> to locate the Assertion, computes a real DigestValue
# (PureBeam.canonicalize) + SignatureValue (C14N.serialize + :public_key.sign),
# and injects both in place. FakeIdP only needs to emit the structure-only shape
# WITH a <CanonicalizationMethod> and WITHOUT the whitespace collapse.
def sign(%Builder{} = builder, opts) do
  ensure_not_prod!()
  ensure_keypair!()
  xml = response_xml(builder, opts)               # structure-only shape (D-02 corrected)
  %{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.sign_response(xml)
  Base.encode64(signed_xml, padding: false)
end

# D-03: expose the trust cert
defdelegate self_signed_cert_pem(), to: Relyra.TestSupport.XmldsigSigner
```

**The D-02 shape diff that MUST be reconciled** (three differences, only the first is load-bearing for `sign_response/1`):
```
FakeIdP.response_xml (fake_idp.ex:110-136):       XmldsigSigner.response_xml (xmldsig_signer.ex:236-264):
  <SignedInfo>                                       <SignedInfo>
    <SignatureMethod .../>                             <CanonicalizationMethod Algorithm=".../xml-exc-c14n#"/>  ◄── FakeIdP MISSING
    <Reference URI="#id">                              <SignatureMethod .../>
      <DigestMethod .../>                              <Reference URI="#id">
    </Reference>          ◄── no DigestValue           <DigestMethod .../>
  </SignedInfo>           (sign_response injects it)   <DigestValue/>  (placeholder)
  ... String.replace(~r/\s+/," ")  ◄── whitespace      </Reference>
      collapse + namespaces on Issuer/Assertion      </SignedInfo>  (whitespace-free, no SAML xmlns)
```
- **Missing `<CanonicalizationMethod>` (CRITICAL):** `sign_response/1` canonicalizes the SignedInfo via `C14N.serialize` and the verifier reads `signed_info_prefix_list/1` (`signature.ex:380-382`) from the SignedInfo. The element must be present so signer and verifier see the SAME SignedInfo bytes. **Add it.**
- **Whitespace collapse (`String.replace(~r/\s+/, " ")`, `fake_idp.ex:134`):** Because `sign_response/1` self-parses the EMITTED bytes and binds the EXACT nodes, whitespace inside SignedInfo affects the canonical SignedInfo bytes BUT the signer signs whatever it emits — so the positive control still passes. HOWEVER, the verifier canonicalizes the SAME emitted bytes, so it stays aligned. The whitespace collapse is therefore NOT strictly fatal to the positive control (self-parse makes it self-consistent). **Recommend dropping it anyway** (D-02 says to) to match the signer's whitespace-free convention and avoid edge cases where collapsed whitespace inside `<DigestValue>`/text nodes interacts with C14N text-escaping. LOW residual risk either way; dropping is the lower-risk, decision-aligned choice.
- **SAML namespaces (`xmlns="urn:oasis:names:tc:SAML:2.0:assertion"` on Issuer/Assertion, `fake_idp.ex:112,114`):** The signer's shape omits these; FakeIdP carries them. This is FINE — `sign_response/1` self-parses and the verifier re-parses the same bytes, so namespaces are consistent. NO change required here (the namespaces make FakeIdP's output more realistic). Do NOT strip them.

### Pattern 2: Adversarial recipe via genuine-then-mutate (D-05/D-06)
**What:** Mint a genuine signed doc, apply a category-specific mutation, assert the typed rejection.
**When to use:** Every ASSUR-01 negative.
**Example:**
```elixir
# Source: signature_crypto_test.exs:81-90 (forged), :215-224 (wrong-key), :226-235 (tampered)
# forged-sig: replace SignatureValue with same-length random base64
forged_b64 = Base.encode64(:crypto.strong_rand_bytes(byte_size(sig_bytes)))
# wrong-key: verify the genuine doc against a DIFFERENT cert
wrong_cert_chain = [throwaway_cert_pem()]            # second, throwaway keypair
# tampered-content: rewrite NameID after signing
XmldsigSigner.signed_response(tamper_name_id: "attacker@evil.example.com")
# positive control: genuine, FakeIdP cert
assert {:ok, %SignedNode{}} = Signature.verify(parsed_doc, conn, FakeIdP-cert-chain)
```

### Pattern 3: C14N-preserved mutation for the digest-mismatch case (D-06)
**What:** A post-signing mutation into the signed `<Assertion>` subtree that exclusive-C14N PRESERVES (so the recomputed digest differs), NOT one C14N normalizes away.
**When to use:** The NEW c14n-differential `:digest_mismatch` case.
**Recommended mutation:** **Add a new attribute to the `<Assertion>` apex element** (e.g. `<Assertion ID="assertion-1" Foo="bar">`), applied post-signing via a `String.replace`-style injection mirroring `maybe_tamper_name_id` (`xmldsig_signer.ex:317-328`). Adding a non-namespace attribute is unambiguously C14N-PRESERVED (PROVENANCE.md: attrs are sorted but never DROPPED; a new attribute changes the canonical byte stream → digest differs → `:digest_mismatch`).
**Example:**
```elixir
# Mirror maybe_tamper_name_id (xmldsig_signer.ex:317-328): mutate AFTER signing,
# do NOT recompute the digest/signature. The SignatureValue still verifies against
# SignedInfo; only the referenced Assertion's canonical bytes change.
signed = XmldsigSigner.signed_response()
mutated_xml =
  String.replace(
    signed.response_xml,
    "<Assertion ID=\"assertion-1\">",
    "<Assertion ID=\"assertion-1\" Foo=\"bar\">",
    global: false
  )
{:ok, parsed_doc} = PureBeam.parse_safely(mutated_xml, [])
assert {:error, %Error{type: :digest_mismatch}} =
         Signature.verify(parsed_doc, connection(), signed.cert_chain)
```

### Anti-Patterns to Avoid
- **Second signer inside FakeIdP** — re-implementing crypto in `FakeIdP` (D-01 violation). Creates a divergent canonicalizer; the positive control would pass for the wrong reason (T-29-15).
- **C14N-normalized mutation for the digest-mismatch case** — see "C14N pitfall mutations to AVOID" below. A no-op mutation leaves the digest unchanged → the fixture falsely passes `{:ok}`.
- **JSON row asserting `:digest_mismatch` under `parser_differential_and_c14n` class** — the `evaluate_fixture/1` branch (`:186-189`) stops at `canonicalize` and never reaches `verify_reference_digest`. The row would fail the `evaluate_fixture` assertion. Use `canonicalization_failed` for the JSON row (D-09); the `:digest_mismatch` proof lives in the new suite (D-06).
- **Stripping FakeIdP's SAML namespaces** — they make FakeIdP realistic and the self-parse keeps signer/verifier aligned. No need to match the signer's namespace-free shape.

### C14N pitfall mutations to AVOID (D-06, from PROVENANCE.md)
These mutations exclusive-C14N NORMALIZES AWAY — the recomputed digest would be UNCHANGED, so the fixture would falsely verify `{:ok}` (a silent assurance hole):

| Mutation to AVOID | Why C14N normalizes it away | PROVENANCE ref |
|-------------------|------------------------------|----------------|
| **Attribute reordering** | C14N sorts attributes by resolved-URI-then-local — reordering is a no-op | "Attribute sort by resolved URI then local (Pitfall 8)" (`PROVENANCE.md:40-41`) |
| **Adding an UNUSED inherited namespace declaration** | Exclusive-C14N OMITS namespaces not visibly utilized in the subtree | "No over-render (Pitfall 1) — `ext` ... never used ... omitted" (`PROVENANCE.md:38-39`) |
| **Self-closing ⇄ expanded empty element** | C14N always expands `<X/>` → `<X></X>` — both canonicalize identically | "Empty-element expansion" (`PROVENANCE.md:42`) |
| **Re-escaping already-equivalent text (e.g. `&#65;` vs `A`)** | C14N normalizes character references to canonical form | "Text escaping + UTF-8 (Pitfalls 5/6)" (`PROVENANCE.md:43-44`) |
| **Reformatting whitespace INSIDE an attribute value vs equivalent** | attribute-value normalization | implied by C14N 1.0 attribute-value normalization |

**C14N-PRESERVED mutations that DO change the digest (any of these works):**
- **Added attribute** on a subtree element (recommended — simplest, unambiguous).
- **Added child element** inside the Assertion subtree.
- **A visibly-utilized namespace declaration** (a namespace actually USED by a new/changed attribute or element) — more complex; prefer the added-attribute form.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Genuine XMLDSig signing in FakeIdP | A second digest/signature pipeline | `XmldsigSigner.sign_response/1` (D-01) | A divergent canonicalizer = the T-29-15 false-positive. The signer self-parses to bind the verifier's exact nodes. |
| Throwaway wrong-key cert | A new keypair-and-cert helper | `throwaway_cert_pem/0` (`signature_crypto_test.exs:260-264`) | Already exists; promote it. Generated locally (NOT in the signer module — the signer reuses FakeIdP's key only). |
| FakeIdP trust cert | Re-deriving a cert from `FakeIdP.keypair()` | `XmldsigSigner.self_signed_cert_pem/0` (`xmldsig_signer.ex:204-211`) | Already derives the self-signed PEM from FakeIdP's key via `pkix_test_root_cert/2`. |
| JSON corpus drift check | A bespoke diff | `mix relyra.conformance --check` (D-09) | Built-in; `ci.conformance` already runs it. |
| Constant-time digest compare | Manual byte compare | `:crypto.hash_equals/2` (already in `verify_reference_digest`) | Length-guarded before the call (`signature.ex:351`). Not your concern in this phase (verify is frozen). |

**Key insight:** Phase 30 builds NO crypto. Everything needed exists in Phase 29 artifacts; the work is *wiring + two precise mutations/rows*. The biggest "hand-roll" temptation — a second signer in FakeIdP — is exactly what D-01 forbids.

## Runtime State Inventory

> This is a refactor/promotion phase (FakeIdP gains real signing) — inventory included.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no databases store FakeIdP output; the keypair is a runtime `:persistent_term` regenerated per test run (`fake_idp.ex:85-95`). | None — verified by grep: `:persistent_term.get({FakeIdP, :rsa_2048_keypair})` is the only state, in-memory. |
| Live service config | None — FakeIdP is in-process test support; no external service. | None. |
| OS-registered state | None — no OS registration; `@prod_build` guard prevents prod compilation (`fake_idp.ex:11,97-101`). | None. |
| Secrets/env vars | None — no secrets; the RSA key is generated at runtime, never persisted, never committed (`29-04-SUMMARY.md` "no committed key material"). | None. |
| Build artifacts | None new. No package install, no egg-info/compiled-binary equivalent. | None. |
| **Callers of `FakeIdP.sign` (blast radius of D-01/D-02)** | Only `test/test_support_demo_test.exs:31` (via `sign_saml_response/2` → `FakeIdP.sign`, `test_support.ex:92`). It posts to a STUB controller (`Relyra.TestSupportDemoController`) that asserts `:current_user` directly and does NOT run real verification — so changing FakeIdP's signed output does NOT break it. `auto_refresh_test.exs` uses `FakeIdP.keypair()` directly (`:531`), reimplementing signing inline — NOT affected by the `sign/2` change. | Verify `mix test test/test_support_demo_test.exs` (in `ci.docs`) stays green after the D-02 shape change. No code edit expected. |

**The canonical question — after FakeIdP's shape changes, what still references the old shape?** Only the demo test (stub controller, unaffected) and the inline signer in `auto_refresh_test.exs` (uses the key, not `sign/2`). The blast radius is effectively zero. This is why D-01's promotion is low-risk.

## Common Pitfalls

### Pitfall 1: c14n-differential REJECTION row routed to the wrong evaluator (HIGHEST RISK)
**What goes wrong:** Adding a JSON corpus row with `class: "parser_differential_and_c14n"` and `expected_error_type: "digest_mismatch"` — the row fails the `corpus_security_test.exs` "manifest fixtures map to expected_error_type" test (`:11-17`).
**Why it happens:** `evaluate_fixture/1` for that class (`:186-189`) runs `parse_safely → canonicalize` and returns the `canonicalize` result — it NEVER calls `Signature.verify/4`, so it can NEVER produce `:digest_mismatch`. A complete, well-formed document with a tampered subtree would actually `canonicalize` SUCCESSFULLY (`{:ok, ...}`), failing the `assert {:error, ...}` outright.
**How to avoid:** Split the proof: (a) the `:digest_mismatch` c14n-differential proof lives in the NEW crypto-verify suite (D-04/D-06); (b) the JSON row (D-09) uses `class: "parser_differential_and_c14n"` with `expected_error_type: "canonicalization_failed"` (reuses the existing evaluator branch, which fails closed on the bare `parsed_doc` map handle — see `pure_beam.ex:509-516` and the existing `c14n-differential-001` row). The two are complementary, not the same case.
**Warning signs:** `mix test test/security/xml/corpus_security_test.exs --only security_corpus` fails on the new row with `{:ok, ...}` where `{:error, ...}` expected, or a type mismatch.

### Pitfall 2: Suite not named in the alias = not gating
**What goes wrong:** Building the new suite but only running it via bare `mix test` — `mix ci.security` never executes it, so success criterion #4 is unmet and the gate is hollow.
**Why it happens:** `ci.security` (`mix.exs:152-169`) names specific test files/tags explicitly; `signature_crypto_test.exs` is currently NOT named (verified: zero matches for `signature_crypto_test` in `mix.exs`). A suite outside the alias does not gate.
**How to avoid:** Add the new suite's file path (and/or `--only adversarial_crypto`) to the `ci.security` alias list (D-08), with `--warnings-as-errors`. Verify by running `mix ci.security` and confirming the new suite's test count appears.
**Warning signs:** `mix ci.security` passes but the adversarial test count is 0; the suite only runs under `mix test`.

### Pitfall 3: CONFORMANCE.md drift on the JSON row add
**What goes wrong:** Adding the JSON row (D-09) but forgetting to regenerate `CONFORMANCE.md` → `ci.conformance --check` fails on drift (the FIRST step of `ci.security`, `mix.exs:153`).
**Why it happens:** `relyra.conformance --check` (`relyra.conformance.ex:58-77`) compares the on-disk `CONFORMANCE.md` byte-for-byte against the freshly-rendered manifest. The `cve_summary_lines` count (`:114-126`) and the `CVE-REG-01 Regression Coverage` table (`:156-165`) both change when a security row is added.
**How to avoid:** After editing `priv/security_corpus.json`, run `mix relyra.conformance` (NO `--check`) to regenerate, commit the updated `CONFORMANCE.md`, THEN verify `mix relyra.conformance --check` passes.
**Warning signs:** `mix ci.security` aborts at the first line with "drift detected for .../CONFORMANCE.md; rerun mix relyra.conformance".

### Pitfall 4: `--warnings-as-errors` aborts on an unused alias/import
**What goes wrong:** The whole `ci.security` lane runs with `--warnings-as-errors`; a leftover unused `alias`/`import` in the new suite (or in FakeIdP after promotion) aborts the run even though tests pass — exactly the issue auto-fixed in `29-04-SUMMARY.md:106-112`.
**Why it happens:** Every test line in the alias carries `--warnings-as-errors`; an unused module attribute, alias, or import is a warning.
**How to avoid:** Keep imports tight in the new suite; after the FakeIdP promotion, remove any now-unused `Builder`/helper references. Run `mix compile --warnings-as-errors` + the suite with the flag before declaring done.
**Warning signs:** Tests pass count is correct but the lane exits non-zero with "Compilation failed (warnings as errors)".

### Pitfall 5: Missing `<CanonicalizationMethod>` breaks the positive control
**What goes wrong:** Promoting `FakeIdP.sign` to delegate to `sign_response/1` WITHOUT adding `<CanonicalizationMethod>` to FakeIdP's `<SignedInfo>` — the SignedInfo the signer canonicalizes/signs differs in shape from what a real verifier expects, and `signed_info_prefix_list/1` reads the (now-absent) CanonicalizationMethod.
**Why it happens:** D-02's most load-bearing diff. `sign_response/1` signs whatever SignedInfo it parses; if the element is absent, the SignedInfo is malformed relative to the XMLDSig contract (even if self-consistent).
**How to avoid:** Add `<CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>` as the FIRST child of FakeIdP's `<SignedInfo>` (mirroring `xmldsig_signer.ex:254`). Verify the FakeIdP-driven positive control returns `{:ok, %SignedNode{}}`.
**Warning signs:** The FakeIdP positive control returns `:invalid_signature` or `:digest_mismatch` despite a genuine signature.

### Pitfall 6: WR-03 brushed by an XSW-shaped adversarial input (scope creep risk)
**What goes wrong:** Designing a crypto-layer XSW adversarial case (genuine signature over assertion-A, attacker assertion-B injected) that exposes WR-03 (Reference/@URI not bound to the consumed node) — tempting the executor to "fix" it, violating D-10.
**Why it happens:** The adversarial corpus naturally probes signed-node binding; WR-03 is the live defense-in-depth gap there.
**How to avoid:** Per D-10, either avoid that exact input shape, or assert the CURRENT behavior and annotate "WR-03 follow-up — do not fix in-phase." A WR-03 fix is a production crypto-correctness change deserving its own plan + review (it modifies `pure_beam.ex` `signed_candidates/1`).
**Warning signs:** A planned task touches `lib/relyra/security/xml/pure_beam.ex` `signed_candidates/1` or `lib/relyra/security/signature.ex` — that is OUT of scope.

## Code Examples

### Adding the JSON corpus REJECTION row (D-09)
```json
// Append to priv/security_corpus.json (a new element in the top-level array).
// Schema enforced by corpus_security_test.exs:126-141 — every field below is required.
// Class "parser_differential_and_c14n" routes through evaluate_fixture/1 :186-189
// (parse_safely → canonicalize), which fails closed with :canonicalization_failed
// on the bare parsed_doc map handle (pure_beam.ex:509-516).
{
  "id": "c14n-differential-rejection-002",
  "class": "parser_differential_and_c14n",
  "family": "signature_wrapping",
  "requirement_ids": ["CVE-REG-01", "ASSUR-01"],
  "expected_error_type": "canonicalization_failed",
  "provenance": {
    "source": "Phase 30 adversarial crypto assurance",
    "kind": "ported-fixture",
    "captured_at": "2026-05-24"
  },
  "source_ref": "relyra:phase-30:c14n-differential-rejection",
  "xml": "<Response ...>...</Response>",
  "notes": "C14N-differential REJECTION: the pure-BEAM seam fails closed (:canonicalization_failed) on an incomplete canonicalization handle; the :digest_mismatch crypto proof lives in the adversarial_crypto suite (ASSUR-01)."
}
```
Note: `requirement_ids` accepts multiple IDs (`corpus_security_test.exs:129` only requires non-empty list); tagging `ASSUR-01` traces the row to the phase. The conformance generator reads `family`, `class`, `expected_error_type`, `provenance.source`/`kind`, `notes` (`relyra.conformance.ex:156-165`).

### Naming the new suite into ci.security (D-08)
```elixir
# In mix.exs aliases, "ci.security" list. Add ONE of these forms after the
# existing security_corpus / gate02_c14n lines (mix.exs:160-161):

# Form A — dedicated tag (recommended for clarity):
"test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors",

# Form B — reuse the existing :security_corpus tag (one fewer concept):
# (tag the new suite @tag :security_corpus and rely on the existing line at :160
#  IF the file is added to that line's path list)
```
Run `mix relyra.conformance` (regen) before running `mix ci.security` (which `--check`s first).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| FakeIdP emits structure-only "signature" (empty SignedInfo, no DigestValue/SignatureValue) | FakeIdP delegates to a genuine signer (real DigestValue + SignatureValue) | Phase 30 (this phase) | The suite exercises REAL verification, not structure-only acceptance (ASSUR-02). |
| Crypto proofs in `signature_crypto_test.exs` outside `ci.security` | Promoted into a gated `:adversarial_crypto` suite named in the alias | Phase 30 | The proof gates every build (ASSUR-01 success #4). |
| JSON corpus evaluates parse/select/canonicalize only | Same (UNCHANGED) — the crypto proof lives in a separate verify-driving suite | Phase 30 | Avoids forcing a runtime cert into static JSON (D-04). |

**Deprecated/outdated:** Nothing deprecated this phase. The `corpus_security_test.exs` evaluator stays as-is (do NOT extend it to call `Signature.verify/4` — that would re-introduce the runtime-cert serialization problem D-04 avoids).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Adding `<CanonicalizationMethod>` + dropping whitespace-collapse is sufficient for the FakeIdP positive control to pass; SAML namespaces need no change. | Pattern 1 / Pitfall 5 | LOW — verified by reasoning over `sign_response/1`'s self-parse; the planner must include a "FakeIdP positive control returns {:ok}" verification step. If wrong, the fix is local to FakeIdP's `response_xml`. |
| A2 | An added non-namespace attribute on the `<Assertion>` apex is C14N-PRESERVED and yields `:digest_mismatch`. | Pattern 3 | LOW — PROVENANCE.md confirms attrs are sorted, never dropped. If wrong (it isn't), fall back to "added child element." The plan should assert `:digest_mismatch` explicitly so a no-op mutation surfaces immediately. |
| A3 | A `parser_differential_and_c14n` JSON row with an incomplete-canonicalization handle yields `:canonicalization_failed` (matching the existing `c14n-differential-001` row's mechanism). | Code Examples / Pitfall 1 | LOW — the existing `c14n-differential-001` row (`security_corpus.json:62-76`) already proves this exact pattern passes. The new row mirrors it. |
| A4 | `Jason` is reliably available in `:test` (transitive) for `conformance_fixtures.ex`. | Standard Stack | VERY LOW — `mix.lock:13` pins jason 1.4.5 via credo/sobelow/ecto/req; the existing conformance tests already pass using it. |
| A5 | The ECDSA fail-closed assertion should be carried into the gated suite as a 6th assertion (not a 6th category). | Validation Architecture | LOW — discretionary recommendation; if the planner disagrees, ECDSA stays proven in `signature_crypto_test.exs` but the planner should then ensure THAT file is also gated, else `:unsupported_signature_algorithm` falls outside `ci.security`. |

## Open Questions (RESOLVED)

1. **Which file location for the new suite — `test/security/xml/` or `test/relyra/security/`?**
   - What we know: Both conventions exist; `corpus_security_test.exs` lives in `test/security/xml/`, `signature_crypto_test.exs` in `test/relyra/security/`. CONTEXT.md leaves this to discretion (D-08 Discretion).
   - Recommendation: `test/security/xml/adversarial_crypto_test.exs` — colocated with the other security-corpus suites that `ci.security` names, easiest to add to the alias line.
   - **RESOLVED:** Plan 30-02 adopts `test/security/xml/adversarial_crypto_test.exs` (the recommended location).

2. **Drive the four crypto categories through `FakeIdP.sign` end-to-end, or through `XmldsigSigner` directly?**
   - What we know: D-01 Discretion + Specific Ideas prefer FakeIdP end-to-end "where practical" so the suite literally exercises ASSUR-02. Both go through the SAME signing path post-promotion.
   - Recommendation: Positive control + at least one negative through `FakeIdP.sign` end-to-end (Base.decode64 the output, then `PureBeam.parse_safely`); the forged/wrong-key/tampered/c14n-differential negatives can use `XmldsigSigner.signed_response/1` directly (cleaner mutation seam via `tamper_name_id:` and direct `response_xml` access). This satisfies "literally exercises ASSUR-02" without contorting every recipe through base64.
   - **RESOLVED:** Plan 30-02 drives the positive control + ≥1 negative through `FakeIdP.sign` end-to-end, with the remaining negatives mutated via `XmldsigSigner.signed_response/1` directly (the recommended split).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP `:public_key` | signing + verify | ✓ | OTP 28 (erts 16.3) | — |
| Erlang/OTP `:crypto` | hash + random | ✓ | OTP 28 | — |
| Erlang/OTP `:json` | corpus JSON decode | ✓ | OTP 27+ (used in repo) | — |
| `Jason` | conformance manifest decode | ✓ | 1.4.5 (mix.lock) | — |
| `Saxy` | parse tree | ✓ | 1.6 (mix.exs) | — |
| ExUnit | the new suite | ✓ | Elixir 1.19.5 | — |
| Docker | NOT required (D-07 — no new golden) | n/a | — | n/a — REJECTION fixtures claim no canonical bytes |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None. The phase is pure-Elixir; CI stays native-toolchain-free (D-07, consistent with `ci.security` being pure-Elixir per `fake_idp` code context line 89).

## Security Domain

> `security_enforcement` is not set in `.planning/config.json`. This phase implements NO new production security control — it consolidates and gates EXISTING Phase 29 crypto. The ASVS-relevant controls (V6 Cryptography, V5 Input Validation) are ALREADY implemented and frozen; Phase 30 only proves them.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control (already implemented — Phase 29) |
|---------------|---------|-----------------|
| V2 Authentication | yes (the proof) | XMLDSig assertion signature verification (`Signature.verify/4`) — the proof THIS phase gates. |
| V5 Input Validation | yes | DOCTYPE/ENTITY/size guards (`PureBeam.parse_safely`), algorithm allowlist (`AlgorithmPolicy`) — frozen. |
| V6 Cryptography | yes | `:public_key.verify` of canonicalized SignedInfo + `:crypto.hash_equals` digest compare — frozen; never hand-rolled (OTP). |
| V3 Session Management | no | Out of scope for this phase. |
| V4 Access Control | no | Out of scope. |

### Known Threat Patterns for the adversarial corpus (XMLDSig SP verification)

| Pattern | STRIDE | Standard Mitigation | Proven by category |
|---------|--------|---------------------|--------------------|
| Forged SignatureValue (valid structure) | Spoofing | `:public_key.verify` against configured cert | forged-sig → `:invalid_signature` |
| Wrong signing key | Spoofing | Trust source = configured `cert_chain`, never KeyInfo | wrong-key → `:invalid_signature` |
| Content tampering (NameID swap) | Tampering | DigestValue recompute over canonicalized referenced element | tampered-content → `:digest_mismatch` |
| Canonicalization differential | Tampering | C14N-preserved mutation changes recomputed digest | c14n-differential → `:digest_mismatch` (NEW) |
| Algorithm substitution (ECDSA/unknown) | Spoofing | digest-atom gate fails closed before verify | ECDSA → `:unsupported_signature_algorithm` (carry-over) |
| Signature wrapping (XSW) | Tampering | duplicate-ID / single-candidate selection (parse layer) | JSON corpus (`duplicate_xml_id`/`ambiguous_signed_node`); crypto-layer XSW = WR-03 (NOTE-as-followup, D-10) |
| Document-KeyInfo trust | Elevation | KeyInfo rejected as trust source | proven in `signature_crypto_test.exs:164-170` + JSON `cve-2024-45409-keyinfo-001` |

## Sources

### Primary (HIGH confidence — in-repo, verified this session)
- `lib/relyra/test_support/xmldsig_signer.ex` — the signer to promote (`sign_response/1` `:161-194`, `self_signed_cert_pem/0` `:204-211`, `maybe_tamper_name_id` `:317-328`, keypair reuse `:208,275-281`, SignedInfo shape `:252-264`).
- `lib/relyra/test_support/fake_idp.ex` — FakeIdP shape (`response_xml` `:103-136`: missing CanonicalizationMethod `:127-130`, whitespace-collapse `:134`, SAML namespaces `:112,114`; keypair `:85-95`; `sign/2` `:65-75`).
- `lib/relyra/security/signature.ex` — frozen verify path (`cryptographically_verify` `:205-233`, `verify_signature_math` `:306-339`, `verify_reference_digest` `:346-374`, `digest_atom` `:249-262`, `signed_info_prefix_list` `:380-382`).
- `test/relyra/security/signature_crypto_test.exs` — all 5 recipes + positive control (`:202-255`, forged `:81-90`, wrong-key `throwaway_cert_pem/0` `:215-224,260-264`, tampered `:226-235`, positive `:203-213`, ECDSA `:131-141`, genuine_signed_doc `:293-360`).
- `test/security/xml/corpus_security_test.exs` — corpus GATE structure, provenance enforcement `:126-141`, the CANONICALIZE-ONLY `evaluate_fixture/1` `:161-194` (the Pitfall-1 routing constraint).
- `priv/security_corpus.json` — row schema; existing `c14n-differential-001` `canonicalization_failed` row `:62-76` (the pattern the D-09 row mirrors).
- `lib/relyra/security/xml/corpus_gate.ex` — runtime gate; canonicalize branch returns `:ok` (no verify) `:153-154`.
- `lib/mix/tasks/relyra.conformance.ex` — `--check` drift gate `:58-77`, security-rows table `:156-165`, cve summary `:114-126`.
- `lib/relyra/conformance_fixtures.ex` — `load_manifest!` uses `Jason.decode!` `:14`, required keys `id requirement_ids provenance` `:4`.
- `mix.exs` — `ci.security` alias `:152-169` (no `signature_crypto_test` named — verified by grep), `ci.conformance` `:148-153`.
- `lib/relyra/security/xml/c14n.ex` — `serialize/2` `:79-97`, `prefix_list_from_transforms/1` `:164-178` (C14N pitfall behaviors).
- `test/fixtures/security/xml/parser_differential_and_c14n/PROVENANCE.md` — the C14N pitfall catalog (attr sort Pitfall 8, no-over-render Pitfall 1, empty-element expansion, text escaping) that constrains the D-06 mutation choice.
- `lib/relyra/security/xml.ex` — `xml_error_type` union includes `:digest_mismatch`/`:unsupported_signature_algorithm`/`:canonicalization_failed` `:8-23`.
- `.planning/phases/29-cryptographic-xmldsig-verification/29-04-SUMMARY.md` — "promote XmldsigSigner into FakeIdP" guidance `:171`, triage blast-radius, T-29-15/16/17.
- `.planning/todos/pending/29-code-review-followups.md` — WR-03 definition (Reference/@URI binding) for the NOTE-as-followup.
- `.planning/config.json` — `nyquist_validation: true`, no `security_enforcement` key.
- Verified runtime: `elixir --version` → Elixir 1.19.5 / OTP 28; `mix.lock` → jason 1.4.5, saxy via mix.exs.

### Secondary (MEDIUM) / Tertiary (LOW)
- None — this phase required no external/web sources. All findings are in-repo and tool-verified.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all in-repo / OTP, versions verified against `mix.lock` + `elixir --version`.
- Architecture (promotion seam, corpus routing): HIGH — traced through actual `evaluate_fixture/1`, `sign_response/1`, `verify_reference_digest` code paths.
- Pitfalls: HIGH — Pitfall 1 (c14n routing) and Pitfall 5 (CanonicalizationMethod) are derived directly from code, not training data.
- Validation Architecture / bypass-space: HIGH for the error→category map (code-verified); MEDIUM for the "dense enough" verdict (a reasoned judgment over the known XMLDSig threat model, not an exhaustive formal proof).

**Research date:** 2026-05-24
**Valid until:** 2026-06-23 (stable — pure in-repo dependencies; the only invalidation risk is if Phase 29 verify code changes, which is out of scope for Phase 30).
