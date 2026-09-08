import { test, expect } from '@playwright/test';

test('web hls flow', async ({ page }) => {
  await page.goto('/');
  
  // Wait for initial MP4 to load to avoid interrupting it and causing Shaka Error 7000
  const playPause = page.locator('[aria-label^="better_player_material_controls_play_pause_button"]');
  await expect(playPause).toBeVisible({ timeout: 10000 });

  const hlsButton = page.locator('[aria-label^="better_player_e2e_setup_hls"]');
  await hlsButton.click({ force: true });
  await page.waitForTimeout(5000); // Wait for HLS to initialize and Shaka to parse manifest

  // Play/pause
  await playPause.click({ force: true });
  await page.waitForTimeout(500);
  await playPause.click({ force: true });

  // Mute/unmute
  const mute = page.locator('[aria-label^="better_player_material_controls_mute_button"]');
  await mute.click({ force: true });
  await page.waitForTimeout(500);
  await mute.click({ force: true });

  // Playback speed
  const settings = page.locator('[aria-label^="better_player_material_controls_more_button"]');
  await settings.click({ force: true });
  const speedMenu = page.locator('[aria-label^="better_player_overflow_menu_playback_speed"]');
  await expect(speedMenu).toBeVisible();
  await speedMenu.click({ force: true });
  
  const speed2x = page.locator('[aria-label^="better_player_overflow_menu_speed_2"]');
  await expect(speed2x).toBeVisible();
  await speed2x.click({ force: true });

  // Quality (Resolution)
  // Close any open menu first, then open quality submenu.
  // The HLS test stream may only expose an "Auto" track — assert that at minimum.
  await page.mouse.click(10, 10);
  await settings.click({ force: true });
  const qualityMenu = page.locator('[aria-label^="better_player_overflow_menu_quality"]');
  await expect(qualityMenu).toBeVisible();
  await qualityMenu.click({ force: true });

  const qualityAuto = page.locator('[aria-label^="better_player_overflow_menu_quality_auto"]');
  await expect(qualityAuto).toBeVisible();
  await qualityAuto.click({ force: true });

  // Seek
  const progressBar = page.locator('[aria-label^="better_player_material_progress_bar"]');
  await expect(progressBar).toBeVisible();
  await progressBar.click({ force: true });

  // Fullscreen
  const fullscreen = page.locator('[aria-label^="better_player_material_controls_fullscreen_button"]');
  await expect(fullscreen).toBeVisible();
  await fullscreen.click({ force: true });
});
