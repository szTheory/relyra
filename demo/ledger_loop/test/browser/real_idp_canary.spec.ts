import { writeFile } from "node:fs/promises";
import { expect, test } from "@playwright/test";

type CanaryStatus =
  | "passed"
  | "unexpected_origin"
  | "idp_rejected"
  | "callback_failure"
  | "provider_failure";

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error("real IdP canary preflight was not completed");
  return value;
}

test("approved real IdP login returns to the configured LedgerLoop workspace", async ({
  page,
}) => {
  const statusPath = required("REAL_IDP_CANARY_RESULT_PATH");
  const loginUrl = required("REAL_IDP_CANARY_SP_LOGIN_URL");
  const spOrigin = required("REAL_IDP_CANARY_SP_ORIGIN");
  const idpOrigin = required("REAL_IDP_CANARY_IDP_ORIGIN");
  const username = required("REAL_IDP_CANARY_USERNAME");
  const password = required("REAL_IDP_CANARY_PASSWORD");
  const usernameSelector = required("REAL_IDP_CANARY_USER_SELECTOR");
  const passwordSelector = required("REAL_IDP_CANARY_PASSWORD_SELECTOR");
  const submitSelector = required("REAL_IDP_CANARY_SUBMIT_SELECTOR");
  let status: CanaryStatus = "provider_failure";

  try {
    await page.goto(loginUrl, { waitUntil: "domcontentloaded" });

    // Credentials are entered only after the browser has reached the exact,
    // preconfigured HTTPS IdP origin.
    const currentIdpUrl = new URL(page.url());
    if (currentIdpUrl.protocol !== "https:" || currentIdpUrl.origin !== idpOrigin) {
      status = "unexpected_origin";
      throw new Error("real IdP canary origin check failed");
    }

    await page.locator(usernameSelector).fill(username);
    await page.locator(passwordSelector).fill(password);
    await page.locator(submitSelector).click();

    try {
      await page.waitForURL((url) => url.origin === spOrigin, { timeout: 90_000 });
    } catch {
      const currentOrigin = new URL(page.url()).origin;
      if (currentOrigin !== idpOrigin && currentOrigin !== spOrigin) {
        status = "unexpected_origin";
      } else if (
        currentOrigin === idpOrigin &&
        (await page.locator('[role="alert"]').isVisible().catch(() => false))
      ) {
        status = "idp_rejected";
      } else {
        status = "callback_failure";
      }

      throw new Error("real IdP canary did not complete the configured callback");
    }

    const returnUrl = new URL(page.url());
    if (returnUrl.protocol !== "https:" || returnUrl.origin !== spOrigin) {
      status = "unexpected_origin";
      throw new Error("real IdP canary returned outside the approved SP origin");
    }

    const workspace = page.locator("#workspace-title");
    if (!(await workspace.isVisible().catch(() => false))) {
      status = "callback_failure";
      throw new Error("real IdP canary callback did not reach the authenticated workspace");
    }

    await expect(workspace).toBeVisible();
    status = "passed";
  } catch {
    throw new Error(`real IdP canary status: ${status}`);
  } finally {
    await writeFile(statusPath, `${status}\n`, { encoding: "utf8", mode: 0o600 });
  }
});
