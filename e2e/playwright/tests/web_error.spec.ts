import { test, expect } from '@playwright/test';

test('web error flow', async ({ page }) => {
  await page.goto('/');

  // Wait for the button to be ready — clicking before Flutter renders no-ops
  const errorButton = page.locator('[aria-label^="better_player_e2e_setup_error"]');
  await expect(errorButton).toBeVisible({ timeout: 15000 });
  await errorButton.click({ force: true });

  // Let toBeVisible carry the wait instead of burning a hard 2s upfront.
  // On slow CI runners, 404 detection + Shaka error propagation + Flutter
  // rebuild can easily take 10–20s, so we give it 30s.
  const errorContainer = page.locator('[aria-label^="better_player_e2e_error_text"], [aria-label^="better_player_web_error_widget"]');
  await expect(errorContainer.first()).toBeVisible({ timeout: 30000 });
});
