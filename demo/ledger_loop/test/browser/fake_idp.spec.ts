import { test, expect } from "@playwright/test";

// Real-browser e2e for the demo's built-in FakeIdP login flow. Complements the
// in-process ConnCase coverage (fake_idp_flow_test.exs) by driving the actual
// Chromium navigation chain — including the self-submitting form's JS auto-POST
// to the ACS — for both the valid and tampered journeys.
//
// Entry: GET /login/test renders a link to /saml/<conn>/login for the seeded
// enabled connection. Selecting "Valid Login" yields a verified assertion and a
// redirect to the workspace home; "Invalid Login (Tampered Signature)" yields a
// typed digest_mismatch rejection (HTTP 400), never a silent accept.

test("valid login round-trips through FakeIdP to an authenticated workspace", async ({
  page,
}) => {
  await page.goto("/login/test");
  await page
    .getByRole("link", { name: "Simulate Login via FakeIdP" })
    .click();

  // On the FakeIdP login form: success is the default selection.
  await expect(page.locator("#action-success")).toBeChecked();
  await page.locator("#action-success").check();
  await page.getByRole("button", { name: "Submit SAML Response" }).click();

  // The /fake_idp/sso response self-submits to the ACS, which verifies the
  // assertion and redirects to "/". Waiting on the workspace title transparently
  // waits through the whole auto-submit + redirect chain.
  await expect(page.locator("#workspace-title")).toHaveText(
    /LedgerLoop Workspace/,
  );
  await expect(page).toHaveURL(/\/$/);
});

test("tampered login is rejected with a typed digest_mismatch (no silent accept)", async ({
  page,
}) => {
  await page.goto("/login/test");
  await page
    .getByRole("link", { name: "Simulate Login via FakeIdP" })
    .click();

  await page.locator("#action-failure").check();

  // Capture the ACS POST response: the tampered signature must fail closed.
  const acsResponse = page.waitForResponse(
    (r) => r.url().includes("/acs") && r.request().method() === "POST",
  );
  await page.getByRole("button", { name: "Submit SAML Response" }).click();

  const resp = await acsResponse;
  expect(resp.status()).toBe(400);

  // The default Relyra ACS error renders "SAML Authentication Error: <msg> (<type>)".
  await expect(page.locator("body")).toContainText("SAML Authentication Error");
  await expect(page.locator("body")).toContainText("digest_mismatch");

  // And it never reached the authenticated workspace.
  await expect(page.locator("#workspace-title")).toHaveCount(0);
});
