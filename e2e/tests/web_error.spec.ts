import { test, expect } from '@playwright/test';

test('web error flow', async ({ page }) => {
  await page.goto('/');
  
  const errorButton = page.locator('[aria-label="better_player_e2e_setup_error"]');
  await errorButton.click();
  
  const errorText = page.locator('[aria-label="better_player_e2e_error_text"]');
  await expect(errorText).toBeVisible({ timeout: 10000 });
});
