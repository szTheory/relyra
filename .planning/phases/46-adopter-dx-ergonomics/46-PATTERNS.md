# Phase 46 — Pattern Map

**Mapped:** 2026-05-27  
**Phase:** 46 — Adopter DX & ergonomics

## File Classification

| File | Role | Closest Analog | Pattern to Replicate |
|------|------|----------------|---------------------|
| `lib/relyra/install/router_injector.ex` | New injector module | `Sigra.Install.Injector` | Marker idempotency, `{:ok, contents}` / `{:already_injected, contents}` / `:ambiguous` |
| `lib/mix/tasks/relyra.install.ex` | Mix task orchestrator | Existing config sentinel injection (`ensure_config!/0`) | `# --- Relyra START/END ---` marker discipline |
| `README.md` | Adopter landing | Oban/Bandit README tradition | Code snippet above fold, narrative below |
| `guides/overview.md` | Doc hub | `guides/getting_started.md` structure | Relative markdown links, section headers |
| `guides/batteries_included.md` | Stub redirect | N/A (new pattern) | Minimal link to root canonical doc |
| `lib/mix/tasks/relyra.batteries_included.ex` | Drift generator | Self (existing) | Provider list from `Relyra.Provider.fetch!/1` |
| `mix.exs` | CI + ExDoc config | Phase 41 `ci.docs` additions | `cmd test -f` presence gates |

## Code Excerpts

### Config sentinel idempotency (replicate for router)

```71:95:lib/mix/tasks/relyra.install.ex
  defp ensure_config! do
    File.mkdir_p!("config")

    path = "config/config.exs"
    sentinel_start = "# --- Relyra START ---"
    sentinel_end = "# --- Relyra END ---"
    # ...
    if String.contains?(existing, sentinel_start) do
      :ok
    else
      File.write!(path, existing <> snippet)
    end
  end
```

### Canonical saml_routes usage shape

```1:12:test/phoenix/router_test.exs
defmodule Relyra.Phoenix.TestRouter do
  use Phoenix.Router
  import Relyra.Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/" do
    pipe_through(:browser)
    saml_routes()
  end
end
```

### apply_defaults snippet shape (README source)

```57:63:guides/recipes/okta.md
connection =
  Relyra.Provider.apply_defaults(:okta, [
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    idp_sso_url: "https://example.okta.com/app/.../sso/saml",
    idp_certificates: ["-----BEGIN CERTIFICATE-----"]
  ])
```

### Sigra injector idempotency contract

```25:39:/Users/jon/projects/sigra/lib/sigra/install/injector.ex
  def inject_router_plugs(file_contents, plug_code) do
    if String.contains?(file_contents, @marker) do
      {:already_injected, file_contents}
    else
      case find_last_end(file_contents) do
        {:ok, position} ->
          {before, rest} = String.split_at(file_contents, position)
          {:ok, before <> "\n" <> plug_code <> "\n" <> rest}
        :error ->
          {:ok, file_contents <> "\n" <> plug_code <> "\n"}
      end
    end
  end
```

### ci.docs presence gate pattern

```166:174:mix.exs
      "ci.docs": [
        "cmd test -f guides/batteries_included.md",
        "cmd test -f BATTERIES_INCLUDED.md",
        "cmd test -f guides/identity_mapping_and_provisioning.md",
        # ...
      ],
```

## Integration Flow

```
README (snippet + overview link)
    ↓
guides/overview.md (Day-1/2/Reference hub)
    ↓
getting_started.md (ExDoc main — unchanged)
    ↓
mix relyra.install → RouterInjector → host router
    ↓
mix relyra.batteries_included --check → BATTERIES_INCLUDED.md
```

## PATTERN MAPPING COMPLETE
