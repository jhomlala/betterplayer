# Better Player AI Rules

## Development Workflow
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
- **Verification**: Run `flutter test` to verify changes don't break existing functionality.

## Project Structure
- **Test Organization**: The `test/` directory MUST mirror the `lib/src/` directory structure.
  - Example: `lib/src/core/` -> `test/core/`
  - Helpers and mocks should be placed in `test/helpers/`.
  - Test files should be named `<original_file_name>_test.dart` or reflect the component they test.
- **Artifacts**: Never track the `.artifacts/` directory in Git. It is already added to `.gitignore`.
- **Example App**: When changing core library code, check if the `example` app needs updates or if its tests/analysis are affected.
