import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run fetch_pr_comments.dart <PR_NUMBER> [owner/repo]');
    print(
      'Example (defaults to jhomlala/betterplayer): dart run fetch_pr_comments.dart 1499',
    );
    print(
      'Example (custom repo): dart run fetch_pr_comments.dart 123 flutter/flutter',
    );
    exit(1);
  }

  final prNumber = int.tryParse(args[0]);
  if (prNumber == null) {
    print('Error: PR_NUMBER must be a valid integer.');
    exit(1);
  }

  String owner = 'jhomlala';
  String repo = 'betterplayer';

  if (args.length > 1) {
    final parts = args[1].split('/');
    if (parts.length == 2) {
      owner = parts[0];
      repo = parts[1];
    } else {
      print('Error: Repository argument must be in the format owner/repo.');
      exit(1);
    }
  }

  final token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    print('Error: GITHUB_TOKEN environment variable is not set.');
    exit(1);
  }

  final url = Uri.parse('https://api.github.com/graphql');
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'User-Agent': 'Dart-GraphQL-Client',
  };

  final query = r'''
query PRComments($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      comments(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes { author { login } createdAt body url }
      }
      reviewThreads(first: 100) {
        nodes {
          comments(first: 50) {
            nodes { author { login } createdAt body path line url }
          }
        }
      }
      reviews(first: 100) {
        nodes { author { login } createdAt body state url }
      }
    }
  }
}
''';

  final variables = {
    "owner": owner,
    "repo": repo,
    "number": prNumber,
    "cursor": null,
  };

  final List<Map<String, dynamic>> allComments = [];
  bool hasNextPage = true;

  print('Fetching comments for $owner/$repo PR #$prNumber...');

  final client = HttpClient();

  try {
    while (hasNextPage) {
      final request = await client.postUrl(url);
      headers.forEach((key, value) => request.headers.set(key, value));

      final body = jsonEncode({
        'query': query,
        'variables': variables,
      });
      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        print('HTTP Error: ${response.statusCode}');
        print(responseBody);
        exit(1);
      }

      final result = jsonDecode(responseBody);
      if (result.containsKey('errors')) {
        print('GraphQL Errors:');
        print(const JsonEncoder.withIndent('  ').convert(result['errors']));
        exit(1);
      }

      final pr = result['data']['repository']?['pullRequest'];
      if (pr == null) {
        print(
          'Error: Could not find PR #$prNumber in repository $owner/$repo.',
        );
        exit(1);
      }

      // 1. Top-level Issue Comments
      if (pr['comments']['nodes'] != null) {
        for (var node in pr['comments']['nodes']) {
          allComments.add({
            "type": "issue_comment",
            "author": node['author'] != null
                ? node['author']['login']
                : "Unknown",
            "createdAt": node['createdAt'],
            "body": node['body'],
            "url": node['url'],
          });
        }
      }

      // 2. & 3. Parse reviews and reviewThreads (only on first page)
      if (variables['cursor'] == null) {
        // Review Threads (inline diff comments)
        if (pr['reviewThreads']['nodes'] != null) {
          for (var thread in pr['reviewThreads']['nodes']) {
            if (thread['comments']['nodes'] != null) {
              for (var comment in thread['comments']['nodes']) {
                allComments.add({
                  "type": "review_inline_comment",
                  "author": comment['author'] != null
                      ? comment['author']['login']
                      : "Unknown",
                  "createdAt": comment['createdAt'],
                  "body": comment['body'],
                  "url": comment['url'],
                  "path": comment['path'],
                  "line": comment['line'],
                });
              }
            }
          }
        }

        // Reviews (summary comments)
        if (pr['reviews']['nodes'] != null) {
          for (var review in pr['reviews']['nodes']) {
            if (review['body'] != null &&
                review['body'].toString().isNotEmpty) {
              allComments.add({
                "type": "review_summary",
                "author": review['author'] != null
                    ? review['author']['login']
                    : "Unknown",
                "createdAt": review['createdAt'],
                "body": review['body'],
                "url": review['url'],
              });
            }
          }
        }
      }

      final pageInfo = pr['comments']['pageInfo'];
      hasNextPage = (pageInfo['hasNextPage'] as bool?) ?? false;
      variables['cursor'] = pageInfo['endCursor'];
    }

    // Sort chronologically
    allComments.sort(
      (a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String),
    );

    // Save to JSON file dynamically named by PR number in temp dir
    final tempDir = Directory.systemTemp.path;
    final fileName = 'pr_${prNumber}_comments.json';
    final outputFile = File('$tempDir${Platform.pathSeparator}$fileName');

    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(allComments),
    );

    print('\nSuccessfully fetched ${allComments.length} total comments.');
    print('Results saved to: ${outputFile.absolute.path}');
  } finally {
    client.close();
  }
}
