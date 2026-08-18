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
- **Post-Implementation Steps**: If you have changed any Dart code, ALWAYS run the following commands in BOTH the root directory and the `example` directory after completion of a plan or task:
  - `dart format .`
  - `flutter analyze .`
- **Error Resolution**: If `flutter analyze` reports issues, they MUST be fixed immediately before concluding the task.
- **PR Completeness**: Before considering a task or bug fix finished, ensure the work is ready to be merged. This includes:
  - Adding a relevant entry to `CHANGELOG.md` under the `## Unreleased` header (following the Changelog Guidelines).
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

## GitHub Issues (Bugs & Features)
- **Research**: Before proposing a fix or new feature, ALWAYS explore the `example/` app and `doc/` directory. They often contain usage patterns, configurations, or existing implementations that can guide the solution or serve as a baseline for a reproduction case. Leverage the entire codebase to find similar implementations before reinventing the wheel.
- **Classification**: Evaluate if a reported issue is a valid defect/request or a misunderstanding. Not all requests should be handled. Be rather negative on adding new things to the main code; instead, favor documentation and examples to show how the user can achieve their goal. Only add new features to the core player if the addition is valid, critical, and "really good." If adding a requested feature or fixing a non-critical bug risks affecting multiple components or destabilizing the library, skip it. Priority is **stability over feature perfection**. If it can be handled by explaining the behavior or pointing to an existing example in the `example/` app, do that instead of changing the code. In such cases, answer the ticket clearly and close it.
- **Surgical Refactoring**: For real bugs or complex features, be brave in refactoring legacy code to ensure a robust implementation. However, stay focused: the change should be like surgery—refactor where necessary but do not touch unrelated areas. Prioritize reusing existing infrastructure (listeners, event channels, controllers) over adding new boilerplate or architectural layers.
- **Plan Analysis**: Every implementation plan for a GitHub issue MUST include an explicit analysis of:
  - **Necessity**: Why is this change required for the project?
  - **Criticality**: What is the impact if this is not fixed or implemented?
  - **Surgical Nature**: How does this change minimize boilerplate and reuse existing code?
- **Reproduction & Verification**: ALWAYS provide a reproducible data source (e.g., a specific URL or asset) so the reviewer can check the solution. For features, provide a clear example demonstrating the new functionality.
- **Testing**: Every bug fix or new feature MUST include appropriate Dart tests. Do not add tests for the native part.
- **Verification**: In every PR or implementation plan, include clear steps to verify the solution.

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
  3. Update `doc/install.md` with the new version snippet and any relevant Android/iOS requirement changes.
  4. Update `environment` SDK constraints in `example/pubspec.yaml` if they need to match the new library requirements.
  5. Add a descriptive entry in `CHANGELOG.md`, marking `[BREAKING_CHANGE]` where applicable.
  6. Run `flutter pub get` in both the root directory and the `example` directory to ensure `pubspec.lock` files are updated.
  7. Run `dart format .` and `flutter analyze .` to verify project health.

## Releasing the Plugin
- Before final publishing, ALWAYS:
  1. Ensure you are on the `master` branch and have pulled the latest changes from `origin/master`.
  2. Verify that the version has been correctly bumped in all required locations (see Version Update Workflow).
  3. NEVER change `CHANGELOG.md` during the release process itself. It must be finalized beforehand.
  4. Ensure a Git tag corresponding to the new version has been created and pushed (e.g., `git tag 0.4.1` and `git push origin 0.4.1`). DO NOT use the `v` prefix for tags.
  5. Perform the final release by calling `flutter pub publish`.
