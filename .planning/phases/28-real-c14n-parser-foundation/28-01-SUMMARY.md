---
phase: 28-real-c14n-parser-foundation
plan: 01
subsystem: security/xml
tags: [saml, xml, saxy, c14n, parser, infoset-normalization, supply-chain]
requires:
  - "Saxy.Handler behaviour (saxy ~> 1.6 hex package)"
  - "parser_path_guard compile-time confinement (lib/relyra/security/xml/ allowed root)"
provides:
  - "Relyra.Security.XML.SaxyTree — Saxy.Handler parse-tree builder"
  - "Relyra.Security.XML.SaxyTree.Node — canonical tree-node struct (CONTRACT for Plans 02/03)"
  - "{:saxy, \"~> 1.6\"} non-optional dependency resolved in mix.lock (saxy 1.6.0)"
affects:
  - "Plan 02 (exclusive-C14N engine) — consumes the Node tree-node shape"
  - "Plan 03 (seam re-wiring) — consumes the Node tree + maps Saxy.ParseError -> :malformed_xml"
tech-stack:
  added:
    - "saxy 1.6.0 (hex, MIT, github.com/qcam/saxy) — non-optional runtime SAX parser"
  patterns:
    - "Saxy.Handler @behaviour + @impl handle_event/3 stack-of-open-elements tree build"
    - "Three Relyra-owned infoset-normalization layers applied at tree-build time"
    - "Node struct contract documented verbatim in the @moduledoc"
key-files:
  created:
    - "lib/relyra/security/xml/saxy_tree.ex"
    - "test/relyra/security/xml/saxy_tree_test.exs"
  modified:
    - "mix.exs (deps/0: + {:saxy, \"~> 1.6\"} non-optional)"
    - "mix.lock (resolved saxy 1.6.0)"
decisions:
  - "Tree node is a struct (Relyra.Security.XML.SaxyTree.Node), not a bare map — stable, introspectable contract for Plans 02/03"
  - "xmlns / xmlns:* declarations are retained verbatim in :attrs AND surfaced resolved in :ns (C14N needs both the raw decls to render and the resolved in-scope map)"
  - "CRLF in an attribute value collapses to a SINGLE space (line-ending normalization precedes the 3.3.3 whitespace mapping, per XML 1.0 3.3.3)"
metrics:
  duration_minutes: 6
  tasks_completed: 3
  files_created: 2
  files_modified: 2
  tests_added: 16
  completed_date: "2026-05-23"
---

# Phase 28 Plan 01: Real C14N parser foundation (saxy + SaxyTree) Summary

`saxy` 1.6.0 added as a non-optional runtime dependency and `Relyra.Security.XML.SaxyTree` built as a `Saxy.Handler` that turns raw SAML XML into a `Node`-struct parse tree carrying verbatim qnames, document-order attributes, an inherited in-scope namespace stack, and the three Relyra-owned infoset-normalization layers (in-scope ns stack, attribute-value whitespace per XML 1.0 §3.3.3, line-ending per §2.11) — applied at build time, kept strictly separate from C14N escaping. Compiles under `parser_path_guard`; 16/16 tests green.

## What Was Built

### Task 1 — saxy package-legitimacy checkpoint (T-28-SC)
Verification-only blocking-human gate. **Pre-approved by the user** before execution. No files modified in this task; disposition recorded below (Supply-Chain Disposition). The threat-register entry T-28-SC is satisfied.

### Task 2 — saxy non-optional dependency (`ae706ef`)
`{:saxy, "~> 1.6"}` added to `deps/0` in `mix.exs` in the core (non-optional) group — explicitly NOT carrying `optional: true` (unlike `req`/`oban`/`phoenix`). `mix deps.get` resolved and pinned **saxy 1.6.0** in `mix.lock`. The `ci.security` alias was left byte-unchanged (stays pure-Elixir, D-12). Only the saxy hunk of `mix.exs` was staged — pre-existing unrelated working-tree edits to the `docs/0` extras list (jtbd doc entries) were left unstaged, out of scope.

### Task 3 — SaxyTree handler (RED `fb72d50` / GREEN `8738532`)
`Relyra.Security.XML.SaxyTree` (`@behaviour Saxy.Handler`) under the parser_path_guard allowed root `lib/relyra/security/xml/`. Maintains a stack of open element nodes in `user_state`; on `:start_element` it derives prefix/local, computes own ns declarations, merges over the parent's in-scope map, and normalizes attribute values; on `:characters`/`:cdata` it appends line-ending-normalized text; on `:end_element` it pops and attaches to the parent in document order; on `:end_document` it finalizes the root. A public `SaxyTree.parse/1` wraps `Saxy.parse_string/3` and returns `{:ok, root_node} | {:error, %Saxy.ParseError{}}`.

## Tree-Node Shape (CONTRACT for Plans 02 and 03 — build against this verbatim)

The tree is built from `Relyra.Security.XML.SaxyTree.Node` structs. The struct is defined as:

```elixir
defmodule Relyra.Security.XML.SaxyTree.Node do
  @enforce_keys [:qname, :prefix, :local]
  defstruct qname: nil,
            prefix: "",
            local: nil,
            attrs: [],
            ns: %{},
            children: [],
            text: ""
end
```

Field contract:

| Field      | Type                                      | Meaning |
|------------|-------------------------------------------|---------|
| `:qname`   | `String.t()`                              | Verbatim qualified name exactly as in source, prefix preserved (e.g. `"ds:Signature"`, `"Assertion"`). |
| `:prefix`  | `String.t()`                              | Derived namespace prefix; `""` (empty string) when the element is unprefixed. |
| `:local`   | `String.t()`                              | Derived local name (qname with the prefix stripped). |
| `:attrs`   | `[{String.t(), String.t()}]`              | Raw attributes in **document order**. Each value is attribute-value normalized (layer #2). `xmlns` / `xmlns:*` declarations are **retained here verbatim as attrs** (so the C14N engine can render them) and are **also** surfaced resolved in `:ns`. |
| `:ns`      | `%{optional(String.t()) => String.t()}`   | In-scope namespace map `prefix => URI`. The **default namespace uses the `""` key**. Inherited from ancestors and overlaid with this element's own `xmlns` / `xmlns:prefix` declarations (layer #1). |
| `:children`| `[Node.t()]`                              | Child element nodes in **document order**. |
| `:text`    | `String.t()`                              | Accumulated character + CDATA content, line-ending normalized (layer #3), in document order. **NOT** whitespace-collapsed (only attribute values are). |

`SaxyTree.parse/1` returns `{:ok, root_node}` (the root `Node`) or `{:error, %Saxy.ParseError{}}`.

### The three infoset-normalization layers (applied at build time)

1. **In-scope namespace stack** — `:ns` = `Map.merge(parent_ns, own_ns)`. `own_ns` derives `xmlns="..."` to the `""` key and `xmlns:prefix="..."` to the `prefix` key. (D-03 layer 1.)
2. **Attribute-value normalization (XML 1.0 §3.3.3, CDATA-type rule — SAML is DTD-less)** — each literal `#x9`/`#xA`/`#xD` in an attribute value becomes a single `#x20`. Line-ending normalization is applied first, so a literal `\r\n` (or lone `\r`) inside an attribute value collapses to **one** space.
3. **Line-ending normalization (XML 1.0 §2.11)** — `\r\n` and a lone `\r` become `\n` in all text/CDATA content.

These build-time *infoset* normalizations are kept **strictly separate** from C14N *escaping* (`&#x9;`/`&#xD;` style), which is a serialize-time concern owned by Plan 02. SaxyTree emits no C14N escapes.

## Supply-Chain Disposition (T-28-SC satisfied)

The user pre-approved adding `{:saxy, "~> 1.6"}` as a non-optional dependency. Orchestrator-verified evidence: hex.pm shows **saxy v1.6.0 (2024-10-22)**, MIT license, **8,548,165** all-time downloads, links to **github.com/qcam/saxy**; the GitHub repo `qcam/saxy` is the genuine "Fast SAX parser and encoder for XML in Elixir" (MIT, actively maintained). At exec time `mix hex.info saxy` re-confirmed 1.6.0 as the latest stable and 8,548,165 all-time downloads. `mix deps.get` pinned `saxy 1.6.0` (hex checksum `02cb4e9b…317ee`) into `mix.lock`. This is NOT a typosquat; the dependency string is exactly `{:saxy, "~> 1.6"}`, non-optional. T-28-SC in the threat register is mitigated.

## Verification

- `mix compile --warnings-as-errors` — passes. parser_path_guard accepts the new `Saxy`-referencing module under its allowed root `lib/relyra/security/xml/`.
- `mix test test/relyra/security/xml/saxy_tree_test.exs --warnings-as-errors` — **16 tests, 0 failures**. Covers: inherited ns stack, own-over-inherited overlay, document-order attrs, verbatim qnames + prefix/local split, attr-value normalization (#x9/#xA/#xD -> space, literal-tab case), text/CDATA line-ending normalization, text NOT whitespace-collapsed, CDATA == characters, mixed text+CDATA order, non-ASCII UTF-8 preservation, malformed-XML -> `%Saxy.ParseError{}`, and document-order children.
- Regression: `mix test test/relyra/security/xml/ test/security/xml/corpus_security_test.exs --warnings-as-errors` — **32 tests, 0 failures**. The existing GATE-02 fail-closed fixtures and corpus_gate tests stay green (no `pure_beam.ex` changes in this plan; SaxyTree is purely additive).
- `grep` confirms `{:saxy, "~> 1.6"}` non-optional in `mix.exs` and `:saxy` 1.6.0 resolved in `mix.lock`.
- No new atom added to the `xml_error_type` union; only `:malformed_xml` is reused (by the future seam mapping in Plan 03).

## TDD Gate Compliance

Plan task 3 is `tdd="true"` and the RED/GREEN gate sequence is present in git history:
- RED: `fb72d50` — `test(28-01): add failing tests for SaxyTree parse-tree builder` (failed to compile because `SaxyTree.Node` did not yet exist — the expected RED failure).
- GREEN: `8738532` — `feat(28-01): implement SaxyTree handler with ns stack + 3 normalizations` (16/16 green).
- REFACTOR: none required; the GREEN implementation was already clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Invalid `relyra_test` Postgres database blocked the test suite**
- **Found during:** Task 3 (running the test suite — the ExUnit `test_helper.exs` calls `MigrationCase.bootstrap!`, which requires a usable Postgres `relyra_test` database).
- **Issue:** `relyra_test` existed but was marked invalid (`datconnlimit = -2`) from an interrupted `storage_up`/migration, and the migration-lock connection checkout timed out under concurrent recompile load (`--warnings-as-errors` recompiles 113 files).
- **Fix:** Dropped the invalid database with `DROP DATABASE IF EXISTS relyra_test WITH (FORCE)` so `bootstrap!`'s `storage_up` could recreate it cleanly, then ran the suite with a warm compile. This is an environment-state repair, not a code change — no source files were modified for it.
- **Files modified:** none (Postgres state only).
- **Commit:** n/a (environment fix).

**2. [Rule 3 - Blocking] Elixir 1.19 set-theoretic typing violation on struct update**
- **Found during:** Task 3 GREEN (`mix compile --warnings-as-errors`).
- **Issue:** The Elixir 1.19 type checker rejected struct updates (`%Node{node | ...}`, `%Node{parent | ...}`) where `node`/`parent` were bound by a bare list-pattern (`[node | rest]`) the checker typed as `dynamic()`.
- **Fix:** Added explicit `%Node{}` patterns at the binding sites (`[%Node{} = node | rest]`, `[%Node{} = parent | tail]`) so the compiler can prove the struct type. No behavior change.
- **Files modified:** `lib/relyra/security/xml/saxy_tree.ex` (folded into the GREEN commit `8738532`).
- **Commit:** `8738532`.

### Out-of-scope items left untouched
- Pre-existing uncommitted working-tree edits to `mix.exs` (`docs/0` extras: `docs/jtbd_gap_map.md`, `guides/jtbd_user_flows.md`), `README.md`, and `guides/getting_started.md` were present before this plan and are unrelated to it — left unstaged. Untracked `docs/jtbd_gap_map.md`, `guides/jtbd_user_flows.md`, and `.planning/phases/28-real-c14n-parser-foundation/28-PATTERNS.md` were likewise left as-is.

## Known Stubs

None. `SaxyTree` is fully wired: `parse/1` is exercised end-to-end by the test suite against real XML inputs; there are no hardcoded empty returns, placeholders, or unwired data paths. (The exclusive-C14N serializer and the seam re-wiring are explicitly out of scope for this plan — Plans 02 and 03.)

## Self-Check: PASSED

- FOUND: lib/relyra/security/xml/saxy_tree.ex
- FOUND: test/relyra/security/xml/saxy_tree_test.exs
- FOUND commit: ae706ef (Task 2 — saxy dep)
- FOUND commit: fb72d50 (Task 3 RED)
- FOUND commit: 8738532 (Task 3 GREEN)
- mix.exs contains `{:saxy, "~> 1.6"}` (non-optional); mix.lock contains saxy 1.6.0.
