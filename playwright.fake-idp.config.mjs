import { defineConfig, devices } from "@playwright/test";

// Dedicated config for the FakeIdP browser e2e. Separate from
// playwright.demo.config.mjs because (a) that config has no webServer and
// defaults to the docker-compose host, and (b) it also matches keycloak.spec.ts,
// which needs a running Keycloak. This config self-boots the demo app and runs
// only fake_idp.spec.ts, so it works standalone in GitHub Actions with just
// Postgres — no Keycloak, no docker.

const PORT = process.env.PORT || "4000";
const BASE_URL = process.env.BASE_URL || `http://127.0.0.1:${PORT}`;

export default defineConfig({
  testDir: "./demo/ledger_loop/test/browser",
  testMatch: /fake_idp\.spec\.ts/,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: "list",
  timeout: 60_000,
  use: {
    baseURL: BASE_URL,
    headless: true,
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: "mix ecto.setup && mix phx.server",
    cwd: "demo/ledger_loop",
    url: BASE_URL,
    timeout: 180_000,
    reuseExistingServer: !process.env.CI,
  },
});
