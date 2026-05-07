---
phase: 21
plan: 06
type: execute
wave: 4
depends_on: [21-01, 21-02, 21-04, 21-05]
files_modified:
  - lib/relyra/live_admin/query.ex
  - lib/relyra/live_admin/components/connection_list.ex
  - lib/relyra/live_admin/connection_metadata_live.ex
  - test/relyra/live_admin/connections_live_test.exs
  - test/relyra/live_admin/connection_metadata_live_test.exs
autonomous: true
requirements:
  - CFG-08
must_haves:
  truths:
    - "The connections list renders an amber 'auto-refresh degraded' micro-badge when consecutive_failure_count >= 1 AND auto_suspended_until is nil"
    - "The connections list renders a red 'auto-refresh suspended' micro-badge when auto_suspended_until > now()"
    - "The connection metadata page shows an 'Auto-refresh health' card displaying the schedule preset, last success, consecutive failure count, current state, last error code, and (when suspended) a 'Resume now' button"
    - "Clicking 'Resume now' writes a single audit row with cause='live_admin_auto_refresh_resume' (Plan 04 record_attempt + AuditWriter co-commit) and triggers an immediate Scheduler.run_due/2 probe scoped to the source via :source_ids"
    - "The Resume now path uses start_async (mirrors the existing :metadata_refresh start_async at lines 80-114 of connection_metadata_live.ex) so the LiveView UI does not block"
    - "The legacy_unsigned_metadata_policy field surfaces in a RiskPanel when set, with allow_until + reason rendered (D-19 + Specific Ideas)"
    - "When LiveView is unavailable, every changed module's else-branch keeps the @moduledoc false stub so the no-LiveView compile lane stays green"
  artifacts:
    - path: "lib/relyra/live_admin/query.ex"
      provides: "Extended list_connections + get_metadata_revisions returning auto_refresh_health summaries"
      exports: ["list_connections/2", "get_metadata_revisions/3"]
    - path: "lib/relyra/live_admin/components/connection_list.ex"
      provides: "Per-row auto-refresh micro-badge"
    - path: "lib/relyra/live_admin/connection_metadata_live.ex"
      provides: "Auto-refresh health card + Resume now handler + handle_async(:auto_refresh_resume, ...)"
      exports: ["handle_event/3", "handle_async/3"]
  key_links:
    - from: "lib/relyra/live_admin/connection_metadata_live.ex handle_event(\"resume_auto_refresh\", ...)"
      to: "lib/relyra/ecto/metadata_apply.ex record_attempt/3 (Plan 04)"
      via: "Single transaction writes the audit row + clears auto_suspended_until via the trigger: :scheduled_probe path; Oban job dispatch (or direct Scheduler.run_due) happens after the transaction"
      pattern: "trigger: :scheduled_probe"
    - from: "lib/relyra/live_admin/connection_metadata_live.ex handle_async(:auto_refresh_resume, ...)"
      to: "lib/relyra/metadata/scheduler.ex run_due/2 with :source_ids"
      via: "Probe is a normal due-source pickup scoped to one source — same code path the cron tick takes (D-25 half-open probe)"
      pattern: "Scheduler.run_due"
    - from: "lib/relyra/live_admin/components/connection_list.ex"
      to: "Relyra.LiveAdmin.Query.list_connections/2 auto_refresh_health summary"
      via: "The query enriches each connection summary with :auto_refresh_health derived from MetadataSource fields"
      pattern: "auto_refresh_health"
---

<objective>
Land the operator-facing surface for Phase 21: a per-row "auto-refresh degraded" / "auto-refresh suspended" micro-badge on the connection list (D-29), an "Auto-refresh health" compact card on the connection metadata page (D-29), and a "Resume now" button that dispatches an immediate half-open probe via `Scheduler.run_due/2` (D-25, D-29 + Specific Ideas resume-now contract). All UX copy follows the brand book: "Auto-refresh", "schedule", "suspended", "resume now", "metadata trust fingerprint" — never "polling", "cron job", "blocked", "retry", "circuit breaker".

Purpose: Per RESEARCH "Wave plan", LiveView extensions ship in Wave 4 once the underlying audit-writer-seam extension (Plan 04) and the scheduler/wrapper (Plan 05) exist. Per D-29, this is a piggyback on existing surfaces — no new mount, no new route, no top-level health dashboard. The `start_async(:metadata_refresh, ...)` pattern at `connection_metadata_live.ex:66-114` is the LOCKED template for the Resume-now button so the operator gets the same disabled-while-loading UX they already know from manual refresh.

Output: Three extended files (Query, ConnectionList component, ConnectionMetadataLive), two extended test files. Pitfall 3 (Resume-now race with concurrent scheduler tick) is handled by routing through `MetadataApply.record_attempt/3` with `trigger: :scheduled_probe` so the audit row + state-clear happen in one transaction; the Oban worker's `unique:` constraint absorbs concurrent ticks.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md
@.planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md
@.planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md
@.planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md
@lib/relyra/live_admin/connections_live.ex
@lib/relyra/live_admin/connection_metadata_live.ex
@lib/relyra/live_admin/components/connection_list.ex
@lib/relyra/live_admin/components/risk_panel.ex
@lib/relyra/live_admin/query.ex
@lib/relyra/ecto/metadata_source.ex
@prompts/relyra-brand-book.md

<interfaces>
Existing connection summary shape (`lib/relyra/live_admin/query.ex:149-160`):

```elixir
defp connection_summary(connection) do
  %{
    connection_id: connection.connection_id,
    display_name: connection.display_name || connection.connection_id,
    organization_id: connection.organization_id,
    status: connection.status,
    provider_preset: connection.provider_preset,
    provider_label: provider_label(connection.provider_preset),
    inserted_at: connection.inserted_at,
    updated_at: connection.updated_at
  }
end
```

Phase 21 adds a `:auto_refresh_health` key. Health states (computed from `MetadataSource` fields, NIL when no source is registered):

- `nil` — no metadata source / source has `auto_refresh_enabled: false` (do not render badge)
- `:healthy` — `auto_refresh_enabled: true` AND `consecutive_failure_count == 0` AND `auto_suspended_until` is nil (do not render badge)
- `:degraded` — `consecutive_failure_count >= 1` AND `auto_suspended_until` is nil (amber)
- `:suspended` — `auto_suspended_until > now()` (red)

Existing `start_async` template (`connection_metadata_live.ex:66-114`) — copy verbatim shape for `resume_auto_refresh`:

```elixir
def handle_event("refresh_metadata", _params, socket) do
  opts = [...] |> maybe_put_req(socket.assigns.relyra_admin_req)
  socket = socket |> assign(:refresh_status, :loading)
                  |> start_async(:metadata_refresh, fn -> Metadata.refresh(connection_id, opts) end)
  {:noreply, socket}
end

def handle_async(:metadata_refresh, {:ok, {:ok, _result}}, socket), do: ...
def handle_async(:metadata_refresh, {:ok, {:error, error}}, socket), do: ...
def handle_async(:metadata_refresh, {:exit, _reason}, socket), do: ...
```

Brand-voice anchors (CONTEXT.md Specifics + brand book):
- "Auto-refresh degraded" (amber badge)
- "Auto-refresh suspended" (red badge)
- "Resume now" (button label, exact)
- "Auto-refresh health" (card heading)
- "Schedule" (column label, NOT "Cadence" or "Interval")
- "Last success" (timestamp label)
- "Consecutive failures" (counter label)
- "Last error" (error-code label)
- "Metadata trust fingerprints" (pinned-fingerprint section)
- "Validity warning" (only if `last_validity_warning_for` is non-nil)
- AVOID: "polling", "cron job", "blocked", "retry", "circuit breaker", "MaxBackoff"

Audit cause string (LOCKED — RESEARCH A3 mirrors the existing `live_admin_metadata_refresh` convention at line 71): `"live_admin_auto_refresh_resume"` (exact).
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Extend Query to surface auto_refresh_health and connection_metadata health summary</name>
  <files>lib/relyra/live_admin/query.ex, lib/relyra/live_admin/components/connection_list.ex, test/relyra/live_admin/connections_live_test.exs</files>
  <read_first>
    - lib/relyra/live_admin/query.ex (whole file — preserve every existing function; only the connection_summary/1 helper and get_metadata_revisions/3 return shape change)
    - lib/relyra/live_admin/components/connection_list.ex (whole file — preserve the existing markup; add a sibling badge inside the per-row li)
    - lib/relyra/ecto/metadata_source.ex (Plan 01 — confirm field names referenced)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-29 micro-badge spec; brand voice anchors)
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/live_admin/connections_live.ex (EXTENDED, micro-badge)" section
    - prompts/relyra-brand-book.md (operator-facing copy: "Auto-refresh", "suspended", "resume now")
    - test/relyra/live_admin/ (existing test files for the LiveView surface — pick one to mirror its setup pattern)
  </read_first>
  <action>
    Step 1 — Edit `lib/relyra/live_admin/query.ex`. The change is in two places:

    (a) Extend `list_connections/2` so it joins (or preloads) the `MetadataSource` row needed to compute `auto_refresh_health`. Replace the body of `list_connections/2` with a query that left-joins `MetadataSource`:

    ```elixir
    @spec list_connections(module(), Scope.t()) :: {:ok, [map()]} | {:error, Error.t()}
    def list_connections(repo, %Scope{} = scope) when is_atom(repo) do
      with :ok <- ensure_repo(repo, :list_connections) do
        rows =
          Connection
          |> scope_query(scope)
          |> order_by([connection], asc: connection.organization_id, asc: connection.display_name)
          |> repo.all()

        # Preload metadata sources in one query to avoid N+1.
        connection_ids = Enum.map(rows, & &1.id)

        sources =
          MetadataSource
          |> where([src], src.connection_record_id in ^connection_ids)
          |> repo.all()
          |> Map.new(fn src -> {src.connection_record_id, src} end)

        now = DateTime.utc_now()

        summaries =
          Enum.map(rows, fn connection ->
            connection_summary(connection, Map.get(sources, connection.id), now)
          end)

        {:ok, summaries}
      end
    end
    ```

    Then update `connection_summary/1` to be `connection_summary/3`:

    ```elixir
    defp connection_summary(connection, metadata_source, now) do
      %{
        connection_id: connection.connection_id,
        display_name: connection.display_name || connection.connection_id,
        organization_id: connection.organization_id,
        status: connection.status,
        provider_preset: connection.provider_preset,
        provider_label: provider_label(connection.provider_preset),
        inserted_at: connection.inserted_at,
        updated_at: connection.updated_at,
        auto_refresh_health: derive_auto_refresh_health(metadata_source, now)
      }
    end

    # D-29 health derivation — returns nil when there is nothing to badge.
    defp derive_auto_refresh_health(nil, _now), do: nil
    defp derive_auto_refresh_health(%MetadataSource{auto_refresh_enabled: false}, _now), do: nil

    defp derive_auto_refresh_health(%MetadataSource{} = source, now) do
      cond do
        not is_nil(source.auto_suspended_until) and DateTime.compare(source.auto_suspended_until, now) == :gt ->
          :suspended

        (source.consecutive_failure_count || 0) >= 1 ->
          :degraded

        true ->
          :healthy
      end
    end
    ```

    (b) Extend `get_metadata_revisions/3` to also return the `auto_refresh_health` summary as a map alongside the source row. After the existing `metadata_source = repo.get_by(...)` line, build the health summary and return it in the result map:

    ```elixir
    auto_refresh_health = build_auto_refresh_health_summary(metadata_source)

    {:ok,
     %{
       connection: connection,
       metadata_source: metadata_source,
       auto_refresh_health: auto_refresh_health,
       revisions: revisions
     }}
    ```

    Add the helper near `derive_auto_refresh_health/2`:

    ```elixir
    # D-29 health card: structured summary used by the LiveView render block.
    # Returns nil when there is no metadata source registered.
    defp build_auto_refresh_health_summary(nil), do: nil

    defp build_auto_refresh_health_summary(%MetadataSource{} = source) do
      %{
        enabled?: source.auto_refresh_enabled || false,
        cadence: source.refresh_cadence,
        next_refresh_at: source.next_refresh_at,
        last_success_at: source.last_success_at,
        consecutive_failure_count: source.consecutive_failure_count || 0,
        last_failure_error_code: source.last_failure_error_code,
        last_validity_warning_for: source.last_validity_warning_for,
        auto_suspended_until: source.auto_suspended_until,
        auto_suspended_reason: source.auto_suspended_reason,
        legacy_unsigned_metadata_policy: source.legacy_unsigned_metadata_policy,
        metadata_trust_fingerprints: source.metadata_trust_fingerprints || [],
        state: derive_auto_refresh_health(source, DateTime.utc_now())
      }
    end
    ```

    Preserve the existing `if Code.ensure_loaded?(Ecto.Query) and Code.ensure_loaded?(Ecto.Schema) do` gate verbatim. Do not modify any other function in this file.

    Step 2 — Edit `lib/relyra/live_admin/components/connection_list.ex`. Inside the per-row `li` block (lines 19-35), append a sibling badge component AFTER the existing meta line `<div style="font-size: 12px; color: #666; margin-top: 4px;">{connection.organization_id} · ...</div>`. Use ONLY the brand-approved copy ("Auto-refresh degraded" / "Auto-refresh suspended"):

    ```heex
    <div :if={connection.auto_refresh_health == :degraded} style="margin-top: 6px;">
      <span style="display: inline-block; padding: 2px 6px; font-size: 11px; background: #fff7e6; color: #b87600; border: 1px solid #d98b00; border-radius: 3px;">
        Auto-refresh degraded
      </span>
    </div>
    <div :if={connection.auto_refresh_health == :suspended} style="margin-top: 6px;">
      <span style="display: inline-block; padding: 2px 6px; font-size: 11px; background: #ffebee; color: #c62828; border: 1px solid #c62828; border-radius: 3px;">
        Auto-refresh suspended
      </span>
    </div>
    ```

    DO NOT use "polling", "cron job", "blocked", "retry", or "circuit breaker" anywhere. DO NOT add a tooltip via JS in this plan (CONTEXT.md mentions tooltip text but the tooltip mechanism is the planner's discretion within D-29; the simpler badge-only approach is the recommendation per the recommendation-first DX preference — if a tooltip is needed for adopter feedback, it can come in a v0.6 follow-up).

    Step 3 — Add tests in `test/relyra/live_admin/connections_live_test.exs` (extend; do not overwrite). Add at minimum these scenarios:

    1. `test "list_connections/2 returns connection summaries with auto_refresh_health: nil when no MetadataSource exists"` — set up a connection with no source; assert `auto_refresh_health == nil`.
    2. `test "list_connections/2 returns auto_refresh_health: nil when source has auto_refresh_enabled: false"` — assert nil even with health-state populated.
    3. `test "list_connections/2 returns auto_refresh_health: :degraded when consecutive_failure_count >= 1 and auto_suspended_until is nil"` — assert `:degraded`.
    4. `test "list_connections/2 returns auto_refresh_health: :suspended when auto_suspended_until > now()"` — assert `:suspended`.
    5. `test "list_connections/2 returns auto_refresh_health: :healthy when source is enabled with no failures and no suspend"` — assert `:healthy`.
    6. `test "ConnectionList renders the 'Auto-refresh degraded' badge for :degraded"` — render the component with a fake assigns map and assert `Phoenix.LiveViewTest.render_component/2` includes `"Auto-refresh degraded"`.
    7. `test "ConnectionList renders the 'Auto-refresh suspended' badge for :suspended"` — assert `"Auto-refresh suspended"` present.
    8. `test "ConnectionList does NOT render any auto-refresh badge for :healthy or nil"` — assert neither badge string present.
    9. `test "ConnectionList copy never includes 'polling' / 'cron job' / 'blocked' / 'retry' / 'circuit breaker'"` — render with each health value and assert none of these strings appear.
  </action>
  <verify>
    <automated>mix test test/relyra/live_admin/connections_live_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "auto_refresh_health" lib/relyra/live_admin/query.ex` returns at least `3`.
    - `grep -c "derive_auto_refresh_health" lib/relyra/live_admin/query.ex` returns at least `2`.
    - `grep -c "build_auto_refresh_health_summary" lib/relyra/live_admin/query.ex` returns at least `2`.
    - `grep -c ":degraded\\|:suspended\\|:healthy" lib/relyra/live_admin/query.ex` returns at least `3`.
    - `grep -c "Auto-refresh degraded" lib/relyra/live_admin/components/connection_list.ex` returns at least `1`.
    - `grep -c "Auto-refresh suspended" lib/relyra/live_admin/components/connection_list.ex` returns at least `1`.
    - `grep -ciE "(polling|cron job|blocked|retry|circuit breaker)" lib/relyra/live_admin/components/connection_list.ex` returns `0` (brand-voice invariant).
    - `mix test test/relyra/live_admin/connections_live_test.exs --warnings-as-errors` exits 0 with the 9 new tests passing AND every pre-existing connections-live test still passing.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0 (the `if Code.ensure_loaded?(Phoenix.LiveView)` gate keeps the no-LiveView lane green).
    - `mix compile --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>Connection summaries carry `auto_refresh_health ∈ {nil, :healthy, :degraded, :suspended}`. The list component renders amber/red badges with brand-approved copy ONLY when the health state is degraded or suspended. The N+1 risk is closed by the explicit MetadataSource preload. The brand-voice invariant (no "polling"/"cron"/"blocked"/"retry") is grep-enforced.</done>
</task>

<task type="auto">
  <name>Task 2: Add Auto-refresh health card + Resume now handler to ConnectionMetadataLive</name>
  <files>lib/relyra/live_admin/connection_metadata_live.ex, test/relyra/live_admin/connection_metadata_live_test.exs</files>
  <read_first>
    - lib/relyra/live_admin/connection_metadata_live.ex (the WHOLE file — preserve every existing function and the `if Code.ensure_loaded?(Phoenix.LiveView)` gate; only ADD a new handle_event + handle_async + render section)
    - lib/relyra/live_admin/components/risk_panel.ex (existing risk-panel component the legacy_unsigned_metadata_policy panel mirrors)
    - lib/relyra/live_admin/connections_live.ex lines 594-596 (audit_context helper — but ConnectionMetadataLive does its own audit cause inline already; mirror that)
    - lib/relyra/metadata/scheduler.ex (Plan 05 — `run_due/2` with `:source_ids` opt; audit context flows in via `:audit`)
    - lib/relyra/ecto/metadata_apply.ex (Plan 04 — `record_attempt/3` with `trigger: :scheduled_probe`)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-29 health card spec; D-35 audit row required; Specifics: Resume-now MUST audit with cause = live_admin_auto_refresh_resume)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Pitfall 3: Suspended → 'Resume now' race on a clustered Oban"
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/live_admin/connection_metadata_live.ex (EXTENDED, 'Resume now')" section
    - prompts/relyra-brand-book.md
  </read_first>
  <action>
    Step 1 — Edit `lib/relyra/live_admin/connection_metadata_live.ex`. The changes are additive — preserve the entire existing file (mount, handle_params, all existing handle_event clauses, all existing handle_async clauses, the existing render block, and every defp helper). Add ONE new handle_event clause, ONE new handle_async chain, and ONE new render section (the health card) above the existing "Revision History" section.

    (a) Add a new `handle_event("resume_auto_refresh", ...)` clause AFTER the existing `handle_event("refresh_metadata", ...)` clause (around line 85):

    ```elixir
    def handle_event("resume_auto_refresh", _params, socket) do
      repo = socket.assigns.relyra_admin_repo
      actor = socket.assigns.admin_scope.actor
      source = get_in(socket.assigns, [:detail, :metadata_source])

      cond do
        is_nil(source) ->
          {:noreply, put_flash(socket, :error, "No metadata source is registered for this connection.")}

        is_nil(source.auto_suspended_until) ->
          {:noreply, put_flash(socket, :info, "Auto-refresh is not currently suspended.")}

        true ->
          # D-28 single-transaction discipline: the audit row + suspend-clear
          # MUST co-commit. Plan 04 ships `MetadataApply.resume_auto_refresh/3`
          # as the single seam — DO NOT write a parallel `repo.update` here
          # (B3 invariant; see Plan 04 Task 3 acceptance criteria).
          # The Oban worker's unique: constraint absorbs concurrent scheduler
          # ticks that fire the same source (Pitfall 3).
          case Relyra.Ecto.MetadataApply.resume_auto_refresh(repo, source, %{actor: actor}) do
            {:ok, %{source: _updated_source}} ->
              # Now that operator intent is durably recorded AND suspend is
              # cleared (one transaction), dispatch the immediate half-open
              # probe via run_due/2 scoped to this source.
              opts =
                [
                  repo: repo,
                  actor: actor,
                  cause: "live_admin_auto_refresh_resume",
                  audit: %{actor: actor, cause: "live_admin_auto_refresh_resume"},
                  source_ids: [source.id]
                ]
                |> maybe_put_req(socket.assigns.relyra_admin_req)

              socket =
                socket
                |> assign(:resume_status, :loading)
                |> start_async(:auto_refresh_resume, fn ->
                  Relyra.Metadata.Scheduler.run_due(repo, opts)
                end)

              {:noreply, socket}

            {:error, error} ->
              {:noreply, put_flash(socket, :error, error.message)}
          end
      end
    end
    ```

    (b) NO additional helper is needed in the LiveView module — the single-transaction Resume-now seam lives in `Relyra.Ecto.MetadataApply.resume_auto_refresh/3` (Plan 04 Task 3). Per B3, the LiveView MUST NOT carry its own `clear_suspend_for_resume/2` helper; the previous-iteration helper is removed because it created a two-write parallel update that broke D-28.

    (c) Add three new `handle_async(:auto_refresh_resume, ...)` clauses next to the existing `handle_async(:metadata_refresh, ...)` clauses:

    ```elixir
    def handle_async(:auto_refresh_resume, {:ok, {:ok, _results}}, socket) do
      socket =
        socket
        |> assign(:resume_status, :idle)
        |> put_flash(:info, "Auto-refresh resumed; running an immediate probe.")
        |> reload_detail()

      {:noreply, socket}
    end

    def handle_async(:auto_refresh_resume, {:ok, {:error, error}}, socket) do
      socket =
        socket
        |> assign(:resume_status, :idle)
        |> put_flash(:error, error.message)

      {:noreply, socket}
    end

    def handle_async(:auto_refresh_resume, {:exit, _reason}, socket) do
      socket =
        socket
        |> assign(:resume_status, :idle)
        |> put_flash(:error, "Resume probe failed to complete.")

      {:noreply, socket}
    end
    ```

    (d) Initialize `:resume_status` in the existing `mount/3` callback (around line 23) — add `|> assign(:resume_status, :idle)` to the assign chain.

    (e) Add the "Auto-refresh health" render section immediately BEFORE the existing `<div style="border-top: 1px solid #ddd; padding-top: 24px;">` block (line 171, the "Revision History" header). The card renders only when `assigns.detail && assigns.detail.auto_refresh_health` is non-nil:

    ```heex
    <div :if={@detail && @detail.auto_refresh_health} style="border: 1px solid #ddd; padding: 16px; margin-bottom: 24px; background: #fafafa;">
      <h2 style="font-size: 18px; margin-top: 0;">Auto-refresh health</h2>

      <div :if={@detail.auto_refresh_health.state == :suspended} style="padding: 8px 12px; background: #ffebee; color: #c62828; border-left: 3px solid #c62828; margin-bottom: 12px;">
        <strong>Auto-refresh suspended</strong>
        <span :if={@detail.auto_refresh_health.auto_suspended_reason}>
          ({@detail.auto_refresh_health.auto_suspended_reason})
        </span>
        <span :if={@detail.auto_refresh_health.auto_suspended_until}>
          until {@detail.auto_refresh_health.auto_suspended_until}
        </span>
      </div>

      <div :if={@detail.auto_refresh_health.state == :degraded} style="padding: 8px 12px; background: #fff7e6; color: #b87600; border-left: 3px solid #d98b00; margin-bottom: 12px;">
        <strong>Auto-refresh degraded</strong>
        — {@detail.auto_refresh_health.consecutive_failure_count} consecutive failures
      </div>

      <dl style="display: grid; grid-template-columns: max-content 1fr; gap: 6px 16px; font-size: 14px; margin: 0;">
        <dt style="color: #666;">Schedule</dt>
        <dd style="margin: 0;">{@detail.auto_refresh_health.cadence || "—"}</dd>

        <dt style="color: #666;">Last success</dt>
        <dd style="margin: 0;">{@detail.auto_refresh_health.last_success_at || "Never"}</dd>

        <dt style="color: #666;">Consecutive failures</dt>
        <dd style="margin: 0;">{@detail.auto_refresh_health.consecutive_failure_count}</dd>

        <dt style="color: #666;">Last error</dt>
        <dd style="margin: 0;">{@detail.auto_refresh_health.last_failure_error_code || "—"}</dd>

        <dt :if={@detail.auto_refresh_health.last_validity_warning_for} style="color: #666;">Validity warning</dt>
        <dd :if={@detail.auto_refresh_health.last_validity_warning_for} style="margin: 0;">
          {@detail.auto_refresh_health.last_validity_warning_for}
        </dd>

        <dt style="color: #666;">Metadata trust fingerprints</dt>
        <dd style="margin: 0; font-family: monospace; font-size: 12px;">
          <span :if={@detail.auto_refresh_health.metadata_trust_fingerprints == []}>(none pinned)</span>
          <ul :if={@detail.auto_refresh_health.metadata_trust_fingerprints != []} style="margin: 0; padding-left: 16px;">
            <li :for={fp <- @detail.auto_refresh_health.metadata_trust_fingerprints}>{fp}</li>
          </ul>
        </dd>
      </dl>

      <div :if={@detail.auto_refresh_health.legacy_unsigned_metadata_policy} style="margin-top: 12px;">
        <Relyra.LiveAdmin.Components.RiskPanel.risk_panel risk_flags={[
          %{label: "Unsigned metadata escape hatch active",
            details: @detail.auto_refresh_health.legacy_unsigned_metadata_policy}
        ]} />
      </div>

      <div :if={@detail.auto_refresh_health.state == :suspended} style="margin-top: 16px;">
        <button phx-click="resume_auto_refresh"
                disabled={@resume_status == :loading}
                style={"padding: 8px 16px; border-radius: 4px; cursor: pointer; " <>
                       if(@resume_status == :loading,
                         do: "background: #e0e0e0; color: #999; border: 1px solid #ccc;",
                         else: "background: #c62828; color: white; border: none;")}>
          {if @resume_status == :loading, do: "Resuming...", else: "Resume now"}
        </button>
        <p style="color: #666; font-size: 12px; margin-top: 8px; margin-bottom: 0;">
          Clears the cool-off window and runs an immediate probe. The probe attempt is recorded in the audit ledger.
        </p>
      </div>
    </div>
    ```

    NOTE the brand-voice invariant: NEVER use "polling", "cron job", "blocked", "retry", "circuit breaker", or "MaxBackoff" in this card. The button label MUST be "Resume now" (exact). The card heading MUST be "Auto-refresh health" (exact). Use "Schedule" not "Cadence" or "Interval". Use "cool-off window" / "immediate probe" if you must describe the timing — but prefer the operator-facing copy already in the spec.

    Step 2 — Replace the Wave 0 stub (or extend the existing) `test/relyra/live_admin/connection_metadata_live_test.exs`. Add at minimum these scenarios:

    1. `test "Auto-refresh health card renders Schedule, Last success, Consecutive failures, and Last error labels"` — render the LiveView with a `detail.auto_refresh_health` map; assert each label is present.
    2. `test "Auto-refresh health card renders the 'Auto-refresh suspended' banner when state == :suspended"` — assert `"Auto-refresh suspended"` is present.
    3. `test "Auto-refresh health card renders the 'Auto-refresh degraded' banner when state == :degraded"` — assert `"Auto-refresh degraded"` is present.
    4. `test "Resume now button only renders when state == :suspended"` — render with state == :degraded; assert `"Resume now"` is NOT present. Render with state == :suspended; assert it IS present.
    5. `test "Resume now button is disabled while @resume_status == :loading"` — assert the button has `disabled` attr when loading.
    6. `test "handle_event(\"resume_auto_refresh\", ...) delegates to MetadataApply.resume_auto_refresh/3 (single-transaction seam — D-28)"` — set up a suspended source; trigger the event; assert (a) the source row has `auto_suspended_until: nil` AND `auto_suspended_reason: nil` AFTER the call, (b) exactly one audit event was appended via `AuditWriter` with `cause: "live_admin_auto_refresh_resume"` and `actor` matching the LiveView scope (proves D-35 single audit-writer seam preserved end-to-end), (c) the LiveView did NOT perform a parallel `repo.update` (no `clear_suspend_for_resume` in the call graph — B3 invariant).
    7. `test "handle_event(\"resume_auto_refresh\", ...) is a no-op when the source is not suspended"` — set up an unsuspended source; assert flash message and no state change.
    8. `test "handle_async(:auto_refresh_resume, {:ok, {:ok, _}}, ...) shows the success flash and reloads the detail"` — assert `socket.assigns.resume_status == :idle` and the appropriate flash.
    9. `test "Brand-voice invariant: rendered HTML contains none of 'polling', 'cron job', 'blocked', 'retry', 'circuit breaker'"` — assert the rendered LiveView HTML does not contain any of these strings.
    10. `test "legacy_unsigned_metadata_policy renders inside a RiskPanel when set"` — assert the risk panel is present when the policy field is non-nil.

    Use the existing test pattern from previous LiveView tests in `test/relyra/live_admin/`. The handle_event tests need a real Repo + MetadataSource fixture per Plan 04's pattern.
  </action>
  <verify>
    <automated>mix test test/relyra/live_admin/connection_metadata_live_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "handle_event(\"resume_auto_refresh\"" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `1`.
    - `grep -c "handle_async(:auto_refresh_resume" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `3` (success / error / exit clauses).
    - `grep -c "live_admin_auto_refresh_resume" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `1` (cause string passed in `opts` for the scheduler probe; the AUTHORITATIVE audit-row cause is set inside `MetadataApply.resume_auto_refresh/3` per Plan 04 Task 3).
    - `grep -c "MetadataApply.resume_auto_refresh\|Relyra.Ecto.MetadataApply.resume_auto_refresh" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `1` (single-transaction seam from Plan 04 Task 3 — D-28).
    - `grep -rE "clear_suspend_for_resume" lib/` returns no matches (B3 invariant — the parallel write helper is removed; resume goes through `MetadataApply.resume_auto_refresh/3` only).
    - `grep -c "Scheduler.run_due\\|Relyra.Metadata.Scheduler.run_due" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `1`.
    - `grep -c "Auto-refresh health" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `1` (card heading).
    - `grep -c "Resume now" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `1` (button label).
    - `grep -c "Auto-refresh suspended\\|Auto-refresh degraded" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `2`.
    - `grep -ciE "(polling|cron job|blocked|retry|circuit breaker|maxbackoff)" lib/relyra/live_admin/connection_metadata_live.ex` returns `0` (brand-voice invariant).
    - `grep -c "RiskPanel" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `1` (D-19 risk panel for legacy_unsigned_metadata_policy).
    - `grep -c "if Code.ensure_loaded?(Phoenix.LiveView) do" lib/relyra/live_admin/connection_metadata_live.ex` returns at least `1` (existing gate preserved).
    - `mix test test/relyra/live_admin/connection_metadata_live_test.exs --warnings-as-errors` exits 0 with at least 10 new tests passing AND every previously-passing metadata-live test still passing.
    - `mix compile --warnings-as-errors` exits 0.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>The connection metadata LiveView renders the Auto-refresh health card with brand-approved copy. The Resume-now button only appears when suspended. Clicking Resume now delegates to `Relyra.Ecto.MetadataApply.resume_auto_refresh/3` (Plan 04 Task 3) which co-commits the audit row (`cause: "live_admin_auto_refresh_resume"`) AND the suspend-clear in ONE transaction (D-28). On success, the LiveView dispatches an immediate Scheduler.run_due/2 probe scoped to the source via `:source_ids` (start_async pattern — UI never blocks). The LiveView carries NO parallel `repo.update` helper (B3 invariant — `clear_suspend_for_resume` removed). The legacy_unsigned_metadata_policy renders inside the existing RiskPanel component when set. The brand-voice invariant is grep-enforced. The `if Code.ensure_loaded?(Phoenix.LiveView)` gate is preserved so the no-LiveView compile lane stays green.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Operator click → `handle_event("resume_auto_refresh", ...)` | Untrusted UI event crosses into the trust-state mutation; the operator's actor identity is the audit anchor. |
| LiveView render → operator's browser | UI-rendered HTML crosses to the operator; brand-voice invariants and credential-redaction posture both apply. |
| LiveView async dispatch → Scheduler.run_due/2 | Concurrent with a background cron tick; the Oban `unique:` constraint deduplicates. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-21-35 | Repudiation | "Resume now" without audit | mitigate | Every Resume-now click writes a `MetadataRevision` row + `AuditWriter.append_event` audit row through `MetadataApply.record_attempt/3` (Plan 04 — D-35 single audit-writer seam). Cause string is the LOCKED `"live_admin_auto_refresh_resume"` (RESEARCH A3). |
| T-21-36 | Tampering | concurrent Resume-now + scheduler tick | mitigate | The audit row + state-clear are co-committed via record_attempt/3's transact block (Plan 04). The subsequent Oban probe insert is deduplicated by the `unique:` constraint (Plan 05) — at most one execution per source per dedup window (Pitfall 3). |
| T-21-37 | Elevation of Privilege | non-admin operator triggering Resume now | mitigate | The LiveView is mounted under the existing `Relyra.LiveAdmin.Scope` + `on_mount` boundary (verified at `connections_live.ex:17`). Phase 21 inherits the existing admin-scope check; no new authn/authz surface introduced. |
| T-21-38 | Information Disclosure | rendered fingerprints / cert details in HTML | accept | Fingerprints are public values (operator pinned them out-of-band; they're identifiers, not secrets). Cert PEMs are NOT rendered. The `legacy_unsigned_metadata_policy` map is rendered inside the existing `Relyra.LiveAdmin.Components.RiskPanel` which uses `Jason.encode!(_, pretty: true)` — same posture as v0.3 risk panels. |
| T-21-39 | Denial of Service | rapid Resume-now clicking | mitigate | The button is `disabled` while `@resume_status == :loading` (matches the `:metadata_refresh` button's disabled-while-loading pattern at line 162 of the existing render). The `start_async` task is one outstanding job per click; subsequent clicks are no-ops via the disabled attr. |
| T-21-40 | Tampering | brand-voice drift in operator copy | mitigate | Grep-enforced acceptance criteria reject any usage of "polling" / "cron job" / "blocked" / "retry" / "circuit breaker" / "MaxBackoff" in either the connection list component or the connection metadata LiveView. |
</threat_model>

<verification>
- `mix test test/relyra/live_admin/connections_live_test.exs test/relyra/live_admin/connection_metadata_live_test.exs --warnings-as-errors` is green.
- `mix test --warnings-as-errors --exclude pending` is green (full suite — proves no LiveView regression).
- `mix compile --warnings-as-errors` is green.
- `mix compile --no-optional-deps --warnings-as-errors` is green (the `if Code.ensure_loaded?(Phoenix.LiveView)` gate keeps the no-LiveView lane green).
- `mix format --check-formatted` is green.
- Brand-voice grep invariant is green: `grep -riE '(polling|cron job|blocked|retry|circuit breaker|maxbackoff)' lib/relyra/live_admin/components/connection_list.ex lib/relyra/live_admin/connection_metadata_live.ex` returns no matches.
</verification>

<success_criteria>
- Connection list renders the amber "Auto-refresh degraded" / red "Auto-refresh suspended" micro-badge with brand-approved copy ONLY (D-29).
- `Relyra.LiveAdmin.Query.list_connections/2` returns connection summaries with `auto_refresh_health ∈ {nil, :healthy, :degraded, :suspended}` and avoids N+1 by pre-loading MetadataSource rows in one query.
- `Relyra.LiveAdmin.Query.get_metadata_revisions/3` returns `auto_refresh_health` in its result map for the metadata-page health card.
- The connection metadata LiveView renders an "Auto-refresh health" card showing schedule, last success, consecutive failures, last error code, validity warning (when set), pinned fingerprints, and the legacy escape-hatch RiskPanel.
- The "Resume now" button appears only when state == :suspended; clicking it clears auto_suspended_until, writes an audit row with cause = "live_admin_auto_refresh_resume" via Plan 04's record_attempt/3 (D-35), then dispatches a scoped Scheduler.run_due/2 probe via start_async.
- All operator-facing copy uses the brand-approved vocabulary; the grep invariant rejects any drift.
- The `if Code.ensure_loaded?(Phoenix.LiveView) do` gate is preserved; the no-LiveView compile lane stays green (engineering-DNA §3 invariant).
</success_criteria>

<output>
After completion, create `.planning/phases/21-scheduled-metadata-refresh/21-06-SUMMARY.md` summarizing: the three modified files with line-delta counts, the new event/async handler names, the `auto_refresh_health` enum cases the badge renders for, and any deviations from the brand-voice invariant.
</output>