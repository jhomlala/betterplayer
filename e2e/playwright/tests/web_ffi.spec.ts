import { test, expect } from '@playwright/test';

test('web ffi flow', async ({ page }) => {
  // 15 methods × up to ~22s each needs more than the 60s default
  test.setTimeout(180_000);

  await page.goto('/');

  // Navigate to FFI page. Retry the click until the FFI page heading is visible
  // — a plain force-click sometimes doesn't trigger Flutter navigation.
  const ffiButton = page.locator('[aria-label^="better_player_e2e_navigate_ffi"]');
  await ffiButton.scrollIntoViewIfNeeded();
  await expect(async () => {
    await ffiButton.click({ force: true });
    await expect(page.getByRole('heading', { name: 'FFI Method Test' })).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 30000, intervals: [2000] });

  // Flutter Web Text nodes get flt-semantics-identifier (not aria-label)
  const initializedStatus = page.locator('[flt-semantics-identifier="ffi_test_initialized_status"]').first();
  await expect(initializedStatus).toBeVisible({ timeout: 60000 });
  await expect(initializedStatus).toContainText('initialized=true', { timeout: 5000 });

  // Scroll down so all buttons are in viewport and the engine has time to settle
  await page.mouse.wheel(0, 500);
  // Give the player time to buffer after initialization before seeking
  await page.waitForTimeout(5000);

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
    'isPictureInPictureSupported',
  ];

  for (const method of methods) {
    console.log(`Testing FFI method: ${method}`);
    const btn = page.locator(`[flt-semantics-identifier="ffi_test_button_${method}"]`).first();

    await btn.scrollIntoViewIfNeeded();

    // Click — fall back to force if the Flutter semantics layer intercepts
    try {
      await btn.click({ timeout: 5000 });
    } catch {
      console.warn(`Click failed for ${method}, retrying with force: true`);
      await btn.click({ force: true });
    }

    // Flutter Web Text nodes use flt-semantics-identifier, not aria-label
    // Check inner text just like Maestro does (id + text separately)
    const status = page.locator(`[flt-semantics-identifier="ffi_test_status_${method}"]`).first();
    await expect(status).toContainText('success=true', { timeout: 20000 });
  }
});
