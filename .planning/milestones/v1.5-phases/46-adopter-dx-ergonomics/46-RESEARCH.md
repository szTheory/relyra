# Phase 46: Adopter DX & ergonomics — Research

**Researched:** 2026-05-27  
**Phase:** 46 — Adopter DX & ergonomics  
**Requirements:** DX-01, DX-02, DX-03  
**Context:** `46-CONTEXT.md` (USER DECISIONS — authoritative for scope)

## Summary

Phase 46 is a **docs + installer polish wedge** with no protocol or security surface changes. A new adopter should see `apply_defaults(:okta, …)` above the fold in README, get `saml_routes()` auto-wired when `mix relyra.install` finds an unambiguous router, and navigate docs by job via `guides/overview.md`. `BATTERIES_INCLUDED.md` (root, drift-tested) becomes canonical; `guides/batteries_included.md` becomes a stub.

**Primary recommendation:** Three parallel Wave-1 plans — README snippet (DX-01), router injector module + install task wiring (DX-02), doc navigation + batteries dedupe (DX-03). Extract router injection into a small `Relyra.Install.RouterInjector` module mirroring Sigra's marker/idempotency pattern rather than bloating `relyra.install.ex`.

---

## 1. Current State Audit

### README (DX-01 gap)

| Item | Current | Target |
|------|---------|--------|
| Above-the-fold snippet | Missing — opens with tagline then "## Start Here" Day-1 list | Runnable `Relyra.Provider.apply_defaults(:okta, [...])` block after lines 1–4 |
| Snippet shape | Canonical in `guides/recipes/okta.md:57-63` | Four keys: `sp_entity_id`, `acs_url`, `idp_sso_url`, `idp_certificates` |
| Provider framing | ✅ Phase 41 D-09 ("4 first-class presets + generic runbook") | Preserve — do not reintroduce "8 presets" |

### Installer router path (DX-02 gap)

| Item | Current | Target |
|------|---------|--------|
| `--router` omitted | `maybe_update_router(nil, …)` only prints live-admin instructions — **no auto-detect** | Glob `lib/**/*router.ex`, filter `use Phoenix.Router`, inject when exactly one match |
| `--router` passed + file exists + no `saml_routes()` | Prints "ambiguous" message, **no injection** | Attempt marker-based injection when anchor found |
| Idempotency | Config uses `# --- Relyra START/END ---` sentinels | Router uses `# --- Relyra SAML routes ---` marker |
| Injection shape | Documented in `test/phoenix/router_test.exs:1-12` | `import Relyra.Phoenix.Router` + `saml_routes()` at module level |
| Tests | `test/mix/relyra_install_test.exs` — scaffold only, no router fixtures | Add unambiguous + ambiguous multi-router fixtures per CONTEXT D-15 |

**Key code path:** `lib/mix/tasks/relyra.install.ex:97-129` — entire router branch is print-only today.

### Doc navigation (DX-03 gap)

| Item | Current | Target |
|------|---------|--------|
| `guides/overview.md` | **Missing** | Day-1 / Day-2 / Reference job-shaped index |
| ExDoc extras | `mix.exs:126-151` — no overview | Add `"guides/overview.md"` near top (after README/BATTERIES) |
| ExDoc main | `"getting_started"` | Keep unchanged (D-09) |
| README "## Start Here" | Points to getting_started only | Add link to `guides/overview.md` as navigation hub |
| `ci.docs` | No overview presence check | Add `cmd test -f guides/overview.md` per D-16 |

### BATTERIES_INCLUDED dedupe (DX-03 gap)

| Item | Current | Target |
|------|---------|--------|
| Root `BATTERIES_INCLUDED.md` | Drift-tested via `mix relyra.batteries_included --check` | **Primary** — keep |
| `guides/batteries_included.md` | Full duplicate narrative (~76 lines) | Short stub linking to root |
| Generator providers | `[:okta, :entra, :google_workspace]` only — **ADFS missing** | Add `:adfs`; update claim table artifact refs to root doc |
| Claim table artifacts | References `guides/batteries_included.md` in 3 rows | Reference `BATTERIES_INCLUDED.md` instead |

---

## 2. Router Injection Design

### Sigra pattern (DNA source)

`/Users/jon/projects/sigra/lib/sigra/install/injector.ex`:
- Marker comment check → `{:already_injected, contents}` (idempotent)
- `find_last_end/1` for anchor when no explicit hook
- Returns `{:ok, new_contents}` or `{:already_injected, contents}` — never silent corruption

### Recommended Relyra shape

Create `lib/relyra/install/router_injector.ex` (library-owned, testable without Mix):

```elixir
@marker "# --- Relyra SAML routes ---"

def inject(contents) when is_binary(contents) do
  cond do
    String.contains?(contents, @marker) or String.contains?(contents, "saml_routes()") ->
      {:already_injected, contents}
    true ->
      case find_use_phoenix_router_line(contents) do
        {:ok, line_end_pos} -> {:ok, insert_after(contents, line_end_pos, snippet())}
        :error -> :ambiguous
      end
  end
end

def detect_routers(cwd \\ File.cwd!()) do
  Path.wildcard(Path.join(cwd, "lib/**/*router.ex"))
  |> Enum.filter(&router_file?/1)
end
```

**Anchor heuristic (planner discretion resolved):** Insert after the first line matching `use\s+\w+\.Router` or `use\s+Phoenix\.Router` (module-level, before pipelines). This matches real Phoenix apps and `TestRouter` shape. Do **not** use `find_last_end` for Relyra — `saml_routes/0` is a module-level macro per `router.ex:6-24`, not inside a scope block.

**Snippet to inject:**

```elixir
# --- Relyra SAML routes ---
import Relyra.Phoenix.Router
saml_routes()
```

### Auto-detect flow in `Mix.Tasks.Relyra.Install`

```
--router nil:
  routers = RouterInjector.detect_routers()
  case length(routers) do
    1 -> inject into routers |> hd
    _ -> print manual instructions (current behaviour)
  end

--router path:
  if File.exists? -> inject or fallback print
  else -> existing missing-file message
```

### Ambiguous cases (must not modify file)

- 0 or 2+ router files matching `use Phoenix.Router`
- File exists but no `use …Router` anchor
- Injection returns `:ambiguous`

---

## 3. guides/overview.md Structure

Migrate proof-journey narrative from `guides/batteries_included.md` into Day-1 section; stub the guide file.

**Proposed sections:**

| Section | Links |
|---------|-------|
| **Day-1 — Install and prove** | `getting_started.md`, `batteries_included.md` (stub → root), install + FakeIdP proof steps |
| **Day-2 — Operate in production** | Provider runbooks (okta/entra/google_workspace/adfs), `identity_mapping_and_provisioning.md`, `troubleshooting.md`, `logout.md`, case studies |
| **Reference** | `SECURITY.md`, `CONFORMANCE.md`, `jtbd_user_flows.md`, `operations/incident_playbook.md`, root `BATTERIES_INCLUDED.md` |

Keep links relative (`getting_started.md`, not absolute paths) for ExDoc compatibility.

---

## 4. Files to Modify

| File | Plan | Change |
|------|------|--------|
| `README.md` | 01 | Insert snippet block after tagline; link overview in Start Here |
| `lib/relyra/install/router_injector.ex` | 02 | **New** — detect + inject + marker idempotency |
| `lib/mix/tasks/relyra.install.ex` | 02 | Wire auto-detect + injection |
| `test/mix/relyra_install_test.exs` | 02 | Fixture routers: single + multi |
| `test/relyra/install/router_injector_test.exs` | 02 | **New** — unit tests for inject/idempotent/ambiguous |
| `guides/overview.md` | 03 | **New** — job-shaped index |
| `guides/batteries_included.md` | 03 | Stub → root `BATTERIES_INCLUDED.md` |
| `mix.exs` | 03 | Add overview to extras + `ci.docs` gate |
| `lib/mix/tasks/relyra.batteries_included.ex` | 03 | Add `:adfs`; fix claim table artifact refs |
| `BATTERIES_INCLUDED.md` | 03 | Regenerate via `mix relyra.batteries_included` |

---

## 5. Verification Commands

```bash
# Full phase gate
mix test test/mix/relyra_install_test.exs test/relyra/install/router_injector_test.exs test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors
mix ci.docs
mix format --check-formatted

# Spot checks
grep -n "apply_defaults(:okta" README.md
grep -n "guides/overview.md" README.md mix.exs
test -f guides/overview.md
mix relyra.batteries_included --check
```

---

## 6. Pitfalls

| Pitfall | Mitigation |
|---------|------------|
| Injecting inside a `scope` block | Anchor on `use …Router` line, not `find_last_end` |
| Corrupting multi-router apps | Count routers; 2+ → no write |
| Re-run duplicates `saml_routes()` | Marker + `saml_routes()` presence check |
| Generator drift after ADFS add | Regenerate + `--check` in same plan |
| Overview breaks ExDoc main | Keep `main: "getting_started"` unchanged |
| "8 presets" copy regression | Grep gate in acceptance criteria |

---

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` aliases |
| **Quick run command** | `mix test test/relyra/install/router_injector_test.exs --warnings-as-errors` |
| **Full suite command** | `mix ci.docs` |
| **Estimated runtime** | ~30 seconds |

### Per-Requirement Verification Map

| REQ | Behavior | Test Type | Command |
|-----|----------|-----------|---------|
| DX-01 | README contains `apply_defaults(:okta` above "## Start Here" | grep | `grep -n apply_defaults README.md` |
| DX-02 | Single-router inject + idempotent re-run | unit + integration | `mix test test/relyra/install/router_injector_test.exs test/mix/relyra_install_test.exs` |
| DX-02 | Multi-router byte-unchanged | integration | install test ambiguous fixture |
| DX-03 | overview.md exists + ci.docs gate | file + alias | `mix ci.docs` |
| DX-03 | batteries stub + generator ADFS | unit + drift | `mix relyra.batteries_included --check` |

### Manual-Only Verifications

| Behavior | Why Manual | Instructions |
|----------|------------|--------------|
| ExDoc sidebar navigation feel | Visual | `mix docs && open doc/index.html` — confirm overview appears in extras |

---

## RESEARCH COMPLETE
