import { expect, test } from "@playwright/test";

const connectionId = "01H0B4Y1A2B3C4D5E6F7G8H9J4";
const sarahPassword = process.env.KEYCLOAK_SARAH_PASSWORD || "sarah-password";

test("Keycloak signs Sarah into LedgerLoop through the public scoped ACS", async ({
  page,
}) => {
  await page.goto("/login/test");
  await page.getByRole("link", { name: "Sign in with Keycloak" }).click();

  await expect(page).toHaveURL(/keycloak\.relyra\.localhost/);
  await page.locator("#username").fill("sarah@northstar.example.com");
  await page.locator("#password").fill(sarahPassword);

  const acsResponse = page.waitForResponse(
    (response) =>
      response.url().endsWith(`/saml/${connectionId}/acs`) &&
      response.request().method() === "POST",
  );

  await page.locator("#kc-login").click();

  expect((await acsResponse).status()).toBe(302);
  await expect(page.locator("#workspace-title")).toHaveText(/LedgerLoop Workspace/);
});
