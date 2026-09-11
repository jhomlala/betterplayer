# GitHub Rules & Utilities

## Fetching PR Comments
To fetch all comments (issue comments, inline review comments, and review summaries) from a Pull Request, use the Dart script located at scripts/fetch_pr_comments.dart.

### Requirements
- Make sure you have a GitHub Personal Access Token exported in your environment variables:
  $env:GITHUB_TOKEN="your_token_here"

### Usage
Run the following command from the root of the project:
```powershell
dart run scripts/fetch_pr_comments.dart <PR_NUMBER> [owner/repo]
```

### Examples
- Default repository (jhomlala/betterplayer):
  dart run scripts/fetch_pr_comments.dart 1499
- Custom repository:
  dart run scripts/fetch_pr_comments.dart 1234 flutter/flutter

The script will automatically save the results chronologically in your system's temporary directory as `pr_<PR_NUMBER>_comments.json` to avoid cluttering the repository with tracked files.

## Fetching Issue Data
To fetch the full details and comments of a GitHub Issue, use the Dart script located at `scripts/fetch_issue_data.dart`.

### Requirements
- Make sure you have a GitHub Personal Access Token exported in your environment variables:
  `$env:GITHUB_TOKEN="your_token_here"`

### Usage
Run the following command from the root of the project:
```powershell
dart run scripts/fetch_issue_data.dart <ISSUE_URL_OR_NUMBER> [owner/repo]
```

### Examples
- Using a full URL:
  `dart run scripts/fetch_issue_data.dart https://github.com/jhomlala/betterplayer/issues/1500`
- Using a number (defaults to jhomlala/betterplayer):
  `dart run scripts/fetch_issue_data.dart 1500`
- Using a number and custom repo:
  `dart run scripts/fetch_issue_data.dart 123 flutter/flutter`

The script will save the issue details and comments in your system's temporary directory as `issue_<ISSUE_NUMBER>_data.json`.

## Publishing a GitHub Release

To automate creating a GitHub release via the REST API (after pushing your tag), you can use PowerShell. If your current session hasn't picked up the latest `$env:GITHUB_TOKEN`, you can fetch it directly from the User environment variables.

### Usage
Run the following commands from the root of the project. Make sure your combined release notes are saved in a file (e.g., `release_notes.md`) and replace `VERSION_HERE` with your actual tag (e.g., `1.8.1`).

```powershell
$env:GITHUB_TOKEN = [Environment]::GetEnvironmentVariable("GITHUB_TOKEN", "User")
$bodyRaw = [string](Get-Content release_notes.md -Raw)
$bodyJson = @{
    tag_name = "VERSION_HERE"
    name = "VERSION_HERE"
    body = $bodyRaw
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "https://api.github.com/repos/jhomlala/betterplayer/releases" -Method Post -Headers @{ "Authorization" = "Bearer $($env:GITHUB_TOKEN)"; "Accept" = "application/vnd.github.v3+json" } -Body $bodyJson -ContentType "application/json"
```

