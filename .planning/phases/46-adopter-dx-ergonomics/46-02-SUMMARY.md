---
phase: 46-adopter-dx-ergonomics
plan: 02
subsystem: installer
tags: [mix-task, router-injection, phoenix]

provides:
  - Relyra.Install.RouterInjector with marker-based idempotent inject
  - mix relyra.install auto-detects single Phoenix router and injects saml_routes()

key-files:
  created:
    - lib/relyra/install/router_injector.ex
    - test/relyra/install/router_injector_test.exs
  modified:
    - lib/mix/tasks/relyra.install.ex
    - test/mix/relyra_install_test.exs

requirements-completed: [DX-02]

completed: 2026-05-27
---

# Phase 46 Plan 02 Summary

**Installer auto-injects SAML routes on unambiguous single-router hosts and falls back safely when detection is ambiguous.**

## Accomplishments

- `RouterInjector` detects `lib/**/*router.ex` files using `use …Router`, injects after first anchor with `# --- Relyra SAML routes ---` marker.
- `mix relyra.install` writes injection on single match; multi-router and no-router paths print manual instructions without corrupting files.
- Unit and integration tests cover inject, idempotent re-run, and ambiguous multi-router cases.

## Self-Check: PASSED
