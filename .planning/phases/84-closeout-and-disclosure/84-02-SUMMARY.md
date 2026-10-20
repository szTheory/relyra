# Release CI repair — local verification

The Phase 78 producer's ExUnit counter now recognizes tests, properties, and
mixed summaries. It counts both execution types while retaining zero-evidence,
command-exit, overflow, identity, and diagnostic guards.

The regression failed on the old parser and passed after the correction. It
executes the production parser against mixed, singular, property-only, aggregate,
zero, and absent execution summaries. It runs in the mandatory ordinary test lane.

Verification on Elixir 1.19.5 / OTP 28:

- Focused Phase 78 contract: 12 tests, 0 failures (1 excluded).
- `mix qa`: exit 0; 5 properties, 1089 tests, 0 failures (12 excluded).
- `mix ci.security`: exit 0; separate-process security suites preserved.
- `mix format --check-formatted`, `bash -n`, and `git diff --check`: exit 0.
- Replay of both original OTP 27/28 diagnostic logs: actual qa command exit 0;
  the corrected counter recognizes 1093 executions (1088 tests + 5 properties).

The first local QA attempt used an older Hex archive and lacked compiled demo
test metadata. After selecting the installed Hex 2.5.1 archive and compiling the
demo in test mode, the complete QA command passed. No source change was needed
for these local setup differences.

Remote release CI, squash merge, and Hex publication remain pending. The user
authorized the squash merge once CI is green; disclosure is still unapproved.
