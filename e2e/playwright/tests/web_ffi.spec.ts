import { test, expect } from '@playwright/test';

test('web ffi flow', async ({ page }) => {
  // 15 methods × up to ~22s each needs more than the 60s default
  test.setTimeout(180_000);

  await page.goto('/');

  // Wait for the FFI button to actually be in the DOM and visible before
  // attempting navigation — scrollIntoViewIfNeeded silently no-ops when
  // Flutter hasn't rendered the semantics tree yet.
  const ffiButton = page.locator('[aria-label^="better_player_e2e_navigate_ffi"]');
  await expect(ffiButton).toBeVisible({ timeout: 15000 });

  // Retry navigation until the FFI page heading is visible.
  // Use coordinate-based clicks — Flutter Web's hit testing happens at pixel
  // level, so page.mouse.click is more reliable than Playwright's synthetic
  // click on flt-semantics wrapper elements.
  await expect(async () => {
    const ffiTarget = page.locator('[flt-semantics-identifier^="ffi_test_"]').first();
    if (await ffiTarget.isVisible()) return;

    if (await ffiButton.isVisible()) {
      const box = await ffiButton.boundingBox();
      if (box) {
        await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      } else {
        await ffiButton.click({ force: true });
      }
    }

    await expect(ffiTarget).toBeVisible({ timeout: 3000 });
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

    await btn.scrollIntoViewIfNeeded();

    // Use coordinate-based click — Flutter's hit-test pipeline picks these up
    // more reliably than synthetic Playwright clicks on flt-semantics wrappers.
    const box = await btn.boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    } else {
      console.warn(`No bounding box for ${method}, falling back to force click`);
      await btn.click({ force: true });
    }

    // Short pause to let Flutter process the tap and setState before checking
    await page.waitForTimeout(300);

    // Flutter Web Text nodes use flt-semantics-identifier, not aria-label
    // Check inner text just like Maestro does (id + text separately)
    const status = page.locator(`[flt-semantics-identifier="ffi_test_status_${method}"]`).first();
    await expect(status).toContainText('success=true', { timeout: 20000 });
  }
});
