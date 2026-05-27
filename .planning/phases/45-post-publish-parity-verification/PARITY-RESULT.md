# Parity Result — relyra 1.4.0

**Generated:** 2026-05-27T21:24:04Z
**Git tag:** v1.4.0
**Hex version:** 1.4.0

## Tarball checksums (informational)

| Source | SHA-256 |
|--------|---------|
| Hex API (`hex.pm/api/.../releases/1.4.0`) | 727594d614eaa1f65b3958c78b83d667debbf8e9d7ff0cde0240a193c60ce5b6 |
| Local `mix hex.build` at v1.4.0 | unavailable |

> Outer tar SHA256 may differ while package contents match. Pass/fail uses path-set diff, not outer bytes.

## Path-set parity

- `mix verify.release_parity 1.4.0` exit code: 0
- Only in git: 0 (none)
- Only in Hex: 0 (none)

## test_support (TD-02 defense-in-depth)

- Published paths containing `test_support`: 0
- Result: PASS

## Release metadata

- `mix hex.audit`: exit 0 — No retired packages found
- `mix ci.release`: exit 0

## Verdict

**PASS**

Path-set parity confirmed for relyra 1.4.0; zero test_support paths in published tarball; mix hex.audit and mix ci.release both green.
