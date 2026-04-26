# Security Policy

## Threat model

Relyra sits on the SAML trust boundary. The library assumes the IdP is
untrusted input and treats all inbound XML, signatures, RelayState values,
and response metadata as potentially hostile.

## Supported algorithms

- SHA-256+ for signatures.
- SHA-256+ for digest methods.
- SHA-1 is rejected unless a time-boxed legacy override is explicitly configured.

## Non-negotiables

- DTDs and external entities stay disabled before parse.
- Signatures are verified against configured certificates only.
- Raw RelayState URLs are rejected.
- Replay protection is required.
- Raw assertions/responses must not be logged.

## Release prerequisites

Before tagging or publishing a release:

- Confirm the public domain / namespace values still match the deployed EntityID,
  ACS URL, and metadata URL surface.
- Confirm any Keycloak example uses a pinned image tag and refresh that pin only
  after checking the upstream release notes.
- Run the release parity lane (`mix ci.release`) before publish.

## Reporting a vulnerability

Use a private GitHub Security Advisory or contact the maintainers privately.
Please do not open a public issue for a potential security bug.

Include:

- Affected version.
- Reproduction steps.
- Impact assessment.
- Any sample payloads needed to verify the issue.
