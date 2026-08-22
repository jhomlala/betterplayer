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
- **Handling Overlays**: Controls often auto-hide. Use a tap on the video area to ensure controls are visible before interacting.
  ```yaml
  - tapOn:
      id: "better_player_cupertino_video_area"
  - tapOn:
      id: "better_player_cupertino_controls_play_pause_button"
  ```
- **Waiting**: Use `extendedWaitUntil` if a video takes time to load.
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
2.  **Update Flow**: Add the interaction to `maestro/ios_flow.yaml` (or a new flow file).
3.  **Verify**: Run the test locally on an iOS Simulator:
    ```bash
    maestro test maestro/ios_flow.yaml
    ```
