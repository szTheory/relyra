# Phase 39: Logout Strategy & Operational Guidance - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 1
**Analogs found:** 1 / 1

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `guides/recipes/logout.md` | guide | static | `guides/identity_mapping_and_provisioning.md` | role-match |

## Pattern Assignments

### `guides/recipes/logout.md` (guide, static)

**Analog:** `guides/identity_mapping_and_provisioning.md`

**Title and Purpose pattern** (lines 1-6):
```markdown
# Identity Mapping And Provisioning

This guide is the operator-facing reference for the moment after SAML validation
has already succeeded. Use it to decide which verified identity field becomes
your local account anchor, whether login-time JIT is appropriate, and where
Relyra's responsibility ends.
```

**Code snippet referencing pattern** (lines 20-30):
```markdown
## `UserMapper` behaviour

`Relyra.UserMapper.map_attributes/3` is the host-owned seam between verified
SAML identity and your application's account policy.

On the Phoenix ACS success path, Relyra calls the mapper like this:

\`\`\`elixir
{:ok, login_result} = Relyra.consume_response(response_xml, consume_opts)
{:ok, mapped_user} = Relyra.UserMapper.map_attributes(login_result, login_result.connection, opts)
\`\`\`
```

**Sectioning pattern (Overview vs Ownership)** (lines 37-52):
```markdown
## Relyra owns / Host owns

## Relyra owns

- Response validation, signature verification, replay checks, and the verified
  login payload.
- The normalized identity facts exposed through `Relyra.LoginResult` and
  `Relyra.Principal`, such as `name_id`, `name_id_format`, and released
  attributes.
- The mapper and session seams where the host application takes over.

## Host owns

- Choosing the local account anchor.
- Looking up an existing account, deciding whether a new account may be created,
  and deciding which fields are safe to update on login.
- Authorization, tenant membership, offboarding, manual account linking, and
  every lifecycle action outside the successful login event.
```

## Shared Patterns

### Tone and Positioning
**Source:** `guides/identity_mapping_and_provisioning.md`
**Apply to:** `guides/recipes/logout.md`
```markdown
Treat this guide as a local identity policy document, not as a SAML theory
overview. The question is not "what can the IdP emit?" The question is "which
verified value should our app trust as the durable local anchor?"
```
*Note for Planner: Apply an assertive tone that establishes Relyra's stance and the necessary operational reality, demoting front-channel SLO as per `39-CONTEXT.md`.*

## No Analog Found

None.

## Metadata

**Analog search scope:** `guides/**/*.md`
**Files scanned:** 12
**Pattern extraction date:** 2026-05-27
