import { test, expect } from '@playwright/test';

test('web flow', async ({ page }) => {
  await page.goto('/');

  // Wait for the player controls to be ready before interacting — without
  // this, clicks fire before Flutter has rendered the controls and the
  // overflow menu never opens. (Same pattern used in web_datasource_swap.spec.ts)
  const playPause = page.locator('[aria-label^="better_player_material_controls_play_pause_button"]');
  await expect(playPause).toBeVisible({ timeout: 15000 });

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
  await expect(settings).toBeVisible({ timeout: 5000 });
  await settings.click({ force: true });
  await page.waitForTimeout(2000);
  const speedMenu = page.locator('[aria-label^="better_player_overflow_menu_playback_speed"]');
  await expect(speedMenu).toBeVisible();
  await speedMenu.click({ force: true });
  
  const speed2x = page.locator('[aria-label^="better_player_overflow_menu_speed_2"]');
  await expect(speed2x).toBeVisible();
  await speed2x.click({ force: true });

  // Quality (Resolution)
  await settings.click({ force: true });
  await page.waitForTimeout(2000);
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
