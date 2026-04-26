# Architecture Research — Enterprise Configuration

**Domain:** enterprise configuration for an Elixir/Phoenix SAML SP
**Researched:** 2026-04-25
**Confidence:** MEDIUM-HIGH

## Standard Architecture

### System Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                         Phoenix presentation                       │
│  Router / LoginController / ACSController / MetadataController     │
├────────────────────────────────────────────────────────────────────┤
│                     Relyra runtime orchestration                   │
│  start_login/3   consume_response/3   build_sp_metadata/2          │
├────────────────────────────────────────────────────────────────────┤
│               Connection + trust-resolution boundary               │
│  Relyra.ConnectionResolver  →  %Relyra.Connection{}               │
│  Relyra.UserMapper          →  %Relyra.Principal{} + mapping cfg   │
│  RequestStore / ReplayStore  →  login intent + replay state        │
├────────────────────────────────────────────────────────────────────┤
│                 Enterprise config domain (new in v0.2)             │
│  connection aggregate | certificates | mappings | metadata refresh │
│  audit trail          | staged rollover | validation/diff           │
├────────────────────────────────────────────────────────────────────┤
│                        Host app database / Repo                     │
│  Ecto schemas + migrations live in the host app, not a library Repo │
└────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Status |
|---|---|---|
| `Relyra.ConnectionResolver` | Resolve one tenant-scoped trust/config snapshot for a request. | Modified existing |
| `%Relyra.Connection{}` | Runtime-only value object consumed by protocol core. | Modified existing |
| `Relyra.Protocol.Metadata` | Render SP metadata from a resolved connection. | Modified existing |
| `Relyra.UserMapper` | Consume persisted mapping config, not raw schema records. | Modified existing |
| `Relyra.Audit` / `Relyra.Telemetry` | Record config writes, refreshes, rollover promotions, mapping changes. | Modified existing |
| `Relyra.Ecto.Connection` | Canonical connection aggregate persistence. | New |
| `Relyra.Ecto.Certificate` | Certificate inventory + status + expiry metadata. | New |
| `Relyra.Ecto.Mapping` / versioned mapping tables | Persist attribute/group mapping rules. | New |
| `Relyra.Ecto.AuditEvent` | Durable audit history for config mutations. | New |
| `Relyra.ConnectionResolver.Ecto` | Hydrate `%Relyra.Connection{}` from persisted config. | New |
| `Relyra.Metadata.Import` / `Refresh` | Fetch, parse, diff, and stage IdP metadata changes. | New |
| `Relyra.CertificateRollover` | Promote staged trust and signal expiry. | New |

## Recommended Project Structure

```
lib/relyra/
├── connection.ex                # runtime trust snapshot
├── connection_resolver.ex       # public behaviour
├── connection_resolver/ecto.ex   # v0.2 adapter
├── protocol/                    # unchanged protocol core
├── metadata/                    # import/refresh/diff service
├── ecto/                        # host-app schema helpers + migrations
├── audit.ex                     # config-change audit emission
└── telemetry.ex                 # config-change spans
```

### Structure Rationale

- **Runtime stays value-object based:** protocol modules should never know about Ecto schemas.
- **Persistence is an adapter concern:** config lives in the host app DB, matching the existing store-adapter pattern.
- **Metadata and rollover are separate services:** import/refresh changes trust material; rollover promotes it.

## Architectural Patterns

### Pattern 1: Aggregate snapshot, not live schema access

**What:** load config rows, normalize them into `%Relyra.Connection{}` plus mapping/cert snapshots, and hand only the snapshot to runtime.
**When to use:** every login, metadata export, and ACS validation path.
**Trade-offs:** one extra translation step, but protocol core stays pure and testable.

### Pattern 2: Transactional config writes with audit side effects

**What:** write connection/certificate/mapping rows in one DB transaction, then emit audit/telemetry on commit.
**When to use:** admin saves, metadata refresh application, rollover promotion.
**Trade-offs:** slightly more plumbing, but avoids partial trust state.

### Pattern 3: Staged trust promotion

**What:** imported certs land as `next`/`staged`, then are promoted after validation; old certs remain usable until retirement.
**When to use:** certificate rollover and metadata refresh.
**Trade-offs:** more state, but avoids downtime during IdP rotation.

## Data Flow

### Request Flow

```
Admin/API import or edit
    ↓
Config service validates changes
    ↓
Ecto transaction writes connection/cert/mapping rows
    ↓
Audit + telemetry emitted
    ↓
ConnectionResolver.Ecto loads snapshot at runtime
    ↓
Protocol core consumes %Relyra.Connection{}
```

### State Management

```
Config tables
   ↓ snapshot
ConnectionResolver.Ecto
   ↙            ↘
%Relyra.Connection{}   mapping/cert metadata
   ↓                    ↓
runtime login/ACS       UserMapper / signature verify
```

### Key Data Flows

1. **Runtime resolution:** request hits login/ACS/metadata endpoint → resolver loads one connection aggregate → runtime receives pure values only.
2. **Metadata onboarding:** operator imports metadata XML/URL → parse and diff → stage trust changes → audit → optionally promote.
3. **Certificate rollover:** new cert stored alongside old cert → verification accepts both during overlap → expiry warning fires → old cert retired.
4. **Mapping application:** persisted mapping version is resolved with the connection → `UserMapper` applies it to the verified principal.

## Scaling Considerations

| Scale | Architecture Adjustments |
|---|---|
| 0-1k users | Single host Repo + straightforward aggregates are enough. |
| 1k-100k users | Add read-side caching for resolved connections and cert material. |
| 100k+ users | Split config read models from write models only if resolution latency becomes visible. |

### Scaling Priorities

1. **First bottleneck:** repeated config reads on login. Cache resolved connection snapshots, not raw rows.
2. **Second bottleneck:** metadata refresh churn. Keep diff/apply transactional and operator-driven.

## Anti-Patterns

### Anti-Pattern 1: Ecto structs in protocol core

**What people do:** pass schema structs into `Protocol.*` or `UserMapper`.
**Why it's wrong:** leaks persistence into the auth boundary and breaks testability.
**Do this instead:** resolve to `%Relyra.Connection{}` and plain mapping data first.

### Anti-Pattern 2: Blind metadata auto-apply

**What people do:** poll IdP metadata and activate changes immediately.
**Why it's wrong:** silent trust drift is dangerous and hard to audit.
**Do this instead:** fetch, diff, stage, then promote explicitly.

### Anti-Pattern 3: Single cert field

**What people do:** store `idp_signing_cert` as one binary.
**Why it's wrong:** rollover becomes an outage.
**Do this instead:** persist multiple cert rows with lifecycle state.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---|---|---|
| Host app Repo | Passed through opts/config | Keep data in the host database; no library-owned Repo. |
| IdP metadata URL | Explicit fetch via `Req` | Operator-triggered refresh only for v0.2. |
| Optional admin UI | Mount later on top of config APIs | UI must not define storage semantics. |

### Internal Boundaries

| Boundary | Communication | Notes |
|---|---|---|
| `ConnectionResolver` ↔ config tables | adapter/service | schema structs must not escape upward |
| `ConnectionResolver` ↔ runtime | value snapshot | runtime only sees `%Relyra.Connection{}` |
| `Protocol.Metadata` ↔ connection snapshot | pure render | export SP metadata from resolved config |
| `UserMapper` ↔ mapping config | pure data input | no free-form mapping DSL in v0.2 |
| `Audit` ↔ write paths | event emission | every trust change gets history |

## Recommended Build Order

1. **Connection aggregate + migrations** — everything else depends on durable tenant-scoped config.
2. **Ecto-backed `ConnectionResolver`** — runtime must consume the new config before automation ships.
3. **Metadata export + import/refresh service** — onboarding depends on a stable artifact.
4. **Certificate inventory + staged rollover** — highest-risk enterprise config feature.
5. **Mapping persistence + versioning** — authorization inputs need audit and rollback.
6. **Optional admin surface** — only after the write/read APIs are stable.

## Sources

- `.planning/PROJECT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `lib/relyra.ex`
- `lib/relyra/connection.ex`
- `lib/relyra/connection_resolver.ex`
- `lib/relyra/request_store.ex`
- `lib/relyra/replay_store.ex`
- `lib/relyra/protocol/metadata.ex`
- `lib/relyra/phoenix/controllers/metadata_controller.ex`
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`

---
*Architecture research for: enterprise configuration for an Elixir/Phoenix SAML SP*
*Researched: 2026-04-25*
