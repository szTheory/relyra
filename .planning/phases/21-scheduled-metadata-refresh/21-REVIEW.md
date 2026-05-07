---
status: clean
phase: 21-scheduled-metadata-refresh
reviewed_at: "2026-05-07T03:55:00Z"
reviewer: orchestrator-inline
reviewer_reason: "gsd-code-reviewer subagent disconnected mid-run twice (~15min socket timeouts). Inline review by orchestrator focused on the high-leverage Phase 21 invariants (atomicity, optional-deps, asymmetric strictness, brand voice) plus a delta-based read of the new prod modules."
findings_critical: 0
findings_high: 0
findings_medium: 0
findings_low: 1
findings_informational: 2
---

# Phase 21 Code Review

**Verdict:** CLEAN. No critical, high, or medium findings. One low-severity informational note + two informational observations.

## Method

The two `gsd-code-reviewer` subagent runs both disconnected on socket errors after ~15 minutes (no REVIEW.md written). Inline review by the orchestrator focused on the high-leverage invariants whose violation would be a real defect:

1. Atomicity (D-28): every health-state mutation co-commits with audit row inside `Repo.transact/2`.
2. Optional-deps gateway (D-02 / D-37): both compile lanes green.
3. Asymmetric strictness (D-09): scheduled apply path requires signed metadata; manual import unchanged.
4. Pure helpers stay pure (no Repo / Req / Ecto / Telemetry imports).
5. Trust anchor: no TOFU, no fallback to assertion-signing certs.
6. Single audit-writer seam (D-35).
7. Brand voice (no banned terms in user-facing copy).

Each invariant verified directly via grep / diff / test in the VERIFICATION.md ledger. The findings below capture additional code-quality observations that the verifier scope did not pick up.

## Findings

### LOW-1 — `workers/metadata_refresh.ex` brand-voice comment uses "retry"

**File:** `lib/relyra/workers/metadata_refresh.ex:55`
**Severity:** Low
**Category:** Style / brand voice

The comment block at line 50-58 explains that Phase 21 owns its own backoff via the auto-suspend state machine (D-25) and that mixing Oban's per-job retry with the per-source backoff would be a double-counting footgun:

```elixir
# Phase 21 owns its OWN backoff via the auto-suspend state machine
# (D-25). Mixing Oban's per-job retry with our own per-source
# backoff is the double-counting footgun (RESEARCH "Don't
# Hand-Roll" row 3). One attempt per scheduler tick.
max_attempts: 1,
```

Brand voice forbids "retry" in user-facing copy. This is a code comment documenting a *rejected* pattern (explaining *why* `max_attempts: 1`), not user-facing copy, so it is acceptable per the spirit of the brand book. Recommend leaving as-is — the comment's pedagogical value is high and rewording would obscure it. If a stricter reading is preferred later, "second attempt" or "re-attempt" would preserve meaning while avoiding the literal banned term.

**Recommendation:** Accept. No change required.

### INFO-1 — D-35 single-audit-writer-seam invariant is preserved through helper indirection

**File:** `lib/relyra/ecto/metadata_apply.ex:879-895`
**Severity:** Informational

The append-event call at line 895 is wrapped in `defp append_metadata_audit/6`. The transact wrap is at line 30 of `apply_revision/4`. The helper receives `repo` as its first argument (the in-transaction repo handle), which is the correct pattern.

A naive grep for "AuditWriter.append_event near Repo.transact" on the same line could miss this — the seam is wrapped in a helper for testability and the transact is at the top of the caller. For future reviewers: **D-35 holds at the function boundary, not the textual line boundary.** All four transact-wrapped sites (`record_attempt/3`, `apply_revision/4`, `record_validity_warning/3`, `resume_auto_refresh/3`) end up at exactly two `AuditWriter.append_event` call sites, both inside the transact via direct call or helper.

### INFO-2 — Compile-time `Code.ensure_loaded?` gate placement is correct but subtle

**File:** `lib/relyra/workers/metadata_refresh.ex` (top of module body, outside `defmodule`)
**Severity:** Informational

Plan 21-05 documents this as a Rule-3 deviation: the `Code.ensure_loaded?(Oban.Worker)` gate had to move outside the `defmodule` body because Elixir's `Kernel.if/2` eagerly compiles both branches at macro-expansion time. Inside the `defmodule`, the with-Oban branch's `use Oban.Worker` macro would attempt to expand `Oban.Worker` even when Oban is absent.

The current shape gates **the entire `defmodule` body** behind `Code.ensure_loaded?`, producing two completely separate module definitions (with-Oban or absent-lane). Both compile lanes are green:

- `mix compile --warnings-as-errors` → green (Oban present)
- `mix compile --no-optional-deps --warnings-as-errors` → green (Oban absent)

This is the canonical Elixir pattern for optional-deps modules and matches the existing `Relyra.OptionalDeps.LiveAdmin` shape — different from `LiveAdmin`'s raise-on-absent contract (which 21-05 explicitly deviates from to a result-tuple shape, also documented).

**Recommendation:** Add a `# Pitfall N: ...` comment near the gate (already present per 21-05 SUMMARY) explaining the eager-compile pitfall so future reviewers understand why the gate is at module scope, not statement scope.

## Spot-check on phase invariants (cross-reference with VERIFICATION.md)

| Invariant | Status |
|-----------|--------|
| D-05 refresh.ex byte-identical | ✓ |
| D-09 great-error verbatim + asymmetric strictness | ✓ |
| D-23 metadata.refresh telemetry namespace byte-identical | ✓ |
| D-28 atomicity (4 transact wraps in MetadataApply) | ✓ |
| D-30 LogAlerts not auto-attached | ✓ |
| D-35 single audit-writer seam (2 sites in MetadataApply) | ✓ |
| D-37 optional-deps dual compile lanes | ✓ |
| B3 zero `clear_suspend_for_resume` in `lib/` | ✓ |
| Brand voice clean across prod paths (one benign comment exception) | ✓ |
| Pure helpers have no impure imports | ✓ |
| TrustAnchor no TOFU | ✓ |

## Race-condition surface review

The `Scheduler.run_due/2` loop selects due rows then dispatches `AutoRefresh.run_one/2` for each. Two Oban workers landing on the same source within the same tick cannot occur because the worker's `unique:` constraint at `lib/relyra/workers/metadata_refresh.ex` keys on `[:source_id]` with `period: :infinity, states: [:available, :scheduled, :executing]`. This is the locked Oban-side dedup contract. For non-Oban schedulers (mix task / k8s / fly.io), the operator is responsible for not running two scheduler ticks concurrently — RESEARCH "Don't Hand-Roll" documents this and the README ops section recipes show single-replica configurations for k8s and fly.io.

Within a single `run_due/2` invocation, the per-source loop is sequential (21-05 SUMMARY documents the sequential per-source loop), so intra-tick races are impossible.

## Audit-row payload completeness

Verified by spot-reading `metadata_apply.ex:625-650` and the 21-04 SUMMARY. The state-transition events (`:degraded`, `:suspended`, `:recovered`) carry the LOCKED payload: correlation_id, source_id, connection_record_id, error_code, consecutive_failure_count, auto_suspended_reason, transient?, counts_toward_suspend?. All payload fields trace to schema columns or pure-helper outputs — no derived fields that could drift.

## Conclusion

The Phase 21 code is production-ready. The 14 documented deviations across the 7 plans are all tactical correctness fixes that preserve the invariants. No code path discovered in this review violates the LOCKED contract surface from CONTEXT.md. The single low-severity finding (LOW-1, comment using "retry") is acceptable in context.

Recommend: ship.
