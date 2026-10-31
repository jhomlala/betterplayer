import { test, expect } from '@playwright/test';

test('web video completion and replay flow', async ({ page }) => {
  await page.goto('/');

  const playPause = page.locator('[aria-label^="better_player_material_controls_play_pause_button"]');
  await expect(playPause).toBeVisible({ timeout: 15000 });

  // Seek near end to trigger EOF and natural finished event
  const seekToEndButton = page.locator(
    '[aria-label^="better_player_e2e_seek_to_end_button"], [flt-semantics-identifier="better_player_e2e_seek_to_end_button"]'
  );
  await expect(seekToEndButton).toBeVisible({ timeout: 10000 });
  await seekToEndButton.click({ force: true });

  // Wait for finished status
  const finishedStatus = page.locator(
    '[aria-label^="better_player_e2e_finished_status"], [flt-semantics-identifier="better_player_e2e_finished_status"]'
  );
  await expect(finishedStatus.first()).toBeVisible({ timeout: 30000 });

  // Tap replay button in controls
  await expect(playPause).toBeVisible({ timeout: 10000 });
  await playPause.click({ force: true });

  // Wait for replayed status
  const replayedStatus = page.locator(
    '[aria-label^="better_player_e2e_replayed_status"], [flt-semantics-identifier="better_player_e2e_replayed_status"]'
  );
  await expect(replayedStatus.first()).toBeVisible({ timeout: 20000 });
});
