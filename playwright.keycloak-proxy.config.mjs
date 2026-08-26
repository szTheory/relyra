import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./demo/ledger_loop/test/browser",
  testMatch: /keycloak\.spec\.ts/,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [["list"]],
  timeout: 60_000,
  use: {
    baseURL: process.env.BASE_URL || "http://relyra.localhost",
    headless: true,
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        launchOptions: {
          args: [
            "--host-resolver-rules=MAP relyra.localhost 127.0.0.1,MAP keycloak.relyra.localhost 127.0.0.1",
          ],
        },
      },
    },
  ],
});
