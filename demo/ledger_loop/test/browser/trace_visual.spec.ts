import { expect, test } from "@playwright/test";

const enabledConnectionId = "01H0B4Y1A2B3C4D5E6F7G8H9J0";
const supportConnectionId = "01H0B4Y1A2B3C4D5E6F7G8H9J3";

const adminUsername = process.env.DEMO_ADMIN_USERNAME;
const adminPassword = process.env.DEMO_ADMIN_PASSWORD;

test("tampered FakeIdP rejection remains recoverable and its trace evidence stays operable", async ({
  page,
}) => {
  await page.goto("/login/test");
  await page
    .getByRole("link", { name: "Simulate Login via FakeIdP" })
    .click();
  await page.locator("#action-failure").check();

  const acsResponse = page.waitForResponse(
    (response) =>
      new URL(response.url()).pathname ===
        `/saml/${enabledConnectionId}/acs` &&
      response.request().method() === "POST",
  );

  await page.getByRole("button", { name: "Submit SAML Response" }).click();

  expect((await acsResponse).status()).toBe(400);
  await expect(page.locator("body")).toContainText("digest_mismatch");
  await expect(page.locator("#workspace-title")).toHaveCount(0);

  await page.goto("/");
  await expect(page.getByText("Verified sign-in receipt")).toHaveCount(0);

  if (!adminUsername || !adminPassword) {
    throw new Error("DEMO_ADMIN_USERNAME and DEMO_ADMIN_PASSWORD are required");
  }

  const authorization = `Basic ${Buffer.from(
    `${adminUsername}:${adminPassword}`,
  ).toString("base64")}`;

  await page.setExtraHTTPHeaders({ authorization });
  await page.goto("/login/admin");
  await expect(page).toHaveURL(/\/relyra\/admin$/);
  await page.goto(`/relyra/admin/connections/${enabledConnectionId}/trace`);

  const newestFailedTrace = page
    .locator('[data-testid^="login-trace-row-"]')
    .filter({ hasText: "failed" })
    .first();
  const failedSummary = newestFailedTrace.locator("summary");

  await expect(newestFailedTrace).toContainText("digest_mismatch");
  await failedSummary.focus();
  await page.keyboard.press("Enter");
  await expect(newestFailedTrace).not.toHaveAttribute("open", "");
  await page.keyboard.press("Enter");
  await expect(newestFailedTrace).toHaveAttribute("open", "");

  await page.getByRole("link", { name: "Back to connection" }).click();
  await expect(page).toHaveURL(
    new RegExp(`/relyra/admin/connections/${enabledConnectionId}$`),
  );

  await page.setViewportSize({ width: 360, height: 800 });
  await page.goto(`/relyra/admin/connections/${enabledConnectionId}/trace`);

  const narrowFailedTrace = page
    .locator('[data-testid^="login-trace-row-"]')
    .filter({ hasText: "digest_mismatch" })
    .first();
  const evidence = narrowFailedTrace.getByRole("region", {
    name: "Login trace step evidence",
  });
  await evidence.focus();
  expect(
    await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
  ).toBe(true);
  expect(
    await evidence.evaluate(
      (region) => region.scrollWidth > region.clientWidth,
    ),
  ).toBe(true);
  await evidence.evaluate((region) => {
    region.scrollLeft = region.scrollWidth;
  });
  expect(await evidence.evaluate((region) => region.scrollLeft)).toBeGreaterThan(0);
  await expect(
    evidence.getByRole("columnheader", { name: "Duration" }),
  ).toBeInViewport();

  await page.goto("/support/scenario");
  await expect(page).toHaveURL(
    new RegExp(`/relyra/admin/connections/${supportConnectionId}/trace$`),
  );
  await expect(page.locator("#login-trace")).toContainText(
    "visual_fixture_long_failure_cause",
  );
  await expect(page.locator("#login-trace")).toContainText(
    "SAFE_LONG_KNOWN_STEP_ERROR_CODE",
  );
});
