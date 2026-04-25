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

## Reporting a vulnerability

Use a private GitHub Security Advisory or contact the maintainers privately.
Please do not open a public issue for a potential security bug.

Include:

- Affected version.
- Reproduction steps.
- Impact assessment.
- Any sample payloads needed to verify the issue.
