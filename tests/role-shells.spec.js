const { test, expect } = require('@playwright/test');

test.describe('role shell smoke', () => {
  test('root loads organizer landing', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/tamil tournament/i);
    await expect(page).toHaveURL(/\/$/);
  });

  test('assistant route requires authenticated role', async ({ page }) => {
    await page.goto('/a/demo-tournament');
    await expect(page).toHaveTitle(/tamil tournament/i);
    await expect(page).toHaveURL(/\/a\/demo-tournament$/);
  });

  test('referee route requires authenticated role', async ({ page }) => {
    await page.goto('/r/demo-tournament');
    await expect(page).toHaveTitle(/tamil tournament/i);
    await expect(page).toHaveURL(/\/r\/demo-tournament$/);
  });

  test('public route shell is reachable by slug', async ({ page }) => {
    await page.goto('/p/demo-slug');
    await expect(page).toHaveTitle(/tamil tournament/i);
    await expect(page).toHaveURL(/\/p\/demo-slug$/);
  });
});
