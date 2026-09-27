import { test, expect } from '@playwright/test';

test('web datasource swap flow', async ({ page }) => {
  await page.goto('/');

  // Wait for initial MP4 to load to avoid interrupting it and causing Shaka Error 7000
  const playPause = page.locator('[aria-label^="better_player_material_controls_play_pause_button"]');
  await expect(playPause).toBeVisible({ timeout: 10000 });

  // MP4
  const mp4Button = page.locator('[aria-label^="better_player_e2e_setup_mp4"]');
  await mp4Button.click({ force: true });
  await page.waitForTimeout(3000);

  // Swap to HLS
  const hlsButton = page.locator('[aria-label^="better_player_e2e_setup_hls"]');
  await hlsButton.click({ force: true });
  await page.waitForTimeout(5000);

  // Play to verify
  await expect(playPause).toBeVisible({ timeout: 10000 });
  await playPause.click({ force: true });

  // Swap back to MP4 and verify visibility callback (#939)
  await mp4Button.click({ force: true });
  await expect(playPause).toBeVisible({ timeout: 10000 });

  const visibilityCycleButton = page.locator('[aria-label^="better_player_e2e_visibility_cycle_button"]');
  const visibilityStatus = page.locator(
    '[aria-label^="better_player_e2e_visibility_callback_status"], [flt-semantics-identifier="better_player_e2e_visibility_callback_status"]'
  );
  await expect(async () => {
    if (await visibilityStatus.first().isVisible()) return;
    await visibilityCycleButton.click({ force: true });
    await expect(visibilityStatus.first()).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 10000, intervals: [1000] });

  // Verify BetterPlayerPlaylist transition (#1037)
  const playlistButton = page.locator('[aria-label^="better_player_e2e_playlist_button"]');
  const playlistStatus = page.locator(
    '[aria-label^="better_player_e2e_playlist_status"], [flt-semantics-identifier="better_player_e2e_playlist_status"]'
  );
  await expect(async () => {
    if (await playlistStatus.first().isVisible()) return;
    await playlistButton.click({ force: true });
    await expect(playlistStatus.first()).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 15000, intervals: [1000] });
});
