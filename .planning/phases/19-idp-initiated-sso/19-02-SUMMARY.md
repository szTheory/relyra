---
phase: 19-idp-initiated-sso
plan: 02
status: complete
verified: 2026-05-06T19:30:00Z
---

## 19-02 Summary: Safe Redirect Utility

I implemented a security utility to safely validate RelayState as a local redirect path, preventing Open Redirect vulnerabilities.

### Key Changes
- Created the `Relyra.Security.Redirect` module.
- Implemented `safe_local_redirect/2`, which ensures paths are local (starting with `/`) and do not contain protocol schemes or double-slashes (`//`).
- Integrated `Relyra.Error` for typed failure reporting.
- Verified all edge cases (external URLs, double-slashes, relative paths) via TDD.

### Verification Results
- `mix test test/security/redirect_test.exs` passed.
