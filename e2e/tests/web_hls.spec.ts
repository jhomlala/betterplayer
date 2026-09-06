import { test, expect } from '@playwright/test';

test('web hls flow', async ({ page }) => {
  await page.goto('/');
  
  const hlsButton = page.locator('[aria-label="better_player_e2e_setup_hls"]');
  await hlsButton.click();
  
  const videoArea = page.locator('[aria-label="better_player_material_video_area"]');
  await expect(videoArea).toBeVisible({ timeout: 15000 });

  // Play/pause
  const playPause = page.locator('[aria-label="better_player_material_controls_play_pause_button"]');
  await playPause.click();
  await page.waitForTimeout(500);
  await playPause.click();

  // Mute/unmute
  const mute = page.locator('[aria-label="better_player_material_controls_mute_button"]');
  await mute.click();
  await page.waitForTimeout(500);
  await mute.click();

  // Playback speed
  const settings = page.locator('[aria-label="better_player_material_controls_more_button"]');
  await settings.click();
  const speedMenu = page.locator('[aria-label="better_player_overflow_menu_playback_speed"]');
  await expect(speedMenu).toBeVisible();
  await speedMenu.click();
  
  const speed2x = page.locator('[aria-label="better_player_overflow_menu_speed_2.0"]');
  await expect(speed2x).toBeVisible();
  await speed2x.click();

  // Quality (Resolution)
  await settings.click();
  const qualityMenu = page.locator('[aria-label="better_player_overflow_menu_quality"]');
  await expect(qualityMenu).toBeVisible();
  await qualityMenu.click();
  
  const qualityAuto = page.locator('[aria-label="better_player_overflow_menu_quality_auto"]');
  await expect(qualityAuto).toBeVisible();
  
  // Verify at least one other quality exists
  const quality1 = page.locator('[aria-label="better_player_overflow_menu_quality_1"]');
  await expect(quality1).toBeVisible();
  
  await qualityAuto.click();

  // Seek
  const progressBar = page.locator('[aria-label="better_player_material_progress_bar"]');
  await expect(progressBar).toBeVisible();
  await progressBar.click();

  // Fullscreen
  const fullscreen = page.locator('[aria-label="better_player_material_controls_expand_button"]');
  await expect(fullscreen).toBeVisible();
  await fullscreen.click();
});
