---
phase: 18-mapping-editor-audit-timeline-hardening
plan: 01
subsystem: admin-ui
tags:
  - mappings
  - live-admin
  - ecto-changeset
  - security
dependency_graph:
  requires:
    - 03-behaviour-contracts-and-stores
  provides:
    - Strictly typed mapping form interactions
    - Visual badging of active mappings
  affects:
    - Relyra.LiveAdmin.ConnectionsLive
    - Relyra.LiveAdmin.Components.ConnectionDetail
tech_stack:
  added: []
  patterns:
    - Phoenix.Component.inputs_for
    - Ecto.Schema.embedded_schema
key_files:
  created:
    - lib/relyra/live_admin/mapping_form.ex
  modified:
    - lib/relyra/live_admin/connections_live.ex
    - lib/relyra/live_admin/components/connection_detail.ex
    - test/phoenix/live_admin_test.exs
key_decisions:
  - Extract typed MappingForm structs (AttributeMappingForm, GroupMappingForm) using `embedded_schema` for robust validation instead of raw JSON editing.
metrics:
  duration: ~30m
  completed_date: "2026-05-06"
---

# Phase 18 Plan 01: Replace JSON textareas with strictly typed mapping forms and active badge Summary

Implement Ecto-backed strictly typed mapping forms using `inputs_for` for attributes and groups to eliminate manual JSON editing and badge the active mapping state.

## Scope of Work

1.  **Extract Mapping Forms**: Created `Relyra.LiveAdmin.AttributeMappingsForm` and `Relyra.LiveAdmin.GroupMappingsForm` as embedded schemas in `lib/relyra/live_admin/mapping_form.ex` to formally define mapping structure and validations.
2.  **ConnectionsLive Updates**: Added event handlers for `validate_*`, `save_*`, `add_*`, and `remove_*` attribute and group mappings to manage dynamic row insertion and deletion inside the Changesets.
3.  **ConnectionDetail Updates**: Replaced JSON textareas with typed `<.inputs_for>` forms, allowing operators to add or remove mapping fields intuitively. Added an "Active" badge to the first item in the mapping revision timeline.
4.  **Tests**: Added comprehensive tests in `test/phoenix/live_admin_test.exs` covering `add_attribute_mapping`, `save_attribute_mappings`, `add_group_mapping`, and `save_group_mappings` verifying both UI interactions and Ecto schema outcomes.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

No new threat flags. Replaced unstructured manual input with strictly validated `Ecto.Changeset` boundaries, mitigating tampering risk T-18-01.

## Known Stubs

None. Form mapping state maps perfectly to `MappingCommands`.

## Self-Check: PASSED
- `lib/relyra/live_admin/mapping_form.ex` exists and is integrated.
- `lib/relyra/live_admin/connections_live.ex` updated.
- `lib/relyra/live_admin/components/connection_detail.ex` updated.
- Commits recorded successfully.
