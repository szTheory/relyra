import { defineConfig, devices } from "@playwright/test";

const reportDir =
  process.env.FLEET_PROXY_REPORT_DIR || "playwright-report/fleet-proxy";

export default defineConfig({
  testDir: "./test/browser",
  testMatch: /fleet_proxy\.spec\.mjs/,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [
    ["list"],
    ["html", { outputFolder: reportDir, open: "never" }],
  ],
  timeout: 60_000,
  use: {
    baseURL: process.env.BASE_URL || "http://localhost:4000",
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
            "--host-resolver-rules=MAP relyra.localhost 127.0.0.1,MAP sibling.localhost 127.0.0.1",
          ],
        },
      },
    },
  ],
});
