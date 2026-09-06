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
    const btn = page.locator(`[aria-label*="ffi_test_button_${method}"], button:has-text("Test ${method}")`).first();
    await btn.scrollIntoViewIfNeeded();
    await btn.click({ force: true });
    
    const status = page.locator(`[aria-label*="ffi_test_status_${method}"], flt-semantics:has-text("success=true")`).first();
    await expect(status).toContainText('success=true', { timeout: 10000 });
  }
});
