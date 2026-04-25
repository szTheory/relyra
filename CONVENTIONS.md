# Conventions

## Validation order

Relyra validates in one direction only:

1. Parse safely.
2. Check issuer / connection binding.
3. Verify signature.
4. Bind the signed node.
5. Check status.
6. Check destination, audience, recipient, and time windows.

## Stores

- Request store handles one-time request intent consumption.
- Replay store handles assertion replay protection.
- Production deployments should use cluster-safe storage.

## Tenancy

- Treat `connection_id` as the routing key.
- Never resolve a connection implicitly from user-controlled XML.

## Unsafe options

- Any compatibility override must be explicit, time-boxed, and auditable.
- Unsafe defaults are not acceptable.
