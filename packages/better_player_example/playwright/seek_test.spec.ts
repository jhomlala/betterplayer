import { test, expect } from '@playwright/test';

test('Rapid seeking updates video position without crashing', async ({ page }) => {
  // Assuming the example app is served on localhost:8080
  await page.goto('http://localhost:8080');

  // Wait for the Flutter app to load and elements to be available
  await page.waitForTimeout(2000);

  // Click the "Seek Test" navigation button
  // We use the semantics identifier/label exposed in Flutter web
  await page.click('[aria-label="better_player_e2e_navigate_seek"]');

  // Wait for the video to start
  await page.waitForTimeout(4000);

  // Assert position text exists
  const positionText = page.locator('[aria-label="better_player_e2e_position"]');
  await expect(positionText).toBeVisible();

  // Tap 00:03
  await page.click('[aria-label="better_player_e2e_seek_3s"]');
  await page.waitForTimeout(2000);
  
  // Verify position text changed to 3s (or slightly more due to playback)
  await expect(positionText).toHaveText(/Position: [3-5]s/);

  // Tap 00:10
  await page.click('[aria-label="better_player_e2e_seek_10s"]');
  await page.waitForTimeout(2000);
  await expect(positionText).toHaveText(/Position: 1[0-2]s/);

  // Tap 00:30
  await page.click('[aria-label="better_player_e2e_seek_30s"]');
  await page.waitForTimeout(2000);
  await expect(positionText).toHaveText(/Position: 3[0-2]s/);
});
