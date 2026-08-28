# Deferred Items

## 2026-08-26 — Plan 70-04

- `cd demo/ledger_loop && mix format --check-formatted` reports formatting drift in pre-existing unrelated files: `lib/ledger_loop_web/live/setup_live.html.heex`, `lib/ledger_loop_web/components/layouts/root.html.heex`, `lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex`, `lib/ledger_loop_web/controllers/fake_idp_html/sso.html.heex`, `lib/ledger_loop/demo/keycloak_provisioner.ex`, and existing unrelated tests. No Plan 70-04 file failed formatting; focused controller verification passed.
