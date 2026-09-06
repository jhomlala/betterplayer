import { test, expect } from '@playwright/test';

test('web datasource swap flow', async ({ page }) => {
  await page.goto('/');
  
  // MP4
  const mp4Button = page.locator('[aria-label^="better_player_e2e_setup_mp4"]');
  await mp4Button.click({ force: true });

  // Swap to HLS
  const hlsButton = page.locator('[aria-label^="better_player_e2e_setup_hls"]');
  await hlsButton.click({ force: true });
  await page.waitForTimeout(2000);

  // Play to verify
  const playPause = page.locator('[aria-label^="better_player_material_controls_play_pause_button"]');
  await expect(playPause).toBeVisible();
  await playPause.click({ force: true });
});
