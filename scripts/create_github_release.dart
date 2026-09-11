// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Packages to include in the release, in dependency order.
/// Each entry is [pubPackageName, localRelativePath].
const _packages = [
  ['better_player_platform_interface', 'packages/better_player_platform_interface'],
  ['better_player_android', 'packages/better_player_android'],
  ['better_player_ios', 'packages/better_player_ios'],
  ['better_player_web', 'packages/better_player_web'],
  ['better_player', 'packages/better_player'],
];

/// Repository in the form "owner/repo".
const _repo = 'jhomlala/betterplayer';

void main(List<String> args) async {
  // ¦¦ Token ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
  final token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    _die(
      'Error: GITHUB_TOKEN environment variable is not set.\n'
      'Run: \$env:GITHUB_TOKEN = [Environment]::GetEnvironmentVariable("GITHUB_TOKEN", "User")',
    );
  }

  final client = HttpClient();

  // ¦¦ Collect info for each package ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
  print('Checking packages against pub.dev...\n');

  final releaseEntries = <String>[];

  for (final entry in _packages) {
    final pubName = entry[0];
    final localPath = entry[1];
    
    // Read local version from pubspec.yaml
    final localVersion = _readLocalVersion(localPath);
    if (localVersion == null) {
      _die('Could not read version from $localPath/pubspec.yaml');
    }

    final pubInfo = await _fetchPubVersion(client, pubName, localVersion);

    if (pubInfo == null) {
      print('  [$pubName $localVersion] NOT found on pub.dev — skip from notes (publish first!)');
      continue;
    }

    final publishedAt = DateTime.tryParse(pubInfo['published'] as String? ?? '');
    // Consider "new" if published within the last 1 hour
    final isNew = publishedAt != null &&
        DateTime.now().toUtc().difference(publishedAt.toUtc()).inHours < 1;

    if (!isNew) {
      print('  [$pubName $localVersion] already existed on pub.dev before today — SKIPPING from release notes.');
      continue;
    }

    print('  [$pubName $localVersion] newly published — INCLUDED in release notes.');

    // Extract latest changelog entry
    final changelog = _readLatestChangelog(localPath, localVersion);
    if (changelog != null) {
      releaseEntries.add('### `$pubName`\n$changelog');
    }
  }

  if (releaseEntries.isEmpty) {
    print('\nNo newly-published packages found. Nothing to release.');
    exit(0);
  }

  final isDryRun = args.contains('--dry-run');

  // ¦¦ Release version comes from the main package ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
  final releaseVersion = _readLocalVersion('packages/better_player');
  if (releaseVersion == null) {
    _die('Could not read version from packages/better_player/pubspec.yaml');
  }

  final releaseBody = releaseEntries.join('\n\n');

  print('\nRelease version : $releaseVersion');
  print('Release body:\n$releaseBody\n');

  if (isDryRun) {
    print('--- DRY RUN ---');
    print('Would tag and push $releaseVersion');
    print('Would create GitHub Release');
    exit(0);
  }

  // ¦¦ Create & push git tag ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
  // First check if tag already exists
  final tagExistsResult = await Process.run('git', ['rev-parse', releaseVersion]);
  if (tagExistsResult.exitCode == 0) {
    print('Git tag $releaseVersion already exists. Skipping tag creation.');
  } else {
    await _runGit(['tag', releaseVersion]);
    await _runGit(['push', 'origin', releaseVersion]);
    print('Git tag $releaseVersion created and pushed.');
  }

  // ¦¦ Create GitHub Release ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
  final request = await client.postUrl(
    Uri.parse('https://api.github.com/repos/$_repo/releases'),
  )
    ..headers.add(HttpHeaders.authorizationHeader, 'Bearer $token')
    ..headers.add(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json')
    ..headers.add('User-Agent', 'Dart/3.0')
    ..headers.contentType = ContentType.json
    ..write(
      jsonEncode({
        'tag_name': releaseVersion,
        'name': releaseVersion,
        'body': releaseBody,
      }),
    );

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  client.close();

  if (response.statusCode == 201) {
    final htmlUrl = (jsonDecode(responseBody) as Map)['html_url'];
    print('GitHub Release created successfully!');
    print('URL: $htmlUrl');
  } else {
    // If the release already exists, GitHub API returns validation error (422)
    if (response.statusCode == 422) {
      print('GitHub Release $releaseVersion might already exist.');
    } else {
      print('Failed to create GitHub Release. Status: ${response.statusCode}');
      print(responseBody);
      exit(1);
    }
  }
}

// ¦¦ Helpers ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

/// Reads the `version:` field from [packagePath]/pubspec.yaml.
String? _readLocalVersion(String packagePath) {
  final file = File('$packagePath/pubspec.yaml');
  if (!file.existsSync()) return null;
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('version:')) {
      return trimmed.split(':').last.trim();
    }
  }
  return null;
}

/// Fetches the version metadata from pub.dev.
/// Returns the JSON map for that version, or null if not found.
Future<Map<String, dynamic>?> _fetchPubVersion(
  HttpClient client,
  String packageName,
  String version,
) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://pub.dev/api/packages/$packageName/versions/$version'),
    )..headers.add('User-Agent', 'Dart/3.0');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Extracts the first changelog entry (matching [version]) from CHANGELOG.md.
String? _readLatestChangelog(String packagePath, String version) {
  final file = File('$packagePath/CHANGELOG.md');
  if (!file.existsSync()) return null;

  final lines = file.readAsLinesSync();
  final entryLines = <String>[];
  var inEntry = false;

  for (final line in lines) {
    if (line.startsWith('## ')) {
      if (inEntry) break; // next section — stop
      if (line.contains(version)) {
        inEntry = true;
        entryLines.add(line); // include the ## header
      }
    } else if (inEntry) {
      entryLines.add(line);
    }
  }

  if (entryLines.isEmpty) return null;
  // Trim trailing blank lines
  while (entryLines.isNotEmpty && entryLines.last.trim().isEmpty) {
    entryLines.removeLast();
  }
  return entryLines.join('\n');
}

/// Runs a git command and exits on failure.
Future<void> _runGit(List<String> args) async {
  final result = await Process.run('git', args);
  if (result.exitCode != 0) {
    _die('git ${args.join(' ')} failed:\n${result.stderr}');
  }
}

Never _die(String message) {
  print(message);
  exit(1);
}
