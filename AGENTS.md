# Better Player AI Rules

## Development Workflow
- **Commit/Push Policy**: NEVER commit or push changes automatically. ALWAYS wait for explicit user approval before performing any Git commit or push operations.
- **Git Hygiene**:
  - ALWAYS `git fetch origin master` and `git rebase origin/master` before starting any new task to ensure you are working on the latest code.
  - Ensure your branch history is clean and only contains commits relevant to the current task.
- **Post-Implementation Steps**: If you have changed any Dart code, ALWAYS run the following commands after completion of a plan or task:
  - `dart format .`
  - `flutter analyze .`
- **Error Resolution**: If `flutter analyze` reports issues, they MUST be fixed immediately before concluding the task.

## Code Style & Linting
- **Standard**: Follow `package:very_good_analysis`.
- **Formatting**: Adhere to standard Dart formatting.
- **Specific Rules**:
  - Prefer single quotes over double quotes.
  - Require trailing commas for multi-line arguments and collections.
  - Maintain the existing suppressions in `analysis_options.yaml` for specific project needs (e.g., `public_member_api_docs: false`).

## Testing
- **Async Operations**: Always `await` asynchronous calls in tests (e.g., `setupDataSource`, `play`, `pause`, `seekTo`).
- **Mocking**: Use `BetterPlayerMockController` and `MockVideoPlayerController` for unit tests.
- **Verification**: ALWAYS run tests using the following command to efficiently identify failures and avoid token limit issues:
  ```powershell
  $names=@{}; flutter test --machine | ForEach-Object { if ($_ -match '^{.*}$') { $_ | ConvertFrom-Json } } | ForEach-Object { if($_.type -eq "testStart"){$names[$_.test.id]=$_.test.name} elseif($_.type -eq "error"){[PSCustomObject]@{test=$names[$_.testID]; error=$_.error}} } | ConvertTo-Json -Compress
  ```

## Project Structure
- **Test Organization**: The `test/` directory MUST mirror the `lib/src/` directory structure.
  - Example: `lib/src/core/` -> `test/core/`
  - Helpers and mocks should be placed in `test/helpers/`.
  - Test files should be named `<original_file_name>_test.dart` or reflect the component they test.
- **Artifacts**: Never track the `.artifacts/` directory in Git. It is already added to `.gitignore`.
- **Example App**: When changing core library code, check if the `example` app needs updates or if its tests/analysis are affected.

## Architecture
- **Plugin-First Principle**: When working on new features or refactoring existing code, prioritize a **plugin-based architecture**. The goal is to keep the core library lean and extend functionality via plugins rather than purely working within the core.

## Changelog Guidelines
- **Labels**: Mark critical or API-breaking changes with the `[BREAKING_CHANGE]` label at the start of the line.
- **Sections**: Use the following verbs to start entries:
  - `Added`: for new features.
  - `Updated`: for changes in existing functionality or dependencies.
  - `Fixed`: for bug fixes.
- **Attribution**: If the work was done by a contributor, append `(by @username)` or `(by Name)` to the end of the entry.

## Version Update Workflow
- When preparing a new release, ALWAYS:
  1. Update the `version` in `pubspec.yaml`.
  2. Update `s.version` in `ios/better_player.podspec` to match.
  3. Add a descriptive entry in `CHANGELOG.md`, marking `[BREAKING_CHANGE]` where applicable.
  4. Run `flutter pub get` to ensure `pubspec.lock` is updated.
  5. Run `dart format .` and `flutter analyze .` to verify project health.
