# Docker demo: one verified local login, then Fleet proofs

This guide is for an evaluator or maintainer who wants one complete Docker-backed
Relyra login without first assembling a local SSO environment. Its job is concrete:
start the LedgerLoop demo, complete the deterministic local IdP sign-in, and leave with
evidence you can inspect. Relyra remains a library; LedgerLoop is the host application
that maps the user, records its session-establishment receipt, and owns authorization.

## Gameplan

1. **Solo (required):** run one deterministic local-IdP login on loopback and inspect
   its validation trace plus LedgerLoop receipt.
2. **Fleet (follow-on):** after the Solo receipt, use the shared proxy to run this
   demo alongside sibling demos.
3. **Keycloak (optional follow-on):** after Fleet, use a real-IdP proof without
   replacing the deterministic Solo journey.

The repo-root `Makefile` is the public Docker interface. `scripts/demo` remains a
compatibility entry point, but it is not a second workflow.

## Mental model

Solo is a complete proof on its own. It publishes LedgerLoop at a loopback URL and
uses the demo-local identity provider, so you do not need Traefik, Fleet, or Keycloak to finish
the first journey. Relyra verifies the cryptographic assertion against configured
IdP certificates: configured IdP certificates are the trust source, never document
key material. LedgerLoop then performs host-owned user mapping and stores its own
session-establishment evidence.

## Solo: prove one local login

### Prerequisites

Install Docker with Compose v2, then work from the repository root. You do not need
to copy `.env.example` for the default Solo route.

To inspect the protected operator trace, choose and export both
`DEMO_ADMIN_USERNAME` and `DEMO_ADMIN_PASSWORD` in your shell before launch. These
are operator-chosen, runtime-only values; this repository supplies no reusable
credential values.

Run the launcher check first:

```bash
make doctor
```

If it reports a problem, follow the exact `Next:` remediation printed for that
problem before continuing. Port 4000 is the default Solo listener; do not guess at an
alternate Compose command. If that listener is occupied, choose one free port and carry
the same value through diagnosis, URL output, and launch:

```bash
PORT=4101 make doctor
PORT=4101 make url
PORT=4101 make up-build
```

`make url` prints a `Loopback:` origin. Use the origin it emits with `/login/test` for
the local IdP sign-in. For the protected operator trace, enter at `/login/admin`; browser
Basic Auth redirects a successful sign-in to `/relyra/admin`. After an override, do not
substitute the default port 4000.

### Start the deterministic demo

Build and launch the Solo stack:

```bash
make up-build
```

Open [http://localhost:4000/login/test](http://localhost:4000/login/test). Choose
the enabled connection, then select **Simulate Login via FakeIdP**. Complete the
deterministic sign-in offered by FakeIdP.

### Inspect the proof

Return to LedgerLoop after the assertion consumer service completes. Inspect the
operator validation trace through `/login/admin`, then inspect the resulting `LoginReceipt`
in the workspace evidence. If that entry returns a 401 challenge, set both
`DEMO_ADMIN_USERNAME` and `DEMO_ADMIN_PASSWORD`, restart the same Solo topology with
`make up-build`, and retry `/login/admin` at the origin emitted by `make url`.

Relyra verifies the cryptographic assertion and produces the validation trace.
LedgerLoop owns user mapping, owns the persisted session-establishment receipt, and
owns authorization. The receipt is not a claim that Relyra creates a browser cookie
or makes an authorization decision.

**Receipt:** Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt.

## What comes after Solo

Only after recording the Solo receipt should you move to Fleet or optional Keycloak.
They are follow-on proofs, not prerequisites for the deterministic FakeIdP path.

## Fleet: run beside sibling demos

Fleet is for a machine already running more than one Traefik-routed local demo. It
does not improve or replace the complete Solo receipt above. Start or reuse the shared
proxy, then use Fleet discovery to inspect the routed demos:

The same operator-chosen `DEMO_ADMIN_USERNAME` and `DEMO_ADMIN_PASSWORD` prerequisite
applies before inspecting this protected trace through `/login/admin`; Fleet does not
provide a public trace shortcut.

```bash
make proxy
make fleet
```

`make proxy` creates or reuses the external `proxy` network and starts the shared
Traefik instance. `make fleet` lists the currently routed demos; it does not activate
this checkout's proxy overlay or Keycloak profile.

### URL and topology map

| Proof or surface | Browser origin | Scope |
| --- | --- | --- |
| Solo LedgerLoop | `http://localhost:4000` by default; the `Loopback:` origin from `make url` after an override | Complete deterministic local proof |
| Fleet LedgerLoop | `http://relyra.localhost` | Follow-on proxy route |
| Optional Keycloak | `http://keycloak.relyra.localhost` | Follow-on real-IdP proof |
| Traefik dashboard | `http://localhost:8080/dashboard/` | Local routing diagnostics |

*.localhost is browser-facing. Docker service DNS is for container health checks,
Keycloak bootstrap traffic, and internal probes; do not put a browser on a container
service hostname, and do not ask an in-container probe to resolve a browser-only
localhost name.

## Optional Keycloak: a separate real-IdP proof

Keycloak is an optional Fleet proof after Solo. Its public browser origin is
`http://keycloak.relyra.localhost`; its private bootstrap and descriptor traffic stays
on Docker service DNS. The same operator-chosen `DEMO_ADMIN_USERNAME` and
`DEMO_ADMIN_PASSWORD` prerequisite applies before its protected trace journey; start the
complete optional proof with the public launcher:

```bash
make keycloak
```

`make keycloak` starts or reuses Traefik, launches this checkout's proxy overlay under
the Keycloak profile, waits for provisioning, and validates the public descriptor before
it prints routes. Keep the evidence lanes separate:

- FakeIdP is the first deterministic local proof and is the normal way to evaluate
  the guide.
- Keycloak is a separate real-IdP proof behind the proxy, never a prerequisite for
  FakeIdP.

**Receipt:** Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt. This remains host-owned LedgerLoop evidence: Relyra validates the assertion, while LedgerLoop maps the user, records its session-establishment receipt, and owns authorization.

## Caching and fast edits

Source is bind-mounted into the demo container, so ordinary source, template, and
asset edits move into the running Linux environment without copying host build
artifacts into it. The nested `deps/` and `_build/` paths use named Linux volumes;
they keep Linux compilation output separate from macOS or other host artifacts.

The entrypoint compares a `mix.lock` hash before resolving dependencies. It reruns
dependency resolution only when `mix.lock` changes (or its first-run stamp is absent),
so a normal source edit does not fetch or compile dependencies again. BuildKit
Hex/rebar download caches are supporting build-time detail: they make explicit image
rebuilds faster, but they are not the running container's dependency contract.

Use the Make surface for the expected loop:

```bash
make up          # start the existing Solo image for ordinary source edits
make up-build    # intentionally rebuild when dependency, Dockerfile, or config inputs change
```

## Recovery ladder

Work from the least disruptive correction to the strongest cleanup.

1. **Diagnose first.** Run `make doctor` and follow the exact `Next:` command it
   prints. This handles a busy configured Solo port, the shared-proxy listener on 8080,
   and a missing proxy network (`Next: make proxy`) without guessing. For a Solo override,
   reuse one chosen value with `PORT=<free-port> make doctor` and `PORT=<free-port> make url`,
   then launch it with the same value using the sequence shown above and browse to the emitted
   `Loopback:` origin.
2. **Normal restart.** Stop the Solo demo while preserving named volumes, then
   relaunch normally:

   ```bash
   make down
   make up-build
   ```

3. **Refresh demo data deliberately.** `make reset` and its `make reseed` alias run
   the same destructive database refresh: they drop and set up the demo database.
   Use this only when you want the seeded data rebuilt.

   ```bash
   make reset
   # or: make reseed
   ```

4. **Cold rebuild only with confirmation.** `make nuke` asks for explicit
   confirmation before it deletes demo data and build/dependency volumes (plus the
   demo Hex and Mix volumes). The next boot is a cold rebuild.

   ```bash
   make nuke
   ```

### Symptom → supported next step

| Symptom | Next step |
| --- | --- |
| Configured Solo port conflicts or shared proxy conflict on 8080 | Run `make doctor`; free the listener or apply its printed same-value `PORT=<free-port>` / proxy correction. |
| Missing proxy network | Run `make proxy`, then repeat the Fleet action. |
| Browser-only localhost does not work from a container | Keep browser traffic on the public origin and use Docker service DNS for internal traffic. |
| Keycloak public-host mismatch | Confirm the browser is using `http://keycloak.relyra.localhost`, then run `make doctor` and follow its printed proxy/port correction before restarting. |
