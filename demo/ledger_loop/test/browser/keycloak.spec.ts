import { expect, test } from "@playwright/test";

const connectionId = "01H0B4Y1A2B3C4D5E6F7G8H9J4";
const sarahPassword = process.env.KEYCLOAK_SARAH_PASSWORD || "sarah-password";
const adminUsername = process.env.DEMO_ADMIN_USERNAME;
const adminPassword = process.env.DEMO_ADMIN_PASSWORD;

test("Keycloak signs Sarah into LedgerLoop through the public scoped ACS", async ({
  page,
}) => {
  await page.goto("/login/test");
  await page
    .getByRole("link", { name: "Test with Keycloak (optional real IdP)" })
    .click();

  await expect
    .poll(() => new URL(page.url()).origin)
    .toBe("http://keycloak.relyra.localhost");
  await page.locator("#username").fill("sarah@northstar.example.com");
  await page.locator("#password").fill(sarahPassword);

  const acsResponse = page.waitForResponse(
    (response) =>
      new URL(response.url()).pathname === `/saml/${connectionId}/acs` &&
      response.request().method() === "POST",
  );

  await page.locator("#kc-login").click();

  expect((await acsResponse).status()).toBe(302);
  await expect(page).toHaveURL("http://relyra.localhost/");
  await expect(page.locator("#workspace-title")).toHaveText("LedgerLoop Workspace");
  await expect(page.getByText("Verified sign-in receipt")).toBeVisible();
  await expect(
    page.getByText(
      "Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt.",
    ),
  ).toBeVisible();

  if (!adminUsername || !adminPassword) {
    throw new Error("DEMO_ADMIN_USERNAME and DEMO_ADMIN_PASSWORD are required");
  }

  const adminAuthorization = `Basic ${Buffer.from(
    `${adminUsername}:${adminPassword}`,
  ).toString("base64")}`;

  await page.setExtraHTTPHeaders({ authorization: adminAuthorization });
  await page.goto("/login/admin");
  await expect(page).toHaveURL("http://relyra.localhost/relyra/admin");
  await page.goto(`/relyra/admin/connections/${connectionId}/trace`);

  const newestSuccessfulTrace = page
    .locator('[data-testid^="login-trace-row-"]')
    .filter({ hasText: "succeeded" })
    .first();

  await expect(newestSuccessfulTrace).toContainText(/correlation [\w-]+/);

  for (const [step, label] of [
    ["response.validate", "Validate response"],
    ["signature.verify", "Verify signature"],
    ["replay.check", "Replay check"],
  ]) {
    const stepRow = newestSuccessfulTrace.locator(
      `[data-testid="login-trace-step-${step}"]`,
    );

    await expect(stepRow).toContainText(label);
    await expect(stepRow).toContainText("ok");
  }
});
