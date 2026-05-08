# Phase 27: Adopter Onboarding Polish and Case Studies - Pattern Map

**Mapped:** 2026-05-08
**Files analyzed:** 11 likely Phase 27 files/surfaces
**Analogs found:** 10 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | config | transform | `README.md` | exact |
| `guides/getting_started.md` | config | transform | `guides/getting_started.md` | exact |
| `guides/recipes/okta.md` | config | transform | `guides/recipes/okta.md` | exact |
| `guides/recipes/entra.md` | config | transform | `guides/recipes/entra.md` | exact |
| `guides/recipes/google_workspace.md` | config | transform | `guides/recipes/google_workspace.md` | exact |
| `guides/<new day-1 proof guide>.md` | config | request-response proof narrative | `SECURITY_REVIEW.md` + `SECURITY_REVIEW_EVIDENCE.md` | partial |
| `guides/<new case study docs>.md` | config | request-response + ops narrative | `guides/recipes/*.md` + `docs/security_boundary.md` | partial |
| `test/<new batteries_included_proof_test>.exs` | test | request-response | `test/test_support_demo_test.exs` | role-match |
| `test/mix/<new install-proof test>.exs` or extension of `test/mix/relyra_install_test.exs` | test | file-I/O | `test/mix/relyra_install_test.exs` | exact |
| `mix.exs` | config | batch | `mix.exs` (`ci.security`, `ci.verify`) | exact |
| `lib/mix/tasks/<new docs/proof task>.ex` | mix task | batch | `lib/mix/tasks/relyra.conformance.ex` / `lib/mix/tasks/relyra.security_review.ex` | role-match |

## Pattern Assignments

### `README.md` -> canonical router, not a full docs dump

**Analog:** [README.md](/Users/jon/projects/relyra/README.md:21)

**Current shape to preserve**
- Short install block first, then a small “Quick start”, then explicit guide links.
- Later sections can hold advanced operations, but the top of file stays the routing surface.

**Copy these patterns**
- Install command and scaffold step at [README.md](/Users/jon/projects/relyra/README.md:21).
- “Quick start” as a numbered spine at [README.md](/Users/jon/projects/relyra/README.md:37).
- Guide-list handoff at [README.md](/Users/jon/projects/relyra/README.md:43).
- Narrow pointer style from [README.md](/Users/jon/projects/relyra/README.md:176): one short pointer to the deeper canonical doc, not duplicated prose.

**Use for Phase 27**
- Rework the top of `README.md` into one obvious flow: install -> scaffold -> Getting Started -> provider runbook.
- Keep bulk ops, scheduled refresh, and security material in lower sections or linked docs; do not let them compete with Day-1 entry.

---

### `guides/getting_started.md` -> short narrative spine with explicit branch point

**Analog:** [guides/getting_started.md](/Users/jon/projects/relyra/guides/getting_started.md:1)

**Current shape to preserve**
```markdown
## Testing against a real IdP
- FakeIdP for local development first
- hosted/manual smoke options second
- provider recipes third
```

**Supporting code seam**
- `Relyra.TestSupport` keeps the adopter helper surface intentionally small at [lib/relyra/test_support.ex](/Users/jon/projects/relyra/lib/relyra/test_support.ex:2).
- `FakeIdP` is explicitly test-only and protocol-correct at [lib/relyra/test_support/fake_idp.ex](/Users/jon/projects/relyra/lib/relyra/test_support/fake_idp.ex:2).

**Use for Phase 27**
- Expand this guide into the canonical Day-1 narrative, but keep the current “local proof first, real provider second” ordering.
- End each major step with a receipt, matching the explicit success-check preference in `27-CONTEXT.md`.

---

### Provider runbooks -> vendor terms + exact config example + common-failure table

**Analogs:** [guides/recipes/okta.md](/Users/jon/projects/relyra/guides/recipes/okta.md:1), [guides/recipes/entra.md](/Users/jon/projects/relyra/guides/recipes/entra.md:1), [guides/recipes/google_workspace.md](/Users/jon/projects/relyra/guides/recipes/google_workspace.md:1)

**Current shape to preserve**
- Provenance line: `Tested against: ...`
- Ordered sections: create app -> configure Relyra -> common issues
- Concrete `Relyra.Provider.apply_defaults/2` snippet in vendor-specific terminology
- Symptom/fix table for known footguns

**Code seam that should drive wording**
- Preset registry is explicit and limited to three supported providers at [lib/relyra/provider.ex](/Users/jon/projects/relyra/lib/relyra/provider.ex:83).
- Guide URL, display name, labels, and footguns are part of the provider contract at [lib/relyra/provider.ex](/Users/jon/projects/relyra/lib/relyra/provider.ex:76) and [lib/relyra/provider.ex](/Users/jon/projects/relyra/lib/relyra/provider.ex:145).

**Use for Phase 27**
- Keep each runbook authoritative and operator-facing.
- Derive field names, support claims, and footgun guidance from preset code, not generic SAML prose.
- Add explicit “Relyra owns / IdP owns / Host owns” boundaries using the same narrow-boundary style as security docs.

---

### New “batteries included” proof guide -> concise narrative doc backed by executable receipts

**Analogs:** [SECURITY_REVIEW.md](/Users/jon/projects/relyra/SECURITY_REVIEW.md:1), [SECURITY_REVIEW_EVIDENCE.md](/Users/jon/projects/relyra/SECURITY_REVIEW_EVIDENCE.md:5), [CONFORMANCE.md](/Users/jon/projects/relyra/CONFORMANCE.md:3)

**Copy these patterns**
- One provenance sentence at the top.
- Rerun-command section with exact commands.
- Link-oriented tables mapping claim -> seam -> proof command -> artifact.
- Avoid second-truth prose; point to code seams and generated artifacts instead.

**Best excerpt to copy**
```markdown
## Rerun Commands
- `mix ci.security`
- `mix ci.verify`
- `mix relyra.conformance --check`
```
From [SECURITY_REVIEW_EVIDENCE.md](/Users/jon/projects/relyra/SECURITY_REVIEW_EVIDENCE.md:5)

**Use for Phase 27**
- The proof guide should read like an adopter journey, but each step still ends in a concrete receipt: generated file, test pass, route mount, telemetry event, audit row, or diagnostic artifact.

---

### Fixture-app / generated-host proof -> prove the blessed install path, not a hand-made demo

**Analogs:** [lib/mix/tasks/relyra.install.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.install.ex:8), [test/mix/relyra_install_test.exs](/Users/jon/projects/relyra/test/mix/relyra_install_test.exs:4), [test/test_support_demo_test.exs](/Users/jon/projects/relyra/test/test_support_demo_test.exs:17)

**Installer pattern**
- Hand-rolled generator writes files directly and uses sentinel-guarded config blocks at [lib/mix/tasks/relyra.install.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.install.ex:29) and [lib/mix/tasks/relyra.install.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.install.ex:71).
- Ambiguous router edits fall back to explicit printed instructions instead of risky mutation at [lib/mix/tasks/relyra.install.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.install.ex:101).

**Golden-tree proof pattern**
```elixir
File.cd!(tmp_dir, fn ->
  Mix.Tasks.Relyra.Install.run(["--module", "DemoApp", "--repo", "demo-app"])
end)

assert File.exists?(connections)
assert File.read!(config) =~ "# --- Relyra START ---"
```
From [test/mix/relyra_install_test.exs](/Users/jon/projects/relyra/test/mix/relyra_install_test.exs:10)

**End-to-end helper proof pattern**
```elixir
conn = Phoenix.ConnTest.build_conn() |> setup_saml_connection(connection_id: "demo")
response = build_saml_response() |> sign_saml_response()
conn = post_saml_response(conn, Base.decode64!(response, padding: false))
assert_saml_login(conn, %{email: "alice@example.com"})
```
From [test/test_support_demo_test.exs](/Users/jon/projects/relyra/test/test_support_demo_test.exs:21)

**Use for Phase 27**
- If a fixture app is added, generate it from `mix relyra.install` inside the test lane or from checked-in generated output; do not hand-author a separate “sample app truth”.
- Reuse `FakeIdP` for the first executable receipt before any real IdP setup.

---

### New case-study docs -> recipe structure plus explicit ownership boundary

**Analogs:** provider recipe docs plus [docs/security_boundary.md](/Users/jon/projects/relyra/docs/security_boundary.md:5)

**Copy these patterns**
- Recipe docs provide ordered steps, config snippet, and failure table.
- Boundary docs provide explicit in-scope / out-of-scope ownership language.

**Use for Phase 27**
- Each case study should be a small operations narrative:
  named scenario -> exact wiring -> `Relyra owns` vs `Host owns` -> day-2 operations -> failure/recovery -> evidence surfaces.
- Keep the set small and opinionated; there is no existing large case-study catalog pattern to imitate.

---

### Mix task and generated-doc drift gate -> only if Phase 27 adds a committed proof artifact

**Analogs:** [lib/mix/tasks/relyra.conformance.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.conformance.ex:20), [lib/mix/tasks/relyra.security_review.ex](/Users/jon/projects/relyra/lib/mix/tasks/relyra.security_review.ex:20)

**Copy these patterns**
- `Mix.Task.run("app.start")`
- `OptionParser.parse/2` with `--output` and `--check`
- deterministic markdown rendering
- `check_report!/2` that raises on drift or missing target

**Use for Phase 27**
- Only introduce a new Mix task if the phase commits a generated proof artifact such as a “batteries included evidence” report.
- If the artifact is hand-authored narrative docs only, skip the task and keep verification in focused ExUnit + `rg` checks.

---

### CI / alias wiring -> serialized, narrow, drift-sensitive

**Analogs:** [mix.exs](/Users/jon/projects/relyra/mix.exs:78), [25-03-PLAN.md](/Users/jon/projects/relyra/.planning/phases/25-conformance-and-cve-regression-fixtures/25-03-PLAN.md:121), [26-03-PLAN.md](/Users/jon/projects/relyra/.planning/phases/26-security-audit-preparation-and-remediation/26-03-PLAN.md:116)

**Established pattern**
- Add a dedicated alias when readability helps (`ci.conformance`), then call it from `ci.security`.
- Keep file-scoped proof commands serialized when repo-backed state or generated artifacts are involved.
- Verify packet/doc existence with shell checks before heavier commands.

**Use for Phase 27**
- If there is a docs-proof lane, keep it deterministic and scoped:
  shell checks / generated artifact check / focused proof tests / any repo-backed fixture test.
- Do not broaden ordinary `mix test`.

## Prior PLAN Conventions To Reuse

**Primary analogs:** [25-03-PLAN.md](/Users/jon/projects/relyra/.planning/phases/25-conformance-and-cve-regression-fixtures/25-03-PLAN.md:1), [26-01-PLAN.md](/Users/jon/projects/relyra/.planning/phases/26-security-audit-preparation-and-remediation/26-01-PLAN.md:1), [26-02-PLAN.md](/Users/jon/projects/relyra/.planning/phases/26-security-audit-preparation-and-remediation/26-02-PLAN.md:1), [26-03-PLAN.md](/Users/jon/projects/relyra/.planning/phases/26-security-audit-preparation-and-remediation/26-03-PLAN.md:1)

- Split documentation-heavy work into narrow plans with one truth surface each: IA/router docs, proof artifact/tests, CI/drift enforcement, case studies.
- Keep front matter explicit: `files_modified`, `requirements`, `must_haves.truths`, `artifacts`, and `key_links`.
- In each task block, keep the repo style:
  `read_first` -> `files` -> `behavior` or `action` -> `acceptance_criteria` -> `verify` -> `done`.
- Write acceptance criteria as grep-able claims and verify commands as literal rerun commands.
- Separate narrative docs from executable proof. Phase 26 is the clearest precedent: docs explain the surface; generated artifacts and tests prove it.

## Shared Patterns

### Canonical entry point over peer docs
**Sources:** [README.md](/Users/jon/projects/relyra/README.md:37), [SECURITY_REVIEW.md](/Users/jon/projects/relyra/SECURITY_REVIEW.md:5)

- One file routes the reader.
- Deeper docs are linked, not allowed to compete as equal entry points.

### Exact claims tied to executable seams
**Sources:** [CONFORMANCE.md](/Users/jon/projects/relyra/CONFORMANCE.md:3), [SECURITY_REVIEW_EVIDENCE.md](/Users/jon/projects/relyra/SECURITY_REVIEW_EVIDENCE.md:14)

- Claims are strongest when expressed as claim -> seam -> proof command -> artifact.
- Generated docs should derive from repo state and support `--check` drift detection.

### Local-first adopter proof
**Sources:** [guides/getting_started.md](/Users/jon/projects/relyra/guides/getting_started.md:3), [test/test_support_demo_test.exs](/Users/jon/projects/relyra/test/test_support_demo_test.exs:21)

- First receipt should be `FakeIdP` or other local deterministic seam.
- Hosted IdP setup comes after the adopter has one successful local proof.

### Provider support matrix must match code reality
**Sources:** [README.md](/Users/jon/projects/relyra/README.md:8), [lib/relyra/provider.ex](/Users/jon/projects/relyra/lib/relyra/provider.ex:83), [27-CONTEXT.md](/Users/jon/projects/relyra/.planning/phases/27-adopter-onboarding-polish-and-case-studies/27-CONTEXT.md:26)

- Only Okta, Entra, and Google Workspace currently qualify as first-class preset coverage.
- Docs should not imply broader verified provider support.

## No Strong Analog Found

| File/Surface | Role | Data Flow | Reason |
|---|---|---|---|
| `guides/<new case study catalog>.md` as a repo-native adopter narrative set | config | transform | The repo has recipes and reviewer packets, but no existing case-study family. Build these by combining recipe structure with explicit ownership-boundary language rather than copying a single prior doc verbatim. |

## Metadata

**Analog search scope:** `README.md`, `guides/`, `docs/`, `lib/mix/tasks/`, `lib/relyra/provider*.ex`, `lib/relyra/test_support*.ex`, `test/`, `.planning/phases/06`, `.planning/phases/25`, `.planning/phases/26`
**Pattern extraction date:** 2026-05-08
