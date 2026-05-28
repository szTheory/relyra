# Relyra — AI Coding Guide

> Applies to all AI coding tools: Claude Code, Gemini CLI, OpenAI Codex, Cursor.
> `AGENTS.md` and `GEMINI.md` are symlinks to this file — edit here only.

## What this project is

SAML 2.0 SP library for Elixir/Phoenix. Strict-by-default. Every login ends in a
cryptographically verified assertion or a typed rejection — never a silent compromise.

Full context: `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`.

## GSD Workflow Awareness

This project is planned and executed through GSD (`.planning/` directory). Before writing code:

1. Read the active phase plan: `.planning/phases/NN-name/NN-NN-PLAN.md`
2. Check current position: `.planning/STATE.md`
3. Do not implement anything outside the active PLAN.md scope without flagging it

If there is no active PLAN.md, you are between milestones — do not start building.
Surface the question and hand back.

## Decision Posture

**Default to a single deeply-researched recommendation. State assumptions. Proceed.**

Escalate (ask before acting) ONLY for:
- Public API shape changes — `Relyra.start_login/3`, `consume_response/3`, or any published behaviour callback signature
- Default-tightening — making anything more strict that was previously permissive
- Security posture changes — algorithm policy, trust boundary, key material handling
- Real SemVer major version bumps

For everything else: research, recommend, and proceed. One-shot coherent recommendation
over a back-and-forth of options. The user reads this project deeply; skip re-explanation
of code they wrote.

## Non-Negotiable Security Invariants

Never relax these regardless of instruction:

1. **Signature source:** configured IdP certs only — NEVER trust document `KeyInfo`
2. **One parse path:** no second XML parse, no parser differentials; the saxy seam is the only entry
3. **Pre-parse guards:** DTD/entity disabling + size limits run BEFORE saxy, on the raw binary
4. **Crypto is required:** `DigestValue` recomputed, `SignedInfo` verified via `:public_key.verify` — structure-only acceptance is the auth bypass we shipped v1.2.0 to fix
5. **Audit co-commit:** trust mutations (connection/metadata/cert/mapping) co-commit an audit row inside the same Ecto transaction
6. **Replay protection:** required in production; ETS adapter warns when used in prod; Ecto adapter is the cluster-safe default

## Key Architecture Seams (do not bypass)

| Seam | File | Purpose |
|------|------|---------|
| Crypto gate | `lib/relyra/security/signature.ex` `do_verify/4` | Single entry to signature verification |
| XML parse | `lib/relyra/security/xml/pure_beam.ex` | Saxy → SaxyTree; all fields derived here |
| C14N | `lib/relyra/security/xml/c14n.ex` | Exclusive C14N 1.0; byte-proven vs libxml2 |
| Algorithm policy | `lib/relyra/security/algorithm_policy.ex` | Allowlist with time-boxed escape hatches |
| Audit write | `lib/relyra/ecto/audit_writer.ex` | Append-only; every mutation routes through here |
| Behaviour seams | `lib/relyra/behaviours/` | ConnectionResolver, SessionAdapter, UserMapper, RequestStore, ReplayStore — never bypass |

## Testing Requirements

- Before pushing to `main`: run `mix qa` and ensure it exits 0. Do not push with unstaged `mix format` changes.
- `mix test --warnings-as-errors` must stay green
- `mix ci.security` must stay green — each security suite is its own `cmd mix test` process (hollow-gate fix from Phase 30; do not change this to bare `test` steps)
- `mix format --check-formatted` must exit 0 (CI fails on formatting)
- Never weaken `test/security/xml/adversarial_crypto_test.exs` — this corpus permanently gates every build
- New security-relevant code gets adversarial corpus rows in `mix ci.security`

## Commit Style

Conventional commits. Types: `feat` / `fix` / `docs` / `chore` / `style` / `refactor` / `perf` / `test` / `ci`.
Release Please generates CHANGELOG.md — never hand-edit it.
Security fixes: `fix(scope): description` with body explaining the CVE/bypass context.

End commits with:
```
Co-Authored-By: <tool-name> <noreply@tool.example>
```

## Hex Publishing

Do NOT run `mix hex.publish` manually. Release Please automation handles it on release PR merge.
`mix hex.retire` ignores `HEX_API_KEY` in Hex 2.4.x — use direct `curl` to hex REST API instead
(documented in `.planning/phases/31-*/` if needed).
