import { test, expect } from '@playwright/test';

test('web error flow', async ({ page }) => {
  await page.goto('/');

  // Wait for initial player controls to render before triggering error state
  const playPause = page.locator('[aria-label^="better_player_material_controls_play_pause_button"]');
  await expect(playPause).toBeVisible({ timeout: 15000 });

  const errorButton = page.locator('[aria-label^="better_player_e2e_setup_error"]');
  await expect(errorButton).toBeVisible({ timeout: 10000 });

  // Check for either the external error text or the player's internal error widget
  const errorContainer = page.locator(
    '[aria-label^="better_player_e2e_error_text"], [flt-semantics-identifier="better_player_e2e_error_text"], [aria-label^="better_player_web_error_widget"], [flt-semantics-identifier="better_player_web_error_widget"]'
  );

  await expect(async () => {
    if (await errorContainer.first().isVisible()) return;
    await errorButton.click({ force: true });
    await expect(errorContainer.first()).toBeVisible({ timeout: 5000 });
  }).toPass({ timeout: 30000, intervals: [1000] });
});
