---
phase: 57-demo-fakeidp-browser-login-proof
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - demo/ledger_loop/lib/ledger_loop/application.ex
  - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
  - demo/ledger_loop/lib/ledger_loop/fake_idp/keypair.ex
  - demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex
  - demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/sso.html.heex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex
  - demo/ledger_loop/lib/ledger_loop_web/router.ex
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 57: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed the Phase 57 demo FakeIdP browser-login proof: a deliberately-labelled local
test IdP inside `demo/ledger_loop`. The core crypto path (anti-divergence digest +
SignedInfo signing via Relyra's own public C14N engine) is the riskiest surface and is
implemented soundly — it reuses the verifier's parse/canonicalize seams exactly as the
plan intends, so a passing signature is a genuine cryptographic pass.

No BLOCKER-tier defects found. The committed RSA key under `priv/fake_idp/` is an
acknowledged demo-only secret and is correctly treated as such (not flagged). However,
there are several correctness and robustness defects worth fixing, the most notable being
that an attacker-influenced field (`InResponseTo`, parsed from the inbound `SAMLRequest`)
is interpolated into the emitted XML with **no XML escaping**, and a UI/behaviour mismatch
where the login form advertises a `NameID` the controller never actually emits.

## Warnings

### WR-01: `InResponseTo` (attacker-influenced) interpolated into XML without escaping

**File:** `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex:139`, with source at `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex:116-124`

**Issue:** `extract_in_response_to/1` parses the `ID` attribute out of the inbound
`SAMLRequest` (browser-supplied, deflated base64) via `Regex.run(~r/\bID="([^"]+)"/, xml)`
and threads it through as `in_response_to`. `response_xml/3` then interpolates that value
**raw** into `InResponseTo="#{fields.in_response_to}"` with no XML escaping. The capture
class `[^"]+` excludes `"`, so a quote-based attribute breakout is not possible, but the
captured value may legally contain `<`, `>`, and `&`. Those produce malformed XML in the
emitted Response. The blast radius is bounded (the malformed Response is then re-parsed by
the signer's own `SaxyTree.parse`, which will typically fail and crash the request with a
`MatchError` from `parse_tree!/1` rather than emit anything), but it is an unhandled
crash path driven by untrusted input. The same raw-interpolation pattern applies to every
field in `response_xml/3`; the others derive from trusted fixtures, so only `in_response_to`
is externally influenced.

**Fix:** XML-escape all interpolated values (at minimum the externally-influenced one).
Either escape at emission:
```elixir
defp xml_escape(nil), do: ""
defp xml_escape(s) do
  s
  |> String.replace("&", "&amp;")
  |> String.replace("<", "&lt;")
  |> String.replace(">", "&gt;")
  |> String.replace("\"", "&quot;")
end
# ...
"<Response Destination=\"#{xml_escape(fields.destination)}\" InResponseTo=\"#{xml_escape(fields.in_response_to)}\" ...>"
```
or tighten the extractor regex to the SAML `ID` (xsd:ID/NCName) grammar so non-name
characters are rejected before they reach the template.

### WR-02: Login form advertises `evaluator@example.com`, controller emits `sarah@northstar.example.com`

**File:** `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex:34` vs `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex:31`

**Issue:** The radio label reads "Valid Login (evaluator@example.com)", but `conn_fields/0`
hardcodes `name_id: "sarah@northstar.example.com"`. Worse, `evaluator@example.com` is not a
seeded `SAMLIdentity` subject — `Fixtures.saml_identities/0` only seeds `sarah@...` and
`chen@...`. If anyone "fixes" the controller to honor the label, the login would fail user
mapping. The UI makes a promise the system does not keep, which is exactly the kind of
divergence that erodes trust in a proof harness.

**Fix:** Make the label match the emitted subject, e.g.
`Valid Login (sarah@northstar.example.com)`, or thread the `name_id` from the form and
validate it against a seeded subject.

### WR-03: Unexpected `idp_action` value crashes with `CaseClauseError`

**File:** `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex:65-98`

**Issue:** `action = params["idp_action"] || "success"` only defaults when the param is
absent. The subsequent `case action do "success" -> ... ; "failure" -> ... end` has no
catch-all, so any other posted value (`idp_action=foo`, or an array/map from a crafted
multipart body) raises `CaseClauseError` → 500. Since this is an unauthenticated POST
endpoint, it is a trivially reachable unhandled-input crash.

**Fix:** Add a fallback clause that treats unknown actions as `"success"` (or returns a
400):
```elixir
case action do
  "failure" -> ...tampered...
  _ -> ...success...
end
```

### WR-04: `inflate/1` accepts unbounded decompressed output (zip-bomb amplification)

**File:** `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex:126-139`

**Issue:** `inflate/1` performs a single-shot `:zlib.inflate/2` on browser-supplied,
base64-decoded bytes with no decompressed-size cap. A small crafted `SAMLRequest` can
inflate to a very large binary, which is then scanned by `Regex.run` over the whole string.
Relyra's own raw-binary pre-parse guards (size limits before saxy) exist precisely to stop
this on the verifier side, but this demo decompresses untrusted input before any such guard.
For a local demo the exposure is limited, but it is an avoidable memory-amplification path
on an unauthenticated GET handler.

**Fix:** Bound the inflate output (use `:zlib.inflateChunk/1` in a loop with a byte ceiling,
or set a max accepted compressed-input length and reject oversized requests up front), then
fail closed to `nil` on overflow — consistent with the existing "garbled input → nil"
contract documented at lines 113-124.

### WR-05: `tamper/1` regex silently no-ops if `<NameID>` carries attributes or namespacing

**File:** `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex:102-106`

**Issue:** `String.replace(xml, ~r/<NameID>([^<]+)<\/NameID>/, "<NameID>TAMPERED</NameID>")`
matches only a bare `<NameID>` open tag with no attributes and no namespace prefix. The
signer's current template emits exactly `<NameID>...</NameID>`, so it works today — but the
coupling is implicit and undocumented. If `response_xml/3` is later changed to add a `Format`
attribute or a prefix (both common in real SAML), `tamper/1` becomes a silent no-op:
`signed_response` + `tamper` would return a *valid* signed Response, and the "Invalid Login
(Tampered Signature)" path would unexpectedly **succeed**. A tamper helper that can silently
fail to tamper is a dangerous false-negative for a rejection proof.

**Fix:** Make the no-op detectable — assert the replacement actually changed the bytes:
```elixir
tampered = String.replace(xml, ~r/<NameID[^>]*>([^<]+)<\/NameID>/, "<NameID>TAMPERED</NameID>")
if tampered == xml, do: raise("tamper/1 failed to locate <NameID>; template drifted")
Base.encode64(tampered)
```

## Info

### IN-01: `cert_pem/0` re-reads cert from disk on every call (no caching, unlike `private_key/0`)

**File:** `demo/ledger_loop/lib/ledger_loop/fake_idp/keypair.ex:44-47`

**Issue:** The module docstring (lines 9-11) advertises `:persistent_term` caching to "avoid
repeated disk I/O and PEM parsing on every signing call," and `private_key/0` honors that.
`cert_pem/0` does a fresh `File.read!` every call. It is consumed at compile time by
`Fixtures` (so the hot path is unaffected), but the behaviour contradicts the documented
caching intent and would surprise a future caller invoking it at runtime.

**Fix:** Either cache `cert_pem/0` in `:persistent_term` for symmetry, or narrow the
docstring to clarify only the private key is cached.

### IN-02: `load_private_key/0` crashes opaquely if the PEM has multiple entries

**File:** `demo/ledger_loop/lib/ledger_loop/fake_idp/keypair.ex:58`

**Issue:** `[entry] = :public_key.pem_decode(pem_bin)` hard-matches a single-entry PEM. A
key file with a trailing cert or extra block raises a bare `MatchError` with no context. The
demo file is correct today, so this is purely a diagnosability nit.

**Fix:** Pattern-match the expected entry type and raise a descriptive error on mismatch.

### IN-03: `extract_in_response_to/2` regex matches the first `ID="..."` anywhere in the document

**File:** `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex:119`

**Issue:** `~r/\bID="([^"]+)"/` returns the first `ID` attribute encountered, not
specifically the root `AuthnRequest/@ID`. For a well-formed SP `AuthnRequest` the root ID is
first, so it works; but a request with a child element bearing an earlier `ID` would yield
the wrong correlation value. Acceptable for a demo harness, but worth a comment noting the
assumption (the existing comment at lines 111-113 describes inflation, not the
first-match assumption).

**Fix:** Anchor to the root element's `ID` (e.g. parse with `SaxyTree` and read the root
`attrs`, reusing the engine already in `Signer`), or document the first-match assumption.

### IN-04: `relay_state` round-tripped into a hidden form field without explicit escaping reliance noted

**File:** `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex:21`, `sso.html.heex:18`

**Issue:** `@relay_state` (and `@saml_response`) flow from request params into hidden inputs.
HEEx attribute interpolation auto-HTML-escapes, so there is no XSS here — this is correctly
relying on the framework. Noting it only because the value is request-derived and the safety
is implicit; a one-line comment that escaping is delegated to HEEx would make the trust
boundary explicit for future readers. No change required.

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
