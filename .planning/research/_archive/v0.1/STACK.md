# Stack Research

**Domain:** enterprise configuration for an Elixir/Phoenix SAML SP
**Researched:** 2026-04-25
**Confidence:** MEDIUM

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Ecto | ~> 3.13.5 | Schemas, changesets, embeds, typed config state | This milestone is mostly about durable, audited config state. Ecto 3.13.5 gives `embedded_schema`, `Ecto.Enum`, `Ecto.ParameterizedType`, `Repo.transact/2`, and map-backed embeds that fit connection/certificate/mapping records well. |
| Ecto SQL | ~> 3.13.5 | Migrations, DDL, indexes, transactional schema changes | Use it for connection/cert/mapping tables, unique constraints, partial indexes, and safe migration ordering. It is the current stable line and matches Ecto 3.13.x. |
| Postgrex | ~> 0.19.3 | Postgres adapter for the reference deployment | Current `ecto_sql` 3.13.5 still requires `postgrex ~> 0.19 or ~> 1.0`, so the latest `0.22.0` line is **not** compatible yet. Pin the 0.19 line until Ecto SQL widens support. |
| Jason | ~> 1.4.4 | JSON codec for `:map` columns and embeds | Ecto/Postgrex document Jason as the default JSON path. Enterprise config will store embedded mapping/config blobs in JSONB, so keep the JSON library explicit instead of relying on transitive deps. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Req | ~> 0.5.17 | HTTP fetches for remote metadata refresh | Add this only if controlled refresh actually pulls metadata from IdP URLs. If refresh is upload-only, skip HTTP entirely and keep the core smaller. |
| Phoenix | ~> 1.8.5 | Existing runtime baseline | No backend config work needs a Phoenix bump; keep the shipped 1.8 line as-is. |
| Phoenix LiveView | not yet | Admin UI later | Do **not** add this for the storage/import/rollover milestone. LiveView 1.1 is a later admin-surface concern and requires Phoenix 1.8+ plus `lazy_html` in tests. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `mix ecto.gen.migration` / `mix ecto.migrate` | Create/apply config schema migrations | Host app owns the DB. Relyra should ship schemas and migration guidance, not a separate repo. |
| `mix format` with `import_deps: [:ecto, :ecto_sql]` | Keep migration and schema files formatted | Required once migrations and embedded schemas land. |
| HTTP stubs / `Req.Test` | Test controlled refreshes | Prefer stubbed refresh tests; do not hit live IdP metadata endpoints in unit tests. |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Jason | Elixir built-in JSON only | Consider only if the whole dependency tree is standardized on it and adapter support has been verified in your target stack. Jason is the conservative choice today. |
| Req | Finch | Use Finch only if the host app already standardizes on it or you need lower-level pool control. Req is simpler for a library feature that just needs safe fetches. |
| Ecto + host Repo | Library-owned Repo | Never make Relyra own the database. Enterprise config must live in the host app DB beside audit and identity data. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `postgrex 0.22.0` with `ecto_sql 3.13.5` | Incompatible dependency range today (`ecto_sql` still pins `~> 0.19 or ~> 1.0`). | Stay on `postgrex ~> 0.19.3` for this milestone. |
| Oban / scheduler infrastructure | Controlled refresh is not the same as background automation. | Keep refresh operator-triggered or host-app scheduled later. |
| LiveView in the config core path | Admin UI is a later milestone, not a storage prerequisite. | Keep LiveView optional and deferred. |
| A bespoke JSON/XML persistence layer | Recreates solved problems and complicates migration/audit work. | Use Ecto schemas + JSONB-backed embeds and keep XML parsing on the already-hardened boundary. |

## Stack Patterns by Variant

**If the host app already has a Repo:**
- Use that Repo for enterprise-config tables and audit rows.
- Keep Relyra as schema/migration guidance plus runtime helpers.

**If the host app is Postgres-backed:**
- Use Ecto SQL migrations, unique/partial indexes, and transactional updates.
- Prefer `Repo.transact/2` for import/refresh/rollover mutations.

**If metadata refresh reads from a URL:**
- Use Req for operator-triggered fetches.
- Keep refresh explicit; do not introduce a job runner just for v0.2.

**If the admin UI is added later:**
- Add `Phoenix.LiveView ~> 1.1` and `lazy_html` only then.
- Keep the admin surface optional so enterprise config stays usable from the host app without UI baggage.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Elixir 1.19 | OTP 26–28 | Matches the current project baseline and current Elixir support table. |
| Phoenix 1.8.5 | LiveView 1.1.x | LiveView 1.1 requires Phoenix 1.8+ and adds `lazy_html` for tests. |
| Ecto 3.13.5 | Ecto SQL 3.13.5 | Current stable pair for schemas, embeds, and migrations. |
| Ecto SQL 3.13.5 | Postgrex 0.19.x | This is the important pin; 0.22.0 is too new for the current dependency range. |
| Ecto/Postgrex | Jason 1.4.4 | Needed for `:map`/embed JSON encoding on Postgres; recompile the adapter if you swap JSON libraries. |

## Sources

- https://hexdocs.pm/ecto/embedded-schemas.html — embeds, `embedded_schema`, and `:map` storage guidance
- https://hexdocs.pm/ecto/Ecto.ParameterizedType.html — typed config fields and embedded behavior
- https://hexdocs.pm/ecto/Ecto.Repo.html — `Repo.transact/2`
- https://hex.pm/packages/ecto_sql/dependencies — current `ecto_sql` dependency constraints
- https://hexdocs.pm/ecto_sql/Ecto.Migration.html — migrations, indexes, and database-specific options
- https://hexdocs.pm/phoenix/changelog.html — Phoenix 1.8.5 baseline
- https://hexdocs.pm/phoenix_live_view/changelog.html — LiveView 1.1 requirements if admin UI is added later
- https://hexdocs.pm/elixir/compatibility-and-deprecations.html — Elixir/OTP support matrix
- https://hex.pm/packages/postgrex — latest driver line and publish date
- https://hex.pm/packages/jason — current JSON codec version
- https://hex.pm/packages/req — current HTTP client version for controlled refreshes

---
*Stack research for enterprise configuration milestone*
