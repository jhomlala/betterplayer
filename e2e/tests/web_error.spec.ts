import { test, expect } from '@playwright/test';

test('web error flow', async ({ page }) => {
  await page.goto('/');
  
  const errorButton = page.locator('[aria-label^="better_player_e2e_setup_error"]');
  await errorButton.click({ force: true });
  await page.waitForTimeout(2000);

  // Check for either the external error text or the player's internal error widget
  const errorContainer = page.locator('[aria-label^="better_player_e2e_error_text"], [aria-label^="better_player_web_error_widget"]');
  await expect(errorContainer.first()).toBeVisible({ timeout: 20000 });
});
