import { test, expect } from '@playwright/test';

test('web video accurate seek flow', async ({ page }) => {
  await page.goto('/');

  // Wait for initial MP4 video to be initialized
  const mp4Initialized = page.locator(
    '[aria-label^="better_player_e2e_mp4_initialized"], [flt-semantics-identifier="better_player_e2e_mp4_initialized"]'
  );
  await expect(mp4Initialized.first()).toBeVisible({ timeout: 30000 });

  // Navigate to Seek E2E page
  const navigateSeekButton = page.locator(
    '[aria-label^="better_player_e2e_navigate_seek"], [flt-semantics-identifier="better_player_e2e_navigate_seek"]'
  );
  await expect(navigateSeekButton.first()).toBeVisible({ timeout: 15000 });
  await navigateSeekButton.first().click({ force: true });

  // Wait for seek player initialization
  const seekInitialized = page.locator(
    '[aria-label^="better_player_e2e_seek_initialized"], [flt-semantics-identifier="better_player_e2e_seek_initialized"]'
  );
  await expect(seekInitialized.first()).toBeVisible({ timeout: 30000 });

  // Click Seek 00:10 button
  const seek10sButton = page.locator(
    '[aria-label^="better_player_e2e_seek_10s_button"], [flt-semantics-identifier="better_player_e2e_seek_10s_button"]'
  );
  await expect(seek10sButton.first()).toBeVisible({ timeout: 15000 });
  await seek10sButton.first().click({ force: true });

  // Verify seek 10s status is visible
  const seek10sVerified = page.locator(
    '[aria-label^="better_player_e2e_seek_10s_verified"], [flt-semantics-identifier="better_player_e2e_seek_10s_verified"]'
  );
  await expect(seek10sVerified.first()).toBeVisible({ timeout: 20000 });
});
