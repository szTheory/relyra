import { test, expect } from '@playwright/test';

test('Keycloak login journey', async ({ page }) => {
  // First, automate the Setup UI
  await page.goto('/setup');
  
  await page.click('text=IdP Metadata');
  await page.fill('textarea[name="metadata"]', 'dummy metadata');
  await page.click('button:has-text("Save Metadata")');
  await expect(page.locator('text=Metadata saved successfully!')).toBeVisible();
  
  await page.click('text=Mapping Preview');
  await page.click('text=Next');
  
  await page.click('text=Test & Enable');
  
  // Navigate to root to login
  await page.goto('/');
  
  // Click SAML SSO login. We assume there's a button.
  // Wait for page to load
  await page.waitForLoadState('networkidle');
  
  // The actual text might be 'Login with SAML' or 'SAML SSO'
  const samlLoginButton = page.locator('text=Login with SAML').or(page.locator('text=SAML SSO')).or(page.locator('text=SSO Login'));
  if (await samlLoginButton.count() > 0) {
    await samlLoginButton.first().click();
  } else {
    // Try visiting the auth URL directly if button is missing
    await page.goto('/auth/saml/login');
  }

  // Keycloak login
  await page.fill('input[name="username"], #username', 'admin');
  await page.fill('input[name="password"], #password', 'admin');
  await page.click('input[type="submit"], button[type="submit"], #kc-login');

  // Verify successful redirect back to the app
  await expect(page).not.toHaveURL(/keycloak/);
});
