# Phase 20: Bulk Operations

## Milestone
v0.5 - Operational Maturity

## Goal
Enable operators to manage connections in batches from the LiveView admin surface.

## Prerequisites
- Milestone v0.4 (IdP-initiated SSO) complete.
- LiveView admin surface (v0.3) mounted and functional.
- Ecto persistence (v0.2) and audit ledger operational.

## Focus Areas
- UI: Multi-selection in `ConnectionList`.
- UI: Bulk action triggers and feedback in `ConnectionsLive`.
- Domain: `Relyra.Ecto.BulkActions` coordinator.

## Non-Goals
- Scheduled automation (Phase 21).
- Bulk import of new connections (deferred).
- Transactional rollback of the *entire* batch on partial failure (each connection is independent).
