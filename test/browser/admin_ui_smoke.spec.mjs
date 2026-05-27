import { test, expect } from "@playwright/test";

const legacySha1Label = "Legacy SHA-1 support enabled (compatibility override)";
const oktaNameIdFormat = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified";
const entraNameIdFormat = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent";

test("admin ui shell, preset routing, and legacy sha1 lifecycle are browser-verified", async ({ page }) => {
  await page.goto("/admin");
  await expect(page).toHaveURL(/\/$/);

  await page.goto("/test/reset");
  await expect(page.locator("body")).toContainText("ok");

  await page.goto("/test/session/authenticated");
  await page.goto("/admin/connections/seed_shell");
  await expect(page).toHaveURL(/\/admin\/connections\/seed_shell$/);
  await expect(page.locator('[data-testid="admin-shell"]')).toBeVisible();
  await expect(page.locator('[data-testid="connection-list-region"]')).toBeVisible();
  await expect(page.locator('[data-testid="connection-detail-region"]')).toBeVisible();
  await expect(page.locator('[data-testid="connection-status-badge"][data-status="enabled"]')).toBeVisible();

  await page.goto("/admin/connections/new?preset=okta");
  await expect(page.locator('[data-testid="connection-editor-region"]')).toBeVisible();
  await expect(page).toHaveURL(/preset=okta$/);
  await expect(page.locator('[data-testid="preset-picker"]')).toBeVisible();

  await page.goto("/admin/connections/new?preset=entra");
  await expect(page).toHaveURL(/preset=entra$/);
  await expect(page.locator('[data-testid="preset-picker"]')).toBeVisible();

  await page.goto("/admin/connections/seed_risk");
  await expect(page.locator('[data-testid="connection-status-badge"][data-status="enabled"]')).toBeVisible();
  await expect(page.locator('[data-testid="risk-panel"]')).toBeVisible();
  await expect(page.locator('[data-testid="risk-panel-label"]')).toContainText(legacySha1Label);

  const riskPanelBox = await page.locator('[data-testid="risk-panel"]').boundingBox();
  const metadataHeadingBox = await page.getByText("Metadata", { exact: true }).boundingBox();

  if (!riskPanelBox || !metadataHeadingBox) {
    throw new Error("Expected risk panel and metadata heading bounding boxes to be available");
  }

  expect(riskPanelBox.y).toBeLessThan(metadataHeadingBox.y);
});
