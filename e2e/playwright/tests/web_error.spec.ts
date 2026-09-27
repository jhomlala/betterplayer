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

  // Recover from error by switching back to valid MP4 data source
  const mp4Button = page.locator('[aria-label^="better_player_e2e_setup_mp4"]');
  await mp4Button.click({ force: true });
  await expect(errorContainer.first()).toBeHidden({ timeout: 15000 });
  await expect(playPause).toBeVisible({ timeout: 15000 });

  // Navigate to Seek E2E Page and verify accurate seek position (#1342, #1068, #802)
  const seekNavButton = page.locator('[aria-label^="better_player_e2e_navigate_seek"]');
  const seekInitialized = page.locator(
    '[aria-label^="better_player_e2e_seek_initialized"], [flt-semantics-identifier="better_player_e2e_seek_initialized"]'
  );
  await expect(async () => {
    if (await seekInitialized.first().isVisible()) return;
    if (await seekNavButton.isVisible()) {
      await seekNavButton.click({ force: true });
    }
    await expect(seekInitialized.first()).toBeVisible({ timeout: 5000 });
  }).toPass({ timeout: 25000, intervals: [1000] });

  const seek10sButton = page.locator(
    '[aria-label^="better_player_e2e_seek_10s_button"], [flt-semantics-identifier="better_player_e2e_seek_10s_button"]'
  );
  const seek10sVerified = page.locator(
    '[aria-label^="better_player_e2e_seek_10s_verified"], [flt-semantics-identifier="better_player_e2e_seek_10s_verified"]'
  );
  await expect(async () => {
    if (await seek10sVerified.first().isVisible()) return;
    await seek10sButton.first().click({ force: true });
    await expect(seek10sVerified.first()).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 15000, intervals: [1000] });
});
