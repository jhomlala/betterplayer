import { test, expect } from '@playwright/test';

test('web ffi flow', async ({ page }) => {
  await page.goto('/');
  
  const ffiButton = page.locator('[aria-label^="better_player_e2e_navigate_ffi"]');
  await ffiButton.scrollIntoViewIfNeeded();
  await ffiButton.click({ force: true });
  
  const initializedStatus = page.locator('[aria-label^="ffi_test_initialized_status"]');
  await expect(initializedStatus).toHaveText('initialized=true', { timeout: 60000 });

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
    const btn = page.locator(`[aria-label^="ffi_test_button_${method}"]`);
    await btn.scrollIntoViewIfNeeded();
    await btn.click({ force: true });
    
    const status = page.locator(`[aria-label^="ffi_test_status_${method}"]`);
    await expect(status).toHaveText('success=true', { timeout: 5000 });
  }
});
