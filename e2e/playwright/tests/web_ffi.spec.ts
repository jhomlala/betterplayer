import { test, expect } from '@playwright/test';

test('web ffi flow', async ({ page }) => {
  // 16 methods × up to ~20s each needs more than the 60s default
  test.setTimeout(180_000);

  await page.goto('/');

  // Wait for initial player controls and FFI button to be rendered
  const ffiButton = page.locator('[aria-label^="better_player_e2e_navigate_ffi"]');
  await expect(ffiButton).toBeVisible({ timeout: 15000 });

  // Navigate to FFI page. Retry the click until the FFI page elements are visible.
  await expect(async () => {
    const ffiTarget = page.locator('[flt-semantics-identifier^="ffi_test_"]').first();
    if (await ffiTarget.isVisible()) return;

    if (await ffiButton.isVisible()) {
      await ffiButton.click({ force: true });
    }

    await expect(ffiTarget).toBeVisible({ timeout: 3000 });
  }).toPass({ timeout: 30000, intervals: [2000] });

  // Flutter Web Text nodes get flt-semantics-identifier (not aria-label)
  const initializedStatus = page.locator('[flt-semantics-identifier="ffi_test_initialized_status"]').first();
  await expect(initializedStatus).toBeVisible({ timeout: 60000 });
  await expect(initializedStatus).toContainText('initialized=true', { timeout: 5000 });

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
    'setAndroidMatchFrameRate',
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
    const status = page.locator(`[flt-semantics-identifier="ffi_test_status_${method}"]`).first();

    await expect(async () => {
      if (await status.innerText().then((t) => t.includes('success=true')).catch(() => false)) {
        return;
      }
      await btn.click({ force: true });
      await expect(status).toContainText('success=true', { timeout: 3000 });
    }).toPass({ timeout: 20000, intervals: [1000] });
  }
});
