# Phase 65: documentation-truth - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-16
**Phase:** 65-documentation-truth
**Mode:** assumptions
**Areas analyzed:** Adopter Testing Narrative (Getting Started & Recipes), Validation of Doc Examples (Test Drift Protection), Repo-Internal References & Documentation, Explicit Cert Trust & Scoping

## Assumptions Presented

### Adopter Testing Narrative (Getting Started & Recipes)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Adopter docs will replace `use Relyra.TestSupport` with explicit calls to `Relyra.Testing` API. The term "FakeIdP" will be completely removed from adopter-facing guides. | Confident | `lib/relyra/testing.ex`, Phase 64 goals |

### Validation of Doc Examples (Test Drift Protection)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `test/test_support_demo_test.exs` will be rewritten or replaced (e.g. `testing_api_demo_test.exs`) to use `Relyra.Testing`. | Likely | `guides/getting_started.md`, Phase 65 Goal 5 |

### Repo-Internal References & Documentation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| References to `Relyra.TestSupport` in `BATTERIES_INCLUDED.md`, case studies, etc. updated to `Relyra.Testing`. Demo FakeIdP left for Phase 66. | Confident | Phase 65 Goal 4, ROADMAP.md Phase 66 |

### Explicit Cert Trust & Scoping (Getting Started Guide)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add explicit explanation to `getting_started.md` clarifying ephemeral RSA key generation for testing fixtures. | Likely | Phase 65 Goal 3 |

## Corrections Made

### Validation of Doc Examples (Test Drift Protection)
- **Original assumption:** Rewrite `test/test_support_demo_test.exs` or create a new file `test/docs/testing_api_demo_test.exs`.
- **User correction:** Create a dedicated `test/docs/testing_api_drift_test.exs` file.
- **Reason:** Research indicates this is the most idiomatic Elixir approach for complex context tests and adheres to the existing project convention, keeping the documentation validation isolated.

### Explicit Cert Trust & Scoping (Getting Started Guide)
- **Original assumption:** Add an explicit explanation near the testing section.
- **User correction:** Use an ExDoc admonition block (`> #### Info` or `> #### Note`) immediately following the testing code snippet in `guides/getting_started.md`.
- **Reason:** Research indicates this perfectly balances the "principle of least surprise" with high-momentum Day 1 DX by visually delineating the supplementary context without breaking the tutorial's flow.

## External Research

- Validation of Doc Examples (Test Drift Protection): Generalist agent researched Elixir idiomatic practices, pros/cons of doctests vs dedicated test files, and recommended `test/docs/testing_api_drift_test.exs`.
- Explicit Cert Trust & Scoping: Generalist agent researched ExDoc best practices, pros/cons of inline comments vs dedicated sections, and recommended ExDoc admonition block (`> #### Info`).
