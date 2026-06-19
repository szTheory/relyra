# Phase 65 Validation

## Nyquist Criteria

For each phase requirement, this document specifies exactly how we will prove it has been met.

### DOCS-01: Update local-first testing story to use Relyra.Testing
- **Metric:** `README.md`, `guides/getting_started.md`, and `guides/recipes/*.md` must contain zero instances of `Relyra.TestSupport`.
- **Proof:** `grep_search` and `mix ci.docs` verify the narrative, plus `testing_api_drift_test.exs` ensures the documented API compiles and runs.

### DOCS-02: Eradicate FakeIdP terminology from adopter guides
- **Metric:** The string `FakeIdP` does not appear in adopter-facing markdown files (excluding internal demo paths).
- **Proof:** `grep_search` in the `guides/` directory ensures zero matches for `FakeIdP`.

### DOCS-03: Explaining test certificate provenance
- **Metric:** An ExDoc admonition is present in `getting_started.md`.
- **Proof:** Manual review of the document and the presence of `> #### Info` or `> #### Note` describing ephemeral RSA keys.
