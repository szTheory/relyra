# Phase 17: Certificate inventory + staged rollover UI - Pattern Map

**Mapped:** 2024-05-15
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/live_admin/components/connection_detail.ex` | component | render | `lib/relyra/live_admin/components/connection_detail.ex` | exact |
| `lib/relyra/live_admin/connections_live.ex` | controller | event-driven | `lib/relyra/live_admin/connections_live.ex` | exact |

## Pattern Assignments

### `lib/relyra/live_admin/components/connection_detail.ex` (component, render)

**Analog:** `lib/relyra/live_admin/components/connection_detail.ex`

**Current Generic List Pattern to Replace** (lines 75-97):
```elixir
          <section style="border: 1px solid #ddd; padding: 16px;">
            <h3 style="margin-top: 0;">Certificates</h3>
            <div :for={state <- [:active, :next, :retired]} style="margin-bottom: 16px;">
              <h4 style="margin-bottom: 8px;">{state}</h4>
              <div :if={Map.get(@detail.certificates_by_state, state) == []}>None</div>
              <div :for={certificate <- Map.get(@detail.certificates_by_state, state)} style="border: 1px solid #eee; padding: 12px; margin-bottom: 8px;">
                <div><strong>{certificate.fingerprint_sha256}</strong></div>
                <div style="font-size: 12px; color: #666;">
                  expires {certificate.not_after || "unknown"} · source {certificate.source}
                </div>
                <div style="display: flex; gap: 8px; margin-top: 8px;">
                  <button :if={state == :next} phx-click="activate_certificate" phx-value-fingerprint={certificate.fingerprint_sha256}>Promote next</button>
                  <button :if={state == :active} phx-click="retire_certificate" phx-value-fingerprint={certificate.fingerprint_sha256}>Retire active</button>
                  <button
                    :if={state == :retired and Map.get(@detail.certificates_by_state, :active) != []}
                    phx-click="rollback_certificate"
                    phx-value-restore_fingerprint={certificate.fingerprint_sha256}
                    phx-value-retire_fingerprint={List.first(@detail.certificates_by_state.active).fingerprint_sha256}
                  >
                    Restore and retire current active
                  </button>
                </div>
              </div>
            </div>
          </section>
```

*(Planner Note: The above generic generic block must be replaced with the fixed-layout 3-slot timeline (Next, Active, Retired) with tabular numerals and amber warnings as defined in RESEARCH.md).*

---

### `lib/relyra/live_admin/connections_live.ex` (controller, event-driven)

**Analog:** `lib/relyra/live_admin/connections_live.ex`

**Current Event Dispatch Pattern** (lines 90-101):
```elixir
    def handle_event("activate_certificate", %{"fingerprint" => fingerprint}, socket) do
      handle_reload_result(
        socket,
        CertificateInventory.activate_signing_certificate(
          socket.assigns.relyra_admin_repo,
          socket.assigns.connection_id,
          fingerprint,
          audit: audit_context(socket.assigns.admin_scope, "live_admin_activate_certificate")
        ),
        "Certificate promoted."
      )
    end
```

**Current Error Handling Pattern** (lines 268-270):
```elixir
    defp handle_reload_result(socket, {:error, error}, _message) do
      {:noreply, put_flash(socket, :error, error.message)}
    end
```

*(Planner Note: `handle_reload_result` or specific `StaleEntryError`/conflict handlers must be updated to force a state reload via `socket |> reload_detail()` when an optimistic locking conflict occurs, matching the research recommendations).*

---

## Shared Patterns

### Modals & Verification
**Source:** None natively existing for typed confirmation in Relyra admin yet.
**Apply to:** Rollover confirmation flow.
*(Planner Note: Relyra's brand book and ecosystem guides point out that `modal` was removed from Phoenix core components. Use native HTML `<dialog>` with daisyUI for the typed fingerprint confirmation modal).*

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/relyra/live_admin/components/rollover_modal.ex` (or inline `<dialog>`) | component | render/event-driven | No existing modally-intercepted destructive confirmation flow exists in the examined LiveView files. Use native `<dialog>` as guided by `17-RESEARCH.md`. |

## Metadata

**Analog search scope:** `lib/relyra/live_admin/**/*.ex`
**Files scanned:** 12
**Pattern extraction date:** 2024-05-15