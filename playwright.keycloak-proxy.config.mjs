import { tmpdir } from "node:os";
import { join } from "node:path";
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./demo/ledger_loop/test/browser",
  testMatch: /keycloak\.spec\.ts/,
  outputDir:
    process.env.KEYCLOAK_PROXY_PLAYWRIGHT_TMP_DIR ||
    join(tmpdir(), "relyra-keycloak-playwright-no-attachments"),
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [["list"]],
  timeout: 60_000,
  use: {
    baseURL: process.env.BASE_URL || "http://relyra.localhost",
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
            "--host-resolver-rules=MAP relyra.localhost 127.0.0.1,MAP keycloak.relyra.localhost 127.0.0.1",
          ],
        },
      },
    },
  ],
});
