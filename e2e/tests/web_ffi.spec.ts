import { test, expect } from '@playwright/test';

test('web ffi flow', async ({ page }) => {
  await page.goto('/');
  
  const ffiButton = page.locator('[aria-label^="better_player_e2e_navigate_ffi"]');
  await ffiButton.scrollIntoViewIfNeeded();
  await ffiButton.click({ force: true });
  await page.waitForTimeout(5000); // Increased wait for FFI page to load and initialize

  // Use a more relaxed locator that matches text content or aria-label
  const initializedStatus = page.locator('[aria-label*="ffi_test_initialized_status"], flt-semantics:has-text("initialized=true")').first();
  await expect(initializedStatus).toBeVisible({ timeout: 60000 });
  await expect(initializedStatus).toContainText('initialized=true', { timeout: 10000 });

  // Explicitly scroll down to make sure buttons are in view for Flutter Web
  await page.mouse.wheel(0, 500);
  await page.waitForTimeout(2000);

  await page.waitForTimeout(5000); // Wait extra time for engine to be ready for commands

  const methods = [
    'play',
    'pause',
    'seekTo',
    'setVolume',
    'setSpeed',
    'setTrackParameters',
    'setAudioTrack',
    'setMixWithOthers',
    'setLooping',
    'getPosition',
    'getAbsolutePosition',
    'playerValue',
    'duration',
    'isInitialized',
    'isPictureInPictureSupported'
  ];

  for (const method of methods) {
    console.log(`Testing FFI method: ${method}`);
    const btn = page.locator(`[aria-label*="ffi_test_button_${method}"]`).first();

    // Explicitly scroll the element into view and wait a bit
    await btn.scrollIntoViewIfNeeded();
    await page.waitForTimeout(1000);

    // Attempt click without force first to check actionability, fallback to force if needed
    try {
      await btn.click({ timeout: 5000 });
    } catch (e) {
      console.warn(`Click failed for ${method}, retrying with force: true`);
      await btn.click({ force: true });
    }
    
    // Wait for the status to change from "not started"
    const status = page.locator(`[aria-label*="ffi_test_status_${method}"]`).first();
    await expect(status).not.toContainText('not started', { timeout: 20000 });
    await expect(status).toContainText('success=true', { timeout: 10000 });

    // Small delay between tests
    await page.waitForTimeout(1000);
  }
});
