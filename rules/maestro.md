# Maestro E2E Testing Rules

This document defines the standards and workflow for End-to-End (E2E) testing using [Maestro](https://maestro.mobile.dev/) in the Better Player project.

## Foundation: Semantic Identifiers
Maestro interacts with the native accessibility tree. Standard Flutter `Key` objects are **not** visible to Maestro. To create reliable tests, use **Semantic Identifiers**.

> [!IMPORTANT]
> **STRICT SELECTOR HIERARCHY**:
> 1. **ALWAYS** use `id` (Semantic Identifier) as the primary selector.
> 2. Even for checking labels like "Quality", ensure a semantic identifier is added to the widget and use it.
> 3. Use `text` selectors **ONLY** as a last resort when a semantic identifier cannot be implemented or the text is dynamic/provided by the user (e.g., subtitles).
> 4. **NEVER** use `point` (coordinates) unless interacting with a non-widget area (like dismissing an overlay).

### 1. Implementation in Flutter (Dart)
Use the `identifier` property of the `Semantics` widget (requires Flutter 3.19+). This maps directly to `accessibilityIdentifier` on iOS and `resource-id` on Android.

**Naming Convention:** `better_player_<theme>_<component>_<element>` (e.g., `better_player_material_controls_play_pause_button`).

#### Widgets with Semantic Identifier Support:
- `BetterPlayerMaterialClickableWidget`: Uses `semanticsIdentifier`.
- Custom `Semantics` wrappers in Cupertino controls.
- Progress bars: `better_player_material_progress_bar`, `better_player_cupertino_progress_bar`.

### 2. Implementation in Maestro (YAML)
Always prefer `id` selectors over text or coordinates for stability.

```yaml
- tapOn:
    id: "better_player_material_controls_play_pause_button"
```

## iOS Specific Guidelines
- **Environment**: Ensure `idb-companion` is installed (`brew install idb-companion`).
- **Maestro Studio**: Use `maestro studio` to inspect the accessibility tree on the iOS Simulator if an element is not being found.
- **Coordinates**: Avoid using `point: "X%, Y%"` unless absolutely necessary (e.g., tapping an empty area to dismiss a menu). If used, always add a comment explaining why.

## Reliable Test Patterns
- **Assert Visibility**: Before interacting with an element, assert it is visible if it might be delayed.
  ```yaml
  - assertVisible:
      id: "better_player_material_controls_play_pause_button"
  ```
- **Handling Overlays**: To ensure controls are always available for interaction during E2E tests, it is recommended to enable `setControlsAlwaysVisible(true)` in the `BetterPlayerController` configuration. This eliminates the need for redundant taps on the video area to reveal controls.
  ```dart
  _betterPlayerController.setControlsAlwaysVisible(true);
  ```
- **Waiting**: **NEVER** use the `sleep` command to handle delays or animations. It makes tests flaky and slow. Always use `extendedWaitUntil` or `assertVisible` to wait for specific UI states. For transitions like fullscreen or orientation changes, wait for a key element in the new layout to become visible.
  ```yaml
  - extendedWaitUntil:
      visible:
        id: "better_player_cupertino_controls_play_pause_button"
      timeout: 10000
  ```
- **Progress Bar Interaction**: Use `id` for identifying the bar. For seeking, `tapOn` with `point` relative to the bar's ID is often more reliable than global points.

## Common Maestro Commands Reference
Use these commands when drafting or updating flows.

### App & Navigation
- `launchApp`: Launches the app. Use `clearState: true` for clean runs.
- `back: true`: Simulates the system back button.
- `openLink: "..."`: Opens a deep link.

### Interaction
- `tapOn: <id_or_text>`: Performs a tap. Always prefer `id`.
- `longPressOn: <id_or_text>`: Performs a long press.
- `inputText: "..."`: Types text into the focused field.
- `inputText: { text: "...", id: "..." }`: Types text into a specific field.
- `eraseText: <count>`: Erases characters.
- `pressKey: "Enter"`: Presses a software/hardware key.

### Gestures & Scrolling
- `swipe: { start: "X, Y", end: "X, Y" }`: Performs a swipe.
- `scrollUntilVisible: { element: <id_or_text>, direction: DOWN }`: Scrolls until found.

### Assertions & Flow
- `assertVisible: <id_or_text>`: Fails if not visible.
- `assertNotVisible: <id_or_text>`: Fails if visible.
- `extendedWaitUntil: { visible: <selector>, timeout: <ms> }`: Waits for visibility.
- `repeat: { times: N, commands: [...] }`: Repeats a block.
- `retry: { times: N, commands: [...] }`: Retries a block on failure.

## Development Workflow
1.  **Add Identifier**: Wrap the target widget in `Semantics(identifier: '...')` or use a supporting widget in the library code.
2.  **Update Flow**: Add the interaction to `e2e/maestro/ios/ios_flow.yaml` (or a new flow file).
3.  **Verify**: Run the test locally on an iOS Simulator:
    ```bash
    maestro test e2e/maestro/ios/ios_flow.yaml
    ```

---

## Debugging Maestro CI Artifacts (Mandatory 4-Step Protocol)

When investigating a failed Maestro run from a debug artifact bundle (`maestro-ios-debug-artifacts`), **NEVER guess from the `Element not found` error message alone or blindly edit `Semantics` wrappers.** You must complete and report these 4 checks in order before touching any code:

### Step 1: Visual Check (`<flow>/screenshots/step-XXX-*-FAILED.png`)
Open the failure screenshot first and verify what is actually rendered on screen:
- **Target widget is NOT on screen** (e.g., loading spinner, black screen, error widget, or auto-hidden controls): **STOP.** Do not touch `Semantics`. The failure is a player lifecycle, initialization, or visibility timer bug. Proceed to **Step 2**.
- **Target widget IS visible on screen**, but Maestro could not find it: The failure is an accessibility tree or coordinate bounds issue. Proceed to **Step 3**.

### Step 2: Native-to-Dart Lifecycle Check (`device-simulator.log`)
If the player is stuck on a loading spinner or not rendering controls:
1. Search `device-simulator.log` around the failure timestamp for `setDataSource`, `waiting for init event`, `onInitialized`, and error logs.
2. Verify that `VideoEventType.initialized` and a valid `duration` were emitted after the data source was set or swapped.
   - *Common pitfall:* In `BetterPlayerControlsState.isLoading()`, `if (!latestValue.isPlaying && latestValue.duration == null) return true;` keeps the loading spinner visible (and hides middle controls) if the native player fails to send `onInitialized` after a data source swap.

### Step 3: Accessibility Bounds Diff (`<flow>/commands.json`)
Inspect the `hierarchy` JSON object inside `<flow>/commands.json` at the failed step and compare it with the last passing step:
1. List the sibling elements that **did** survive in the hierarchy and note their `bounds` (`[minX, minY][maxX, maxY]`).
2. Calculate where the missing element is positioned on screen relative to the surviving elements.

### Step 4: XCTest Orientation & Screen Frame Check (`device-xctest.log`)
If a flow passes in Portrait and fails right after entering Fullscreen Landscape:
1. Check `device-xctest.log` for:
   - `Device orientation is 1`
   - `Returning cached screen size`
   - `Skipping offset adjustment: device and app frames are same size but different orientation`
2. Apply **Rule 1 (Fullscreen Landscape `minX < portraitWidth` Cutoff)** below.

---

## iOS Flutter + XCTest Pitfalls & Canonical Patterns

### Rule 1: Fullscreen Landscape `minX < portraitWidth` Cutoff
When Flutter enters fullscreen landscape via `SystemChrome.setPreferredOrientations`, Flutter rotates its canvas (e.g., `852 x 393` on iPhone 16 Pro), but the iOS Simulator hardware orientation (`XCUIDevice.shared.orientation`) remains Portrait (`1`, `393 x 852`).
- XCTest filters out any leaf accessibility node whose bounding box does not intersect the Portrait width (`minX >= 393`).
- For example, a `56px`-wide play/pause button centered at `x = 426` has `bounds = [398, 145][454, 201]`. Because `398 >= 393`, XCTest drops it completely from the accessibility hierarchy!
- **Solution:** Wrap horizontally distributed buttons in `Expanded -> Semantics(container: true, button: true, ...) -> GestureDetector(behavior: HitTestBehavior.opaque) -> Center`. This expands the semantic bounding box of the center button to `[309, 145][542, 201]` (`minX = 309 < 393`, so it survives XCTest's filter) while keeping its center point `(426, 173)` and visual size unchanged.

### Rule 2: Canonical Button `Semantics` Structure
1. **Place `Semantics` OUTSIDE `GestureDetector`**, never inside it. `GestureDetector` creates its own implicit semantics node for tap actions; nesting `Semantics(identifier: ...)` inside `GestureDetector` can cause iOS `UIAccessibility` to merge or drop the inner identifier.
2. **Always set `container: true` and `button: true`** on interactive button semantics, and wrap parent `Row`s in `Semantics(explicitChildNodes: true)`:
   ```dart
   Semantics(
     explicitChildNodes: true,
     child: Row(
       children: [
         Expanded(
           child: Semantics(
             identifier: 'better_player_cupertino_controls_play_pause_button',
             label: label,
             button: true,
             container: true,
             child: GestureDetector(
               behavior: HitTestBehavior.opaque,
               onTap: onPlayPause,
               child: Center(child: buttonIcon),
             ),
           ),
         ),
       ],
     ),
   )
   ```
3. **Keep control bar compositing simple:** Avoid stacking `BackdropFilter` + `ClipRRect` + `AnimatedSlide` + nested `AnimatedOpacity` on interactive controls, as multi-layer offscreen compositing breaks iOS `UIAccessibilityElement` hit-testing during transitions.

