# GitHub Rules & Utilities

## Fetching PR Comments
To fetch all comments (issue comments, inline review comments, and review summaries) from a Pull Request, use the Dart script located at scripts/fetch_pr_comments.dart.

### Requirements
- Make sure you have a GitHub Personal Access Token exported in your environment variables:
  $env:GITHUB_TOKEN="your_token_here"

### Usage
Run the following command from the root of the project:
`powershell
dart run scripts/fetch_pr_comments.dart <PR_NUMBER> [owner/repo]
`

### Examples
- Default repository (jhomlala/betterplayer):
  dart run scripts/fetch_pr_comments.dart 1499
- Custom repository:
  dart run scripts/fetch_pr_comments.dart 1234 flutter/flutter

The script will automatically save the results chronologically in your system's temporary directory as `pr_<PR_NUMBER>_comments.json` to avoid cluttering the repository with tracked files.
