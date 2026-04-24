# ADR 0001: XML Security Strategy

## Status

Accepted (Phase 01 baseline decision)

## Context

Relyra must lock one XML security strategy before protocol implementation begins so
every downstream phase depends on the same trust boundary. The project requires a
single parser trust path, deterministic typed failures, and a pre-declared fallback
if acceptance gates expose canonicalization or signed-node correctness gaps.

## Options Considered

### pure-beam single parser (saxy)

Pure BEAM keeps the runtime simple, preserves first-class Elixir observability,
and avoids native build/distribution overhead in v0.1. The tradeoff is that
canonicalization and signed-node correctness confidence depends entirely on the
fixture corpus and strict gate discipline in this repository.

### NIF over xmlsec

NIF over `xmlsec` increases correctness confidence by leaning on mature XMLDSig
primitives, but it materially increases release complexity with precompiled target
matrices, native dependency management, and checksum/provenance expectations.

### hybrid+xmlsec verify path

Hybrid keeps most library behavior in pure BEAM while delegating signature verify
and canonicalization hard cases to xmlsec. The tradeoff is a split execution model
that still inherits native supply-chain and CI/release complexity.

## Decision

Selected strategy: pure-beam single parser (saxy).

## Decision Rule

Maintain one parser trust path and reject malformed or dangerous XML before trust
decisions. Reassess strategy only through explicit phase gates and ADR updates.
If canonicalization or signed-node acceptance gates fail, switch to hybrid+xmlsec without changing Relyra.Security.XML callbacks.

## Consequences

- Phase 2+ must consume `Relyra.Security.XML` seam outputs and typed `%Relyra.Error{}`.
- Parser usage outside the XML seam must be blocked by compile-time and CI guards.
- A conditional NIF policy remains required if strategy changes to hybrid or NIF.

## Conditional NIF Policy (GATE-03)

If strategy moves to hybrid/NIF, release artifacts must cover this target matrix:

- Linux GNU x86_64
- Linux GNU aarch64
- Linux musl x86_64
- macOS aarch64
- macOS x86_64

Required release artifact: checksum manifest.
Release gate: publish is blocked if checksum verification fails.
Windows remains source-build best effort unless adoption pressure justifies precompiled artifacts.

## Rollback Trigger

If acceptance gates show canonicalization or signed-node correctness failures that
cannot be resolved within the pure-BEAM seam, move to a hybrid+xmlsec path while
preserving `Relyra.Security.XML` callback compatibility.
