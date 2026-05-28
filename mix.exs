Code.require_file("lib/mix/tasks/compile/parser_path_guard.ex", __DIR__)

defmodule Relyra.MixProject do
  use Mix.Project

  @version "1.5.4"
  @source_url "https://github.com/szTheory/relyra"

  def project do
    [
      app: :relyra,
      version: @version,
      description: "Strict-by-default SAML 2.0 Service Provider library for Elixir and Phoenix.",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      compilers: [:parser_path_guard] ++ Mix.compilers(),
      elixirc_options: [ignore_module_conflict: true],
      source_url: @source_url,
      package: package(),
      docs: docs(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: [
        qa: :test,
        "ci.fast": :test,
        "ci.docs": :test,
        "ci.conformance": :test,
        "ci.security": :test,
        "ci.verify": :test,
        "ci.integration": :test,
        "ci.admin_ui": :test,
        "ci.oban_smoke": :test,
        "ci.release": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:prod), do: prod_elixirc_paths()
  defp elixirc_paths(_), do: ["lib"]

  # Production compiles an explicit lib/**/*.ex list omitting test_support (Mix accepts file paths).
  defp prod_elixirc_paths do
    Path.wildcard("lib/**/*.ex")
    |> Enum.reject(&String.contains?(&1, "test_support"))
    |> Enum.sort()
  end

  defp package_lib_files do
    Path.wildcard("lib/**/*")
    |> Enum.reject(&String.contains?(&1, "test_support"))
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Relyra.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:saxy, "~> 1.6"},
      {:telemetry, "~> 1.3"},
      {:plug, "~> 1.16"},
      {:phoenix, "~> 1.8", optional: true},
      {:phoenix_ecto, "~> 4.6", optional: true},
      {:phoenix_live_view, "~> 1.1", optional: true},
      {:bandit, "~> 1.5", only: :test, runtime: false},
      {:lazy_html, ">= 0.1.0", only: :test, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.13", optional: true},
      {:ecto_sql, "~> 3.13", optional: true},
      {:postgrex, ">= 0.0.0", optional: true},
      {:req, "~> 0.5", optional: true},
      {:oban, "~> 2.22", optional: true}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Documentation" => "https://hexdocs.pm/relyra",
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files:
        [
          "priv",
          "docs",
          "guides",
          ".formatter.exs",
          "mix.exs",
          "README.md",
          "CONFORMANCE.md",
          "CHANGELOG.md",
          "LICENSE",
          "SECURITY.md",
          "SECURITY_REVIEW.md",
          "SECURITY_REVIEW_EVIDENCE.md",
          "BATTERIES_INCLUDED.md"
        ] ++ package_lib_files()
    ]
  end

  defp docs do
    [
      main: "getting_started",
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html", "markdown"],
      extras: [
        "README.md",
        "guides/overview.md",
        "guides/getting_started.md",
        "guides/identity_mapping_and_provisioning.md",
        "guides/production_ecto_path.md",
        "guides/jtbd_user_flows.md",
        "guides/case_studies/phoenix_saas_tenant_onboarding.md",
        "guides/case_studies/operator_managed_rollout.md",
        "guides/recipes/okta.md",
        "guides/recipes/entra.md",
        "guides/recipes/google_workspace.md",
        "guides/recipes/adfs.md",
        "guides/recipes/generic_saml.md",
        "guides/recipes/logout.md",
        "guides/troubleshooting.md",
        "guides/operations/incident_playbook.md",
        "SECURITY.md",
        "SECURITY_REVIEW.md",
        "docs/security_boundary.md",
        "docs/security_findings.md",
        "CHANGELOG.md",
        "CONFORMANCE.md",
        "BATTERIES_INCLUDED.md",
        "SECURITY_REVIEW_EVIDENCE.md"
      ],
      groups_for_extras: [
        Introduction: ["README.md", "guides/overview.md"],
        "Day-1": [
          "guides/getting_started.md",
          "guides/identity_mapping_and_provisioning.md",
          "guides/production_ecto_path.md",
          "guides/jtbd_user_flows.md",
          "guides/case_studies/phoenix_saas_tenant_onboarding.md",
          "guides/case_studies/operator_managed_rollout.md"
        ],
        Recipes: [
          "guides/recipes/okta.md",
          "guides/recipes/entra.md",
          "guides/recipes/google_workspace.md",
          "guides/recipes/adfs.md",
          "guides/recipes/generic_saml.md",
          "guides/recipes/logout.md"
        ],
        Operations: [
          "guides/troubleshooting.md",
          "guides/operations/incident_playbook.md"
        ],
        Security: [
          "SECURITY.md",
          "SECURITY_REVIEW.md",
          "docs/security_boundary.md",
          "docs/security_findings.md"
        ],
        "Generated & audit": [
          "CHANGELOG.md",
          "CONFORMANCE.md",
          "BATTERIES_INCLUDED.md",
          "SECURITY_REVIEW_EVIDENCE.md"
        ]
      ]
    ]
  end

  defp aliases do
    [
      qa: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test --warnings-as-errors"
      ],
      "ci.fast": [
        "compile --warnings-as-errors",
        "test --warnings-as-errors --exclude integration"
      ],
      "ci.docs": [
        "cmd test -f guides/overview.md",
        "cmd test -f guides/batteries_included.md",
        "cmd test -f BATTERIES_INCLUDED.md",
        "cmd test -f guides/identity_mapping_and_provisioning.md",
        "cmd test -f guides/production_ecto_path.md",
        "cmd test -f guides/recipes/adfs.md",
        "cmd test -f guides/recipes/generic_saml.md",
        "cmd test -f guides/recipes/logout.md",
        "cmd test -f guides/troubleshooting.md",
        "cmd test -f guides/operations/incident_playbook.md",
        "cmd mix test test/docs/markdown_link_smoke_test.exs --warnings-as-errors",
        "cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors",
        "cmd mix test test/docs/logout_recipe_drift_test.exs --warnings-as-errors",
        "test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors",
        "test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors",
        "relyra.batteries_included --check"
      ],
      "ci.conformance": [
        "test test/conformance/sp_conformance_test.exs test/mix/tasks/relyra_conformance_test.exs --only conformance --warnings-as-errors",
        "relyra.conformance --check"
      ],
      "ci.security": [
        "compile --warnings-as-errors",
        "ci.conformance",
        "cmd test -f SECURITY_REVIEW.md",
        "cmd test -f docs/security_boundary.md",
        "cmd grep -nE \"docs/security_findings.md|Findings Ledger\" SECURITY_REVIEW.md",
        "relyra.security_review --check",
        # each security suite below runs as its own `cmd mix test` (a fresh OS process) on
        # purpose: mix dedups the `test` task within a single alias run, and `ci.conformance`
        # (above) already runs `test` once with `--only conformance` — so any *bare* `test`
        # step here would be silently skipped AND inherit `--only conformance`, leaving the
        # gate hollow (a regression would ship green). keep each suite on its own
        # `cmd mix test` line so it actually executes and gates. do not "simplify" these
        # back into one `test` line. the meta-gate test/security/ci_gate_integrity_test.exs
        # enforces this invariant.
        "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
        "cmd mix test test/security/strict_default_proof_test.exs --warnings-as-errors",
        "cmd mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors",
        "cmd mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus --warnings-as-errors",
        "cmd mix test test/security/xml/corpus_security_test.exs --only gate02_c14n --warnings-as-errors",
        "cmd mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors",
        "cmd mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors",
        "cmd mix test test/security/xml_enc_test.exs --warnings-as-errors",
        "cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors",
        "cmd mix test test/security/metadata_attribute_injection_test.exs --warnings-as-errors",
        "cmd mix test test/security/login_trace_test.exs --warnings-as-errors",
        # decimal advisory GHSA-rhv4-8758-jx7v (Decimal.new exponent DoS) is ignored:
        # decimal is transitive via ecto/postgrex (both pin `decimal ~> 2.0`, so 3.0.0 — the
        # only patched version — is unreachable), and relyra makes no direct Decimal.new/parse
        # calls (no exposure path). Revisit when ecto/postgrex allow decimal ~> 3.0.
        "deps.audit --ignore-advisory-ids GHSA-rhv4-8758-jx7v",
        "hex.audit",
        "sobelow --config"
      ],
      "ci.verify": [
        "ci.docs",
        "test test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs --warnings-as-errors"
      ],
      "ci.integration": [
        "test --only integration --warnings-as-errors"
      ],
      "ci.admin_ui": [
        "test test/phoenix/live_admin_test.exs test/relyra/live_admin/connections_live_test.exs test/relyra/live_admin/connection_metadata_live_test.exs test/relyra/live_admin/phase15_ui_contract_test.exs --warnings-as-errors"
      ],
      "ci.oban_smoke": [
        "compile --no-optional-deps --warnings-as-errors",
        "compile --warnings-as-errors",
        "test --include oban --warnings-as-errors test/relyra/optional_deps/oban_test.exs test/relyra/workers/metadata_refresh_test.exs"
      ],
      "ci.release": [
        "test test/release/release_hardening_test.exs --warnings-as-errors"
      ]
    ]
  end
end
