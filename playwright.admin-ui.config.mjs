import os from "node:os";
import path from "node:path";
import { defineConfig } from "@playwright/test";

const baseURL = process.env.RELYRA_ADMIN_UI_BASE_URL || "http://127.0.0.1:4101";

export default defineConfig({
  testDir: "./test/browser",
  testMatch: /admin_ui_smoke\.spec\.mjs/,
  timeout: 60_000,
  outputDir: path.join(os.tmpdir(), "relyra-playwright-output"),
  fullyParallel: false,
  workers: 1,
  use: {
    baseURL,
    headless: true
  },
  webServer: {
    command: 'mix run --no-halt -e "Relyra.TestSupport.LiveAdminBrowserServer.start!()"',
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    env: {
      ...process.env,
      MIX_ENV: "test"
    }
  }
});
