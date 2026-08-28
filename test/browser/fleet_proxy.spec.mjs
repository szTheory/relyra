import { expect, test } from "@playwright/test";

const expectedOrigin =
  process.env.EXPECTED_PUBLIC_ORIGIN || "http://localhost:4000";

test("setup LiveView stays connected and exposes usable public URLs", async ({
  page,
}) => {
  const consoleErrors = [];
  const pageErrors = [];
  const liveSockets = [];

  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });
  page.on("pageerror", (error) => pageErrors.push(error.message));
  page.on("websocket", (socket) => {
    if (new URL(socket.url()).pathname === "/live/websocket") {
      liveSockets.push(socket.url());
    }
  });

  await page.setViewportSize({ width: 360, height: 720 });
  await page.goto("/setup/sso");

  await expect(page.getByRole("heading", { name: "SSO Setup" })).toBeVisible();
  await expect(
    page.getByRole("heading", { name: "SP Settings" }),
  ).toBeVisible();
  await expect.poll(() => liveSockets.length).toBeGreaterThan(0);

  const readonlyUrls = page.locator('input[type="text"][readonly]');
  await expect(readonlyUrls).toHaveCount(3);

  const endpointNames = ["metadata", "login", "acs"];
  const connectionIds = [];

  for (const [index, endpointName] of endpointNames.entries()) {
    const value = await readonlyUrls.nth(index).inputValue();
    const url = new URL(value);
    const pathMatch = url.pathname.match(
      new RegExp(`^/saml/([^/]+)/${endpointName}$`),
    );

    expect(url.origin).toBe(new URL(expectedOrigin).origin);
    expect(pathMatch).not.toBeNull();
    connectionIds.push(pathMatch[1]);
  }

  expect(new Set(connectionIds).size).toBe(1);

  for (const input of await readonlyUrls.all()) {
    const usability = await input.evaluate((element) => {
      element.focus();
      element.setSelectionRange(0, element.value.length);
      element.scrollLeft = element.scrollWidth;

      return {
        readonly: element.readOnly,
        selectedAll:
          element.selectionStart === 0 &&
          element.selectionEnd === element.value.length,
        horizontallyAccessible:
          element.scrollWidth <= element.clientWidth || element.scrollLeft > 0,
      };
    });

    expect(usability).toEqual({
      readonly: true,
      selectedAll: true,
      horizontallyAccessible: true,
    });
  }

  await page.getByRole("link", { name: "IdP Metadata" }).click();
  await expect(
    page.getByRole("heading", { name: "IdP Metadata" }),
  ).toBeVisible();
  await expect(
    page.getByPlaceholder("Paste your IdP metadata XML here..."),
  ).toBeVisible();

  expect(pageErrors).toEqual([]);
  expect(
    consoleErrors.filter((message) =>
      /origin|websocket|liveview|failed to connect/i.test(message),
    ),
  ).toEqual([]);
});
