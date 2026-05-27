# Phase 49 Pattern Map

**Mapped:** 2026-05-27  
**Phase:** 49 — Adoption honesty

---

## File Roles

| File | Role | Analog |
|------|------|--------|
| `lib/mix/tasks/relyra.conformance.ex` | CONFORMANCE.md generator | Phase 25 conformance task — append section like `cve_summary_lines/1` |
| `priv/conformance/sp_manifest.json` | Executable manifest rows | Existing pass/reject rows (e.g. `sp-response-consume-pass`) |
| `test/conformance/sp_conformance_test.exs` | Manifest row evaluator | `evaluate_row` for `sp-response-consume-pass` |
| `test/security/xml_enc_adversarial_test.exs` | ENC positive control | `FakeIdP.encrypted_response()` + `Application.put_env(:relyra, :sp_private_key_pem, ...)` |
| `docs/jtbd_gap_map.md` | Internal JTBD planning doc | Phase 47/48 doc refresh pattern |
| `guides/recipes/generic_saml.md` | Decoder table + generic path | Existing IBM/CyberArk/PingFederate rows |
| `guides/getting_started.md` §4 | Preset taxonomy for adopters | Phase 47 §3 rewrite pattern |
| `README.md` | Preset taxonomy source of truth | Phase 41 TD-04 framing — verify, don't narrow |

---

## Code Excerpts

### render_report append point

```elixir
# lib/mix/tasks/relyra.conformance.ex:79-101
defp render_report(%{conformance_rows: conformance_rows, security_rows: security_rows}) do
  [
    # ... existing sections ...
    "## CVE-REG-01 Regression Coverage",
    "",
    security_rows_table(security_rows),
    ""  # <-- append scope_boundary_section() before final join
  ]
  |> Enum.join("\n")
end
```

### Manifest pass row shape

```json
{
  "id": "sp-response-consume-pass",
  "status": "pass",
  "expected_outcome": {"result": "ok"}
}
```

### evaluate_row pass pattern

```elixir
defp evaluate_row(%{"id" => "sp-response-consume-pass"} = row) do
  assert {:ok, login_result} =
           Relyra.consume_response(
             genuinely_signed_fixture_xml(row),
             request_intent(),
             consume_opts(now: @fixed_now)
           )
  %{"result" => "ok"}
end
```

### ENC setup pattern (from xml_enc_adversarial_test.exs)

```elixir
setup do
  keypair = FakeIdP.keypair()
  pem = :public_key.pem_encode([
    {:RSAPrivateKey, :public_key.der_encode(:RSAPrivateKey, keypair), :not_encrypted}
  ])
  Application.put_env(:relyra, :sp_private_key_pem, pem)
  on_exit(fn -> Application.delete_env(:relyra, :sp_private_key_pem) end)
  :ok
end
```

### Decoder table row template

```markdown
| PingFederate | `Partner's Entity ID` | `Assertion Consumer Service URL` | ... |
```

---

## PATTERN MAPPING COMPLETE
