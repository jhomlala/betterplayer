import { test, expect } from '@playwright/test';

test('web feed render flow', async ({ page }) => {
  test.setTimeout(120_000);

  await page.goto('/');

  // Wait for initial player controls and Feed Render navigation button
  const feedButton = page
    .locator(
      '[aria-label^="better_player_e2e_navigate_feed_render"], [flt-semantics-identifier="better_player_e2e_navigate_feed_render"]',
    )
    .first();
  await expect(feedButton).toBeVisible({ timeout: 15000 });

  // Navigate to Feed Render page
  await expect(async () => {
    const statusTarget = page
      .locator(
        '[flt-semantics-identifier^="better_player_e2e_feed_render_status_"], [aria-label^="better_player_e2e_feed_render_status_"], [aria-label="waiting"], [aria-label="playing_0"]',
      )
      .first();
    if (await statusTarget.isVisible()) return;

    if (await feedButton.isVisible()) {
      await feedButton.click({ force: true });
    }

    await expect(statusTarget).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 30000, intervals: [2000] });

  // Wait for item 0 to start playing
  const playing0 = page
    .locator(
      '[flt-semantics-identifier="better_player_e2e_feed_render_status_playing_0"], [aria-label="better_player_e2e_feed_render_status_playing_0"], [aria-label="playing_0"]',
    )
    .first();
  await expect(playing0).toBeVisible({ timeout: 60000 });
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'feed_render_item_0.png' });

  // Advance to pooled, preloaded second item
  const nextButton = page
    .locator(
      '[flt-semantics-identifier="better_player_e2e_feed_next_button"], [aria-label="better_player_e2e_feed_next_button"], [aria-label="Next"]',
    )
    .first();
  await expect(nextButton).toBeVisible({ timeout: 15000 });
  await nextButton.click({ force: true });

  // Wait for item 1 to start playing
  const playing1 = page
    .locator(
      '[flt-semantics-identifier="better_player_e2e_feed_render_status_playing_1"], [aria-label="better_player_e2e_feed_render_status_playing_1"], [aria-label="playing_1"]',
    )
    .first();
  await expect(playing1).toBeVisible({ timeout: 60000 });
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'feed_render_item_1.png' });
});
