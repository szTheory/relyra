import { defineConfig, devices } from "@playwright/test";

const outputDir =
  process.env.FLEET_PROXY_OUTPUT_DIR || "test-results/fleet-proxy";

export default defineConfig({
  testDir: "./test/browser",
  testMatch: /fleet_proxy\.spec\.mjs/,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: 0,
  workers: 1,
  reporter: [["list"]],
  outputDir,
  timeout: 60_000,
  use: {
    baseURL: process.env.BASE_URL || "http://localhost:4000",
    headless: true,
    trace: "off",
    screenshot: "off",
    video: "off",
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
