import { defineConfig, devices } from "@playwright/test";

const PORT = process.env.PORT || "4000";
const BASE_URL = process.env.BASE_URL || `http://127.0.0.1:${PORT}`;
const outputDir = process.env.TRACE_VISUAL_PLAYWRIGHT_TMP_DIR;

if (!outputDir) {
  throw new Error(
    "TRACE_VISUAL_PLAYWRIGHT_TMP_DIR must be set by scripts/test_trace_visual_e2e.sh",
  );
}

export default defineConfig({
  testDir: "./demo/ledger_loop/test/browser",
  testMatch: /trace_visual\.spec\.ts/,
  outputDir,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: 0,
  workers: 1,
  reporter: [["list"]],
  timeout: 60_000,
  use: {
    baseURL: BASE_URL,
    headless: true,
    trace: "off",
    screenshot: "off",
    video: "off",
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
