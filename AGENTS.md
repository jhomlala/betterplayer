# Better Player AI Rules

## Development Workflow
- **Commit/Push Policy**: NEVER commit or push changes automatically. ALWAYS wait for explicit user approval before performing any Git commit or push operations.
- **Git Hygiene**:
  - ALWAYS create a new branch before starting any modification (e.g., `feat/feature-name`, `fix/bug-name`).
  - ALWAYS `git fetch origin master` and `git rebase origin/master` before starting any new task to ensure you are working on the latest code.
  - Ensure your branch history is clean and only contains commits relevant to the current task.
  - Use standard branch naming conventions based on the task type:
    - `feat/` for new features.
    - `fix/` or `bugfix/` for bug fixes.
    - `docs/` for documentation updates.
    - `refactor/` for code refactoring.
    - `test/` for adding or updating tests.
    - `chore/` for maintenance tasks or dependency updates.
- **Post-Implementation Steps**: If you have changed any Dart code, ALWAYS run the following commands in the workspace root after completion of a plan or task:
  - `dart format .`
  - `flutter analyze .`
  - Ensure all packages in `packages/` are consistent.
- **Error Resolution**: If `flutter analyze` reports issues, they MUST be fixed immediately before concluding the task.
- **PR Completeness**: Before considering a task or bug fix finished, ensure the work is ready to be merged. This includes:
  - Adding a relevant entry to `CHANGELOG.md` under the `## Unreleased` header. If the header does not exist, create it at the very top of the file (following the Changelog Guidelines).
  - Ensuring all tests pass and `flutter analyze` is clean.
  - Providing clear verification steps and, for bugs, the reproduction data source.

## Code Style & Linting
- **Standard**: Follow `package:very_good_analysis`.
- **Formatting**: Adhere to standard Dart formatting.
- **Specific Rules**:
  - Prefer single quotes over double quotes.
  - Require trailing commas for multi-line arguments and collections.
  - Maintain the existing suppressions in `analysis_options.yaml` for specific project needs (e.g., `public_member_api_docs: false`).
  - **Named Parameters**: Use named parameters for all functions, methods, and constructors if:
    - They have 2 or more parameters.
    - They have only 1 parameter and that parameter is a `bool`.
  - **Widget Creation**: NEVER create widgets using helper methods (e.g., `Widget _buildSomething()`). ALWAYS create them as separate `StatelessWidget` or `StatefulWidget` classes, or define the widget tree directly within the `build` method. This ensures better performance, cleaner code, and correct lifecycle management.
  - **Logging**: ALWAYS use `BetterPlayerUtils.log` for logging instead of `print` or `debugPrint`. This ensures that logs are correctly handled by the project's logging mechanism.

## Testing
- **Async Operations**: Always `await` asynchronous calls in tests (e.g., `setupDataSource`, `play`, `pause`, `seekTo`).
- **Mocking**: Use `BetterPlayerMockController` and `MockVideoPlayerController` for unit tests.
- **Verification**: ALWAYS run tests using the following command at the workspace root or within the relevant package directory to efficiently identify failures and avoid token limit issues:
  - Use `flutter test` within a specific package directory (e.g., `cd packages/better_player; flutter test`).
  - For workspace-wide testing, use:
  ```powershell
  $names=@{}; Get-ChildItem -Path packages -Directory | ForEach-Object { cd $_.FullName; if (Test-Path test) { flutter test --machine | ForEach-Object { if ($_ -match '^{.*}$') { $_ | ConvertFrom-Json } } | ForEach-Object { if($_.type -eq "testStart"){$names[$_.test.id]=$_.test.name} elseif($_.type -eq "error"){[PSCustomObject]@{test=$names[$_.testID]; error=$_.error; package=$_.FullName}} } } }; cd ../.. | ConvertTo-Json -Compress
  ```

## Project Structure
- **Test Organization**: The `test/` directory MUST mirror the `lib/src/` directory structure.
  - Example: `lib/src/core/` -> `test/core/`
  - Helpers and mocks should be placed in `test/helpers/`.
  - Test files should be named `<original_file_name>_test.dart` or reflect the component they test.
- **Artifacts**: Never track the `.artifacts/` directory in Git. It is already added to `.gitignore`.
- **Example App**: When changing core library code, check if the `example` app needs updates or if its tests/analysis are affected.

## E2E Testing (Maestro)
- **Rules Reference**: ALWAYS follow the guidelines in [rules/maestro.md](file:///C:/Users/jhoml/betterplayer/rules/maestro.md) when writing or updating E2E tests.
- **Stability First**: Prioritize using `Semantics(identifier: ...)` in Flutter and `id` selectors in Maestro. Avoid text-based selectors or hardcoded coordinates.
- **iOS Focus**: Ensure all E2E flows are verified on the iOS Simulator, as this is the primary focus for E2E reliability.

## Architecture
- **Plugin-First Principle**: When working on new features or refactoring existing code, prioritize a **plugin-based architecture**. The goal is to keep the core library lean and extend functionality via plugins rather than purely working within the core.
- **Proactive Refactoring**: This is a legacy plugin that requires significant effort to align its architecture with modern best practices (e.g., modularization, separation of concerns). Be proactive when refactoring; don't just fix the immediate issue if you see an opportunity to improve the underlying structure and ensure it follows current Android, iOS, and Flutter standards.

## GitHub Issues (Bugs & Features)
- **Research**: Before proposing a fix or new feature, ALWAYS explore the `example/` app and `doc/` directory. They often contain usage patterns, configurations, or existing implementations that can guide the solution or serve as a baseline for a reproduction case. Leverage the entire codebase to find similar implementations before reinventing the wheel.
- **Classification**: Evaluate if a reported issue is a valid defect/request or a misunderstanding. Not all requests should be handled. Be rather negative on adding new things to the main code; instead, favor documentation and examples to show how the user can achieve their goal. Only add new features to the core player if the addition is valid, critical, and "really good." If adding a requested feature or fixing a non-critical bug risks affecting multiple components or destabilizing the library, skip it. Priority is **stability over feature perfection**. If it can be handled by explaining the behavior or pointing to an existing example in the `example/` app, do that instead of changing the code. In such cases, answer the ticket clearly and close it.
- **Surgical Refactoring**: For real bugs or complex features, be brave in refactoring legacy code to ensure a robust implementation. However, stay focused: the change should be like surgery—refactor where necessary but do not touch unrelated areas. Prioritize reusing existing infrastructure (listeners, event channels, controllers) over adding new boilerplate or architectural layers.
- **Plan Analysis**: Every implementation plan for a GitHub issue MUST include an explicit analysis of:
  - **Necessity**: Why is this change required for the project?
  - **Criticality**: What is the impact if this is not fixed or implemented?
  - **Surgical Nature**: How does this change minimize boilerplate and reuse existing code?
- **Reproduction & Verification**: ALWAYS provide a reproducible data source (e.g., a specific URL or asset) so the reviewer can check the solution. For features, provide a clear example demonstrating the new functionality.
- **Testing**: Every bug fix or new feature MUST include appropriate Dart tests. Do not add tests for the native part. When dealing with core player state changes, ensure tests verify UI reactivity (e.g., aspect ratio or layout updates when video size changes).
- **Verification**: In every PR or implementation plan, include clear steps to verify the solution.

## Changelog Guidelines
- **Content Policy**: Entries in `CHANGELOG.md` MUST ONLY be for the plugin itself (features, fixes, updates). DO NOT include DevOps, infrastructure, or CI/CD changes (e.g., workflow updates, script optimizations).
- **History Preservation**: NEVER remove historical entries from `CHANGELOG.md`. Keep the complete history intact.
- **Unreleased Section**: The `## Unreleased` header should ONLY be present when there are actual unreleased changes. If present, it MUST be at the very top of the changelog file, above all other version headers. Version headers MUST be ordered chronologically, with the most recent version at the top. If there are no unreleased changes, the `## Unreleased` header MUST NOT be present.
- **Grouping**: Always group related or repetitive changes under a single concise entry in `## Unreleased` to avoid bloating.
- **Labels**: Mark critical or API-breaking changes with the `[BREAKING_CHANGE]` label at the start of the line.
- **Sections**: Use the following verbs to start entries:
  - `Added`: for new features.
  - `Updated`: for changes in existing functionality or dependencies.
  - `Fixed`: for bug fixes.
- **Attribution**: If the work was done by a contributor, append `(by @username)` or `(by Name)` to the end of the entry.

## Release Management
- **Preparation**: When asked to "Prepare a release for version X.Y.Z", the AI must:
  1. Update `version: X.Y.Z` in `packages/better_player/pubspec.yaml`, `packages/better_player_android/pubspec.yaml`, `packages/better_player_ios/pubspec.yaml`, and `packages/better_player_platform_interface/pubspec.yaml`.
  2. Update `s.version = 'X.Y.Z'` in `packages/better_player_ios/ios/better_player_ios.podspec`.
  3. Update `better_player: ^X.Y.Z` in the installation snippet of `docs/install.md`.
  4. Rename the `## Unreleased` header to `## X.Y.Z` in `CHANGELOG.md` (omit the date). Ensure that version headers remain ordered correctly with the most recent at the top. DO NOT leave an empty `## Unreleased` section after the release.
  5. Run `flutter pub get` in the root directory.
  6. Run `dart format .` and `flutter analyze .`.
- **Internal Release (`publish_to: none`)**:
  - If any core package has `publish_to: none`, the "release" is strictly a version bump and Git tag.
  - DO NOT run `flutter pub publish` unless explicitly instructed AND `publish_to: none` is removed.
  - The AI should remind the user to create a Git tag (e.g., `git tag X.Y.Z`) after merging the release PR.
- **Public Release**:
  - Only proceed with `flutter pub publish` if:
    1. The version is correctly bumped in all locations.
    2. `CHANGELOG.md` is finalized.
    3. The user provides explicit approval for publishing.
    4. `publish_to: none` is not present in the target package.


## FFI Generation

Swiftgen and jnigen bindings are automatically generated on CI/CD (or triggered manually via GitHub Actions workflow_dispatch). Do not attempt to run swiftgen or jnigen locally if your environment doesn't support it (e.g. Windows for iOS). Instead, make the code changes, commit them, and ask the user to trigger the generation on CI/CD.
