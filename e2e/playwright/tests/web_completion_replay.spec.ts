import { test, expect } from '@playwright/test';

test('web video completion and replay flow', async ({ page }) => {
  await page.goto('/');

  // Wait for initial MP4 video to be initialized
  const mp4Initialized = page.locator(
    '[aria-label^="better_player_e2e_mp4_initialized"], [flt-semantics-identifier="better_player_e2e_mp4_initialized"]'
  );
  await expect(mp4Initialized.first()).toBeVisible({ timeout: 30000 });

  const playPause = page.locator('[aria-label^="better_player_material_controls_play_pause_button"]');
  await expect(playPause).toBeVisible({ timeout: 15000 });

  // Seek near end to trigger EOF and natural finished event
  const seekToEndButton = page.locator(
    '[aria-label^="better_player_e2e_seek_to_end_button"], [flt-semantics-identifier="better_player_e2e_seek_to_end_button"]'
  );
  await expect(seekToEndButton).toBeVisible({ timeout: 10000 });

  // Wait for finished status
  const finishedStatus = page.locator(
    '[aria-label^="better_player_e2e_finished_status"], [flt-semantics-identifier="better_player_e2e_finished_status"]'
  );
  await expect(async () => {
    if (await finishedStatus.first().isVisible()) return;
    await seekToEndButton.click({ force: true });
    await expect(finishedStatus.first()).toBeVisible({ timeout: 4000 });
  }).toPass({ timeout: 35000, intervals: [2000] });

  // Tap replay button in controls
  const replayedStatus = page.locator(
    '[aria-label^="better_player_e2e_replayed_status"], [flt-semantics-identifier="better_player_e2e_replayed_status"]'
  );
  await expect(async () => {
    if (await replayedStatus.first().isVisible()) return;
    await playPause.click({ force: true });
    await expect(replayedStatus.first()).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 20000, intervals: [1000] });
});
