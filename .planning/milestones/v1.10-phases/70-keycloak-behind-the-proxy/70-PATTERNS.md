# Phase 70: Keycloak behind the proxy - Pattern Map

**Mapped:** 2026-08-26  
**Files analyzed:** 12 planned new/modified files  
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `docker-compose.yml` | config | request-response | `docker-compose.proxy.yml` | role-match |
| `docker-compose.proxy.yml` | config | request-response | existing `demo_app` proxy overlay | exact |
| `docker/keycloak/realm-demo-app.json` | config | transform | existing realm import JSON | role-match |
| `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex` | service | request-response | `Relyra.Metadata.Import` + `Relyra.Ecto.Connections` | role/data-flow composition |
| `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex` | controller | request-response | same controller | exact |
| `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex` | component | request-response | same login template | exact |
| `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` | test | CRUD | `connection_scenarios_test.exs` | role-match |
| `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs` | test | request-response | same controller test | exact |
| `demo/ledger_loop/test/browser/keycloak.spec.ts` | test | request-response | `fake_idp.spec.ts` | exact journey shape |
| `scripts/test_keycloak_proxy_e2e.sh` | utility | batch | `scripts/test_fleet_proxy_e2e.sh` | exact lifecycle pattern |
| `package.json` | config | event-driven | existing npm script registry | exact |
| `playwright.keycloak-proxy.config.mjs` (only if a dedicated selector/config is needed) | config | request-response | `playwright.fleet-proxy.config.mjs` | exact |

## Pattern Assignments

### `docker-compose.yml` and `docker-compose.proxy.yml` (config, request-response)

**Analogs:** `docker-compose.proxy.yml`; `docker-compose.yml`

Keep base Compose responsible for private application composition and profile membership; apply browser-facing host identity, Traefik labels, and the external network in the proxy overlay. This is the Phase 69 split rather than a second Keycloak overlay.

**Proxy environment, labels, and dual networks** — `docker-compose.proxy.yml:2-17`:

```yaml
demo_app:
  environment:
    PHX_HOST: ${RELYRA_HOST:-relyra.localhost}
    PHX_SCHEME: http
    PHX_PORT: "80"
  labels:
    - "traefik.enable=true"
    - "traefik.docker.network=${DEMO_PROXY_NETWORK:-proxy}"
    - "traefik.http.routers.relyra-local-demo.rule=Host(`${RELYRA_HOST:-relyra.localhost}`)"
    - "traefik.http.services.relyra-local-demo.loadbalancer.server.port=4000"
  networks:
    - default
    - proxy
```

Copy this shape for `keycloak`, changing only the Relyra-prefixed router/service names and private target port to `8080`. Use one `RELYRA_HOST` to derive `keycloak.${RELYRA_HOST:-relyra.localhost}`; retain `DEMO_PROXY_NETWORK` only as the narrow network hook.

**Existing profile/health pattern to replace** — `docker-compose.yml:43-65`:

```yaml
keycloak:
  image: quay.io/keycloak/keycloak:26.0.7
  profiles: ["keycloak"]
  command: start-dev --import-realm --http-port=8080
  environment:
    KC_HTTP_ENABLED: "true"
    KC_HEALTH_ENABLED: "true"
  healthcheck:
    interval: 5s
    timeout: 5s
    retries: 30
    start_period: 30s
```

Preserve the optional profile, import mount, and bounded health-check rhythm, but remove `ports`, dynamic/localhost hostname settings, and the app-port health URL. Set the locked full public `KC_HOSTNAME`, `KC_PROXY_HEADERS=xforwarded`, and health on internal management `:9000`; Traefik must route only port `8080`.

---

### `docker/keycloak/realm-demo-app.json` (config, transform)

**Analog:** existing `docker/keycloak/realm-demo-app.json`

**Client contract layout** — `docker/keycloak/realm-demo-app.json:28-51`:

```json
{
  "clientId": "http://localhost:4000",
  "name": "Relyra Demo SP",
  "enabled": true,
  "protocol": "saml",
  "rootUrl": "http://localhost:4000",
  "baseUrl": "http://localhost:4000",
  "adminUrl": "http://localhost:4000/saml/sso/acs",
  "redirectUris": ["http://localhost:4000/saml/sso/acs"],
  "attributes": {
    "saml.server.signature": "true",
    "saml.assertion.signature": "true",
    "saml.force.post.binding": "true"
  }
}
```

Retain the signed POST SAML client attributes, including `saml.server.signature.keyinfo.ext: false`; replace every public endpoint field with `${RELYRA_HOST}`-derived public values and the stable connection-scoped `/saml/<keycloak-id>/{metadata,acs}` routes. Replace the admin user with the dedicated Sarah persona. Never place `keycloak:8080`, `demo_app:4000`, or direct localhost URLs in browser-visible realm fields.

---

### `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex` (service, request-response)

**Analogs:** `lib/relyra/ecto/connections.ex`; `lib/relyra/metadata/import.ex`; `lib/relyra/ecto/metadata_apply.ex`; `lib/relyra/ecto/certificate_inventory.ex`

This new, demo-owned service orchestrates existing audited seams; it must not copy the fixture/reset module's bulk-insert pattern. It fetches descriptor bytes over private service DNS, then creates/reconciles a separate draft connection, applies descriptor-derived metadata and certificates, creates the host identity, and enables last. Ordinary `LedgerLoop.Demo.Reset.reset!/0` remains independent.

**Draft-first connection mutation with co-committed audit** — `lib/relyra/ecto/connections.ex:13-34`, `:49-72`, `:126-149`:

```elixir
with {:ok, repo} <- fetch_repo(opts, :create),
     :ok <- ensure_optional_dependency!(:create, repo) do
  changeset = @connection_schema.draft_changeset(struct(@connection_schema), attrs)

  transact(repo, fn ->
    with {:ok, record} <- persist_changeset(repo, changeset, :insert, :create),
         {:ok, audited_record} <-
           maybe_append_audit(repo, record, %{}, connection_trust_view(record),
             :created, changeset_changed_fields(changeset), opts) do
      {:ok, audited_record}
    end
  end)
end
```

```elixir
changeset = @connection_schema.publish_changeset(connection, %{})
before_view = connection_trust_view(connection)

transact(repo, fn ->
  with {:ok, record} <- persist_changeset(repo, changeset, :update, :enable),
       {:ok, audited_record} <-
         maybe_append_audit(repo, record, before_view, connection_trust_view(record),
           :enabled, [:status], opts) do
    {:ok, audited_record}
  end
end)
```

Call the public `Relyra.Ecto.Connections.create/update/enable` seams with `repo: LedgerLoop.Repo` and a non-empty audit map (`actor`, `cause`, `correlation_id`); do not use their private helpers or bare trust-state inserts.

**Descriptor parsing and metadata apply** — `lib/relyra/metadata/import.ex:13-53`:

```elixir
case Parser.parse(xml, opts) do
  {:ok, parsed} ->
    candidate = build_candidate(parsed)

    MetadataApply.apply_revision(connection_id, Map.from_struct(candidate), %{
      source_kind: :xml_import,
      trigger: :manual_import,
      actor: Keyword.get(opts, :actor, "unknown"),
      cause: Keyword.get(opts, :cause, "manual import"),
      content_hash_sha256: sha256(xml),
      trust_summary: candidate.trust_summary
    }, opts)

  {:error, %Error{} = error} ->
    _ = MetadataApply.record_attempt(connection_id, %{outcome: failure_outcome(error),
      content_hash_sha256: sha256(xml)}, opts)
    {:error, error}
end
```

Use `Relyra.Metadata.Import.import_xml/3`, not hand-written PEM parsing. It builds the candidate, derives fingerprints, stages metadata certificates, and records failures through the existing metadata path. Supply redacted diagnostics only; never log descriptor XML or PEM.

**Certificate staging and explicit activation vocabulary** — `lib/relyra/ecto/certificate_inventory.ex:10-35`, `:48-64`:

```elixir
def stage_metadata_certificates(repo, connection, revision, candidate, opts \\ [])

def activate_signing_certificate(repo, connection_id, fingerprint, opts \\ [])
```

Do not direct-insert a certificate. Reconcile the runtime-generated Keycloak certificate through metadata apply/inventory before `enable`; test fresh descriptor keys and idempotent no-op runs.

---

### `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex` and `route_affordance_html/login.html.heex` (controller/component, request-response)

**Analogs:** same controller and template

**Minimal controller-to-template data flow** — `route_affordance_controller.ex:4-7`:

```elixir
def login(conn, _params) do
  conn_id = LedgerLoop.Demo.Fixtures.relyra_enabled_scenario_id()
  render(conn, :login, conn_id: conn_id)
end
```

Add only the provisioned Keycloak connection ID/availability needed to render the conditional link. Keep route ownership and native browser semantics; do not add a parallel login endpoint or modify the `/saml/:connection_id` mount.

**Existing semantic link form** — `route_affordance_html/login.html.heex:3-19`:

```heex
<main class="route-affordance" aria-labelledby="login-title">
  <h1 id="login-title">Start Test Login</h1>
  <div style="margin: 2rem 0;">
    <a href={"/saml/#{@conn_id}/login"} class="button button-primary">
      Simulate Login via FakeIdP
    </a>
  </div>
</main>
```

Keep FakeIdP as the first, always-present deterministic affordance. Add an optional native `<a>` only when provisioning makes the Keycloak connection usable, with the locked accessible name `Test with Keycloak (optional real IdP)`. Replace stale Phase-55 copy with the exact verified-receipt wording without claiming a cookie session.

---

### `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` (test, CRUD)

**Analog:** `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs`

**DataCase setup and durable-state assertions** — `connection_scenarios_test.exs:1-10`, `:27-47`:

```elixir
defmodule LedgerLoop.Demo.ConnectionScenariosTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Demo.Reset
  alias Relyra.Ecto.{Connection, AuditEvent}
  alias LedgerLoop.Repo

  setup do
    Reset.reset!()
    :ok
  end
end
```

```elixir
certs = Repo.all(Ecto.assoc(enabled_conn, :certificates))
assert Enum.any?(certs, &(&1.lifecycle_state == :active and &1.role == :signing))
```

Make this provisioner-specific test inject/fake the bounded descriptor transport while exercising the real Repo and audited Relyra command seams. Assert exactly one separate enabled connection, correct public issuer + Sarah identity, active descriptor certificate, audit rows, rotation reconciliation, and no duplicate/no-op audit churn on a second run. Also assert partial/fetch/apply failure leaves the connection disabled/draft and creates no receipt.

---

### `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs` (test, request-response)

**Analog:** same controller test

**ConnCase route assertion** — `route_affordance_controller_test.exs:1-10`:

```elixir
use LedgerLoopWeb.ConnCase, async: true

test "renders the login page with a FakeIdP SSO link", %{conn: conn} do
  conn = get(conn, "/login/test")
  expected_id = LedgerLoop.Demo.Fixtures.relyra_enabled_scenario_id()
  assert html_response(conn, 200) =~ "/saml/#{expected_id}/login"
end
```

Add two narrow assertions: no Keycloak link when unprovisioned, and the semantic Keycloak link with its stable scoped `/saml/<keycloak-id>/login` target when provisioned. Preserve the existing FakeIdP assertion.

---

### `demo/ledger_loop/test/browser/keycloak.spec.ts` (test, request-response)

**Analog:** `demo/ledger_loop/test/browser/fake_idp.spec.ts`

**Accessible initiation and semantic workspace assertion** — `fake_idp.spec.ts:13-32`:

```typescript
await page.goto("/login/test");
await page.getByRole("link", { name: "Simulate Login via FakeIdP" }).click();
await expect(page.locator("#workspace-title")).toHaveText(/LedgerLoop Workspace/);
await expect(page).toHaveURL(/\/$/);
```

**Exact ACS POST capture for a trust outcome** — `fake_idp.spec.ts:45-59`:

```typescript
const acsResponse = page.waitForResponse(
  (r) => r.url().includes("/acs") && r.request().method() === "POST",
);
const resp = await acsResponse;
expect(resp.status()).toBe(400);
```

Replace (do not extend) the stale Keycloak spec. Start from the optional accessible link, assert navigation to the public `keycloak.relyra.localhost` origin, submit the dedicated Sarah persona, capture the exact stable connection ACS POST and successful redirect, assert semantic workspace plus the exact verified receipt language, then use `/login/admin` and the existing trace page to assert the correlation-specific successful steps. Do not access Postgres, mutate XML, use ambiguous selectors, or put credentials in artifacts.

---

### `scripts/test_keycloak_proxy_e2e.sh`, `package.json`, and optional `playwright.keycloak-proxy.config.mjs` (utility/config, batch/request-response)

**Analogs:** `scripts/test_fleet_proxy_e2e.sh`; `package.json`; `playwright.fleet-proxy.config.mjs`

**Hermetic lifecycle, trap cleanup, and redacted diagnostics** — `scripts/test_fleet_proxy_e2e.sh:17-77`:

```bash
mkdir -p "$ARTIFACT_DIR"

wait_for_http() {
  local url="$1"
  shift
  for _attempt in $(seq 1 60); do
    if curl --noproxy "*" -fsS "$@" "$url" >/dev/null; then return 0; fi
    sleep 1
  done
  return 1
}

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  if [[ "$status" -ne 0 ]]; then capture_diagnostics; fi
  "${FLEET_COMPOSE[@]}" down --remove-orphans >/dev/null 2>&1 || true
  exit "$status"
}
trap cleanup EXIT INT TERM
```

Copy the refusal-to-reuse-active-stack, network ownership, teardown, and host-side Playwright architecture. Extend static rendered-config checks to verify both default and overridden host pairs, no Keycloak host port, port-9000 non-routing, dual networks, full hostname/xforwarded, and no stale realm URLs. Distinguish proxy/DNS, Keycloak readiness, provisioner/metadata, browser authentication, ACS, mapping, and receipt failure layers; diagnostics must redact credentials, SAML payloads, XML, and PEMs.

**Root script registry** — `package.json:4-8`:

```json
"scripts": {
  "admin-ui:smoke": "playwright test --config playwright.admin-ui.config.mjs",
  "demo:fake-idp": "playwright test --config playwright.fake-idp.config.mjs",
  "demo:fleet-proxy": "bash scripts/test_fleet_proxy_e2e.sh"
}
```

Add the scoped `demo:keycloak-proxy` entry using the same direct shell-script convention. Do not add Phase 71 launcher/Makefile UX.

**Single-spec Playwright configuration** — `playwright.fleet-proxy.config.mjs:6-35`:

```javascript
export default defineConfig({
  testDir: "./test/browser",
  testMatch: /fleet_proxy\.spec\.mjs/,
  fullyParallel: false,
  workers: 1,
  timeout: 60_000,
  use: { baseURL: process.env.BASE_URL || "http://localhost:4000", headless: true },
  projects: [{
    name: "chromium",
    use: { ...devices["Desktop Chrome"], launchOptions: { args: [
      "--host-resolver-rules=MAP relyra.localhost 127.0.0.1,MAP sibling.localhost 127.0.0.1"
    ]}}
  }]
});
```

If the existing config cannot select the TypeScript Keycloak spec, add the smallest dedicated config copying this shape and mapping both public hosts to `127.0.0.1`. Do not re-enable the Compose `playwright` service for the supported proof.

## Shared Patterns

### Audited trust mutation

**Source:** `lib/relyra/ecto/connections.ex:229-253`
**Apply to:** Keycloak provisioner connection create/update/enable calls.

```elixir
audit_attrs = %{
  connection_record_id: record.id,
  domain: :connection,
  action: action,
  actor: Map.get(audit, :actor),
  cause: Map.get(audit, :cause),
  correlation_id: Map.get(audit, :correlation_id),
  before_view: before_view,
  after_view: after_view
}

case AuditWriter.append_event(repo, audit_attrs) do
  {:ok, _event} -> {:ok, record}
  {:error, %Error{} = error} -> rollback(repo, error)
end
```

Never replace this with bare certificate/connection `insert_all`; each trust mutation needs actor, cause, correlation, and atomic audit co-commit.

### Host identity and receipt boundary

**Source:** `demo/ledger_loop/lib/ledger_loop/relyra/user_mapper.ex:13-30`; `session_adapter.ex:18-40`
**Apply to:** provisioner identity tests, controller copy, and browser proof.

```elixir
subject = principal.name_id
issuer = connection.idp_entity_id

from identity in SAMLIdentity,
  where: identity.subject == ^subject and identity.issuer == ^issuer
```

```elixir
case Repo.insert(changeset) do
  {:ok, receipt} -> {:ok, receipt_proof}
  {:error, _changeset} ->
    {:error, Relyra.Error.new(:session_establishment_failed, "Failed to insert LoginReceipt")}
end
```

Keycloak must persist its public browser issuer and Sarah NameID exactly, and proof language must call the result a host-owned session-establishment receipt, not a browser authorization cookie.

### Scoped SAML route

**Source:** `demo/ledger_loop/lib/ledger_loop_web/router.ex:65+`; `fake_idp_flow_test.exs:72-101`
**Apply to:** realm ACS/client configuration, login affordance, browser assertions.

```elixir
assert body3 =~ "action=\"/saml/#{@conn_ulid}/acs\""
conn4 = post(build_conn(), "/saml/#{@conn_ulid}/acs", %{
  "SAMLResponse" => saml_response,
  "RelayState" => relay_state
})
assert conn4.status == 302
```

Use the exact stable Keycloak connection-scoped metadata/login/ACS URLs; do not restore legacy global `/auth/saml/*` or `/saml/sso/acs` routes.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex` | service | request-response | No existing demo service fetches a live IdP descriptor; compose the audited Relyra seams above. |
| `scripts/test_keycloak_proxy_e2e.sh` | utility | batch | No Keycloak-specific lifecycle harness exists; extend the Phase 69 hermetic proxy harness. |

## Metadata

**Analog search scope:** `docker*`, `docker/keycloak`, `scripts`, root Playwright config/package scripts, `demo/ledger_loop`, and audited Relyra Ecto/metadata seams.  
**Files scanned:** 23  
**Pattern extraction date:** 2026-08-26
