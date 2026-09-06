import { test, expect } from '@playwright/test';

test('web flow', async ({ page }) => {
  await page.goto('/');
  
  // Wait for the video area to be visible
  
  // Sometimes it's not a button in Semantics, so we use locator by aria-label
  
  

  // Play/pause
  const playPause = page.locator('[aria-label="better_player_material_controls_play_pause_button"]');
  await playPause.click({ force: true });
  await page.waitForTimeout(500);
  await playPause.click({ force: true });

  // Mute/unmute
  const mute = page.locator('[aria-label="better_player_material_controls_mute_button"]');
  await mute.click({ force: true });
  await page.waitForTimeout(500);
  await mute.click({ force: true });

  // Playback speed
  const settings = page.locator('[aria-label="better_player_material_controls_more_button"]');
  await settings.click({ force: true });
  await page.waitForTimeout(1000);
  const speedMenu = page.locator('[aria-label^="better_player_overflow_menu_playback_speed"]');
  await expect(speedMenu).toBeVisible();
  await speedMenu.click({ force: true });
  
  const speed2x = page.locator('[aria-label^="better_player_overflow_menu_speed_2"]');
  await expect(speed2x).toBeVisible();
  await speed2x.click({ force: true });

  // Quality (Resolution)
  await settings.click({ force: true });
  await page.waitForTimeout(1000);
  const qualityMenu = page.locator('[aria-label^="better_player_overflow_menu_quality"]');
  await expect(qualityMenu).toBeVisible();
  await qualityMenu.click({ force: true });
  
  const qualityAuto = page.locator('[aria-label^="better_player_overflow_menu_quality_auto"]');
  await expect(qualityAuto).toBeVisible();
  await qualityAuto.click({ force: true });

  // Seek
  const progressBar = page.locator('[aria-label="better_player_material_progress_bar"]');
  await expect(progressBar).toBeVisible();
  await progressBar.click({ force: true });

  // Fullscreen
  const fullscreen = page.locator('[aria-label="better_player_material_controls_expand_button"]');
  await expect(fullscreen).toBeVisible();
  await fullscreen.click({ force: true });
});
