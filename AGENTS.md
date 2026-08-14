# Better Player AI Rules

## Development Workflow
- **Commit/Push Policy**: NEVER commit or push changes automatically. ALWAYS wait for explicit user approval before performing any Git commit or push operations.
- **Git Hygiene**:
  - ALWAYS `git fetch origin master` and `git rebase origin/master` before starting any new task to ensure you are working on the latest code.
  - Ensure your branch history is clean and only contains commits relevant to the current task.
- **Post-Implementation Steps**: If you have changed any Dart code, ALWAYS run the following commands in BOTH the root directory and the `example` directory after completion of a plan or task:
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
- **Proactive Refactoring**: This is a legacy plugin that requires significant effort to align its architecture with modern best practices (e.g., modularization, separation of concerns). Be proactive when refactoring; don't just fix the immediate issue if you see an opportunity to improve the underlying structure and ensure it follows current Android, iOS, and Flutter standards.

## Changelog Guidelines
- **Labels**: Mark critical or API-breaking changes with the `[BREAKING_CHANGE]` label at the start of the line.
- **Sections**: Use the following verbs to start entries:
  - `Added`: for new features.
  - `Updated`: for changes in existing functionality or dependencies.
  - `Fixed`: for bug fixes.
- **Consolidation**: For repetitive or similar work (e.g., updating multiple links in examples, fixing multiple small UI issues), consolidate into a single concise entry in `CHANGELOG.md` rather than listing every minor change. Avoid adding new entries for every iteration of a fix.
- **Attribution**: If the work was done by a contributor, append `(by @username)` or `(by Name)` to the end of the entry.

## Version Update Workflow
- **Explicit Instruction Only**: NEVER invent, guess, or bump versions (e.g., in `pubspec.yaml`, `podspec`, or `CHANGELOG.md`) without an explicit instruction from the user. All new entries in `CHANGELOG.md` should be placed under a `## Unreleased` header by default.
- When preparing a new release (ONLY when explicitly asked), ALWAYS:
  1. Update the `version` in `pubspec.yaml`.
  2. Update `s.version` in `ios/better_player.podspec` to match.
  3. Update `docs/install.md` with the new version snippet and any relevant Android/iOS requirement changes.
  4. Update `environment` SDK constraints in `example/pubspec.yaml` if they need to match the new library requirements.
  5. Add a descriptive entry in `CHANGELOG.md`, marking `[BREAKING_CHANGE]` where applicable.
  6. Run `flutter pub get` in both the root directory and the `example` directory to ensure `pubspec.lock` files are updated.
  7. Run `dart format .` and `flutter analyze .` to verify project health.

## Releasing the Plugin
- Before final publishing, ALWAYS:
  1. Ensure you are on the `master` branch and have pulled the latest changes from `origin/master`.
  2. Verify that the version has been correctly bumped in all required locations (see Version Update Workflow).
  3. Ensure a Git tag corresponding to the new version has been created and pushed (e.g., `git tag 0.4.0` and `git push origin 0.4.0`). DO NOT use the `v` prefix for tags.
  4. Perform the final release by calling `flutter pub publish`.
