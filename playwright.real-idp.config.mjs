import { defineConfig, devices } from "@playwright/test";

const outputDir = process.env.REAL_IDP_CANARY_PLAYWRIGHT_TMP_DIR;

if (!outputDir) {
  throw new Error(
    "REAL_IDP_CANARY_PLAYWRIGHT_TMP_DIR must be set by scripts/test_real_idp_canary.sh",
  );
}

export default defineConfig({
  testDir: "./demo/ledger_loop/test/browser",
  testMatch: /real_idp_canary\.spec\.ts/,
  outputDir,
  fullyParallel: false,
  forbidOnly: true,
  retries: 0,
  workers: 1,
  reporter: [["list"]],
  timeout: 120_000,
  expect: { timeout: 30_000 },
  use: {
    headless: true,
    trace: "off",
    screenshot: "off",
    video: "off",
    actionTimeout: 20_000,
    navigationTimeout: 60_000,
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
