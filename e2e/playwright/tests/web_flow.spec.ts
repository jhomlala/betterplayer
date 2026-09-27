import { test, expect } from '@playwright/test';

test('web flow', async ({ page }) => {
  await page.goto('/');
  
  // Wait for the video area to be visible
  // Sometimes it's not a button in Semantics, so we use locator by aria-label

  // Play/pause
  const playPause = page.locator('[aria-label^="better_player_material_controls_play_pause_button"]');
  await expect(playPause).toBeVisible({ timeout: 15000 });
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
  const speedMenu = page.locator('[aria-label^="better_player_overflow_menu_playback_speed"]');
  await expect(async () => {
    if (await speedMenu.isVisible()) return;
    await settings.click({ force: true });
    await expect(speedMenu).toBeVisible({ timeout: 2000 });
  }).toPass({ timeout: 10000, intervals: [1000] });
  await speedMenu.click({ force: true });
  
  const speed2x = page.locator('[aria-label^="better_player_overflow_menu_speed_2"]');
  await expect(speed2x).toBeVisible();
  await speed2x.click({ force: true });
  await page.waitForTimeout(400);

  // Quality (Resolution)
  const qualityMenu = page.locator('[aria-label^="better_player_overflow_menu_quality"]');
  await expect(async () => {
    if (await qualityMenu.isVisible()) return;
    await settings.click({ force: true });
    await expect(qualityMenu).toBeVisible({ timeout: 2000 });
  }).toPass({ timeout: 10000, intervals: [1000] });
  await qualityMenu.click({ force: true });
  
  const qualityAuto = page.locator('[aria-label^="better_player_overflow_menu_quality_auto"]');
  await expect(qualityAuto).toBeVisible();
  await qualityAuto.click({ force: true });
  await page.waitForTimeout(400);

  // Subtitles selection (Memory -> None -> Memory)
  const subtitlesMenu = page.locator('[aria-label^="better_player_overflow_menu_subtitles"]');
  await expect(async () => {
    if (await subtitlesMenu.isVisible()) return;
    await settings.click({ force: true });
    await expect(subtitlesMenu).toBeVisible({ timeout: 2000 });
  }).toPass({ timeout: 10000, intervals: [1000] });
  await subtitlesMenu.click({ force: true });

  const subtitlesNone = page.locator('[aria-label^="better_player_overflow_menu_subtitles_none"]');
  await expect(subtitlesNone).toBeVisible();
  await subtitlesNone.click({ force: true });
  await page.waitForTimeout(400);

  // Verify all core PlayerEventType events fired (#945)
  const eventsVerified = page.locator(
    '[aria-label^="better_player_e2e_events_verified"], [flt-semantics-identifier="better_player_e2e_events_verified"]'
  );
  await expect(eventsVerified.first()).toBeVisible({ timeout: 5000 });

  // Runtime Controls Configuration Hotswap (#1000)
  const runtimeConfigButton = page.locator('[aria-label^="better_player_e2e_runtime_config_button"]');
  const runtimeConfigStatus = page.locator(
    '[aria-label^="better_player_e2e_runtime_config_status"], [flt-semantics-identifier="better_player_e2e_runtime_config_status"]'
  );
  await expect(async () => {
    if (await runtimeConfigStatus.first().isVisible()) return;
    await runtimeConfigButton.click({ force: true });
    await expect(runtimeConfigStatus.first()).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 10000, intervals: [1000] });

  // Controls Theme Hotswap (Web -> Cupertino -> Web)
  const toggleThemeButton = page.locator('[aria-label^="better_player_e2e_toggle_theme_button"]');
  const cupertinoPlayPause = page.locator(
    '[flt-semantics-identifier="better_player_cupertino_controls_play_pause_button"], [aria-label^="better_player_cupertino_controls_play_pause_button"]'
  );
  await expect(async () => {
    if (await cupertinoPlayPause.first().isVisible()) return;
    await toggleThemeButton.click({ force: true });
    await expect(cupertinoPlayPause.first()).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 10000, intervals: [1000] });

  await expect(async () => {
    if (await playPause.first().isVisible()) return;
    await toggleThemeButton.click({ force: true });
    await expect(playPause.first()).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 10000, intervals: [1000] });

  // Seek
  const progressBar = page.locator('[aria-label^="better_player_material_progress_bar"]');
  await expect(progressBar).toBeVisible();
  await progressBar.click({ force: true });

  // Fullscreen
  const fullscreen = page.locator('[aria-label^="better_player_material_controls_fullscreen_button"]');
  await expect(fullscreen).toBeVisible();
  await fullscreen.click({ force: true });
});
