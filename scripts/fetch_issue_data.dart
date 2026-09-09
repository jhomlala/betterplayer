import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart run fetch_issue_data.dart <ISSUE_URL_OR_NUMBER> [owner/repo]',
    );
    print(
      'Example (URL): dart run fetch_issue_data.dart https://github.com/jhomlala/betterplayer/issues/1500',
    );
    print(
      'Example (Number): dart run fetch_issue_data.dart 1500',
    );
    print(
      'Example (custom repo): dart run fetch_issue_data.dart 123 flutter/flutter',
    );
    exit(1);
  }

  String owner = 'jhomlala';
  String repo = 'betterplayer';
  int? issueNumber;

  final input = args[0];
  if (input.startsWith('http')) {
    final uri = Uri.tryParse(input);
    if (uri == null ||
        uri.pathSegments.length < 4 ||
        uri.pathSegments[uri.pathSegments.length - 2] != 'issues') {
      print('Error: Invalid GitHub issue URL.');
      exit(1);
    }
    // Expected format: /owner/repo/issues/number
    // uri.pathSegments would be ['owner', 'repo', 'issues', 'number']
    owner = uri.pathSegments[0];
    repo = uri.pathSegments[1];
    issueNumber = int.tryParse(uri.pathSegments[3]);
  } else {
    issueNumber = int.tryParse(input);
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
  }

  if (issueNumber == null) {
    print('Error: Could not determine issue number.');
    exit(1);
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
query IssueData($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) {
      title
      body
      author { login }
      createdAt
      url
      state
      labels(first: 20) {
        nodes { name }
      }
      comments(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes { author { login } createdAt body url }
      }
    }
  }
}
''';

  final variables = {
    "owner": owner,
    "repo": repo,
    "number": issueNumber,
    "cursor": null,
  };

  final Map<String, dynamic> outputData = {};
  final List<Map<String, dynamic>> allComments = [];
  bool hasNextPage = true;

  print('Fetching issue data for $owner/$repo Issue #$issueNumber...');

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

      final issue = result['data']['repository']?['issue'];
      if (issue == null) {
        print(
          'Error: Could not find issue #$issueNumber in repository $owner/$repo.',
        );
        exit(1);
      }

      if (outputData.isEmpty) {
        outputData['title'] = issue['title'];
        outputData['body'] = issue['body'];
        outputData['author'] = issue['author']?['login'] ?? 'Unknown';
        outputData['createdAt'] = issue['createdAt'];
        outputData['url'] = issue['url'];
        outputData['state'] = issue['state'];
        outputData['labels'] = (issue['labels']['nodes'] as List)
            .map((n) => n['name'])
            .toList();
        outputData['comments'] = allComments;
      }

      if (issue['comments']['nodes'] != null) {
        for (var node in issue['comments']['nodes']) {
          allComments.add({
            "author": node['author'] != null
                ? node['author']['login']
                : "Unknown",
            "createdAt": node['createdAt'],
            "body": node['body'],
            "url": node['url'],
          });
        }
      }

      final pageInfo = issue['comments']['pageInfo'];
      hasNextPage = (pageInfo['hasNextPage'] as bool?) ?? false;
      variables['cursor'] = pageInfo['endCursor'];
    }

    // Sort comments chronologically
    allComments.sort(
      (a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String),
    );

    // Save to JSON file dynamically named by issue number in temp dir
    final tempDir = Directory.systemTemp.path;
    final fileName = 'issue_${issueNumber}_data.json';
    final outputFile = File('$tempDir${Platform.pathSeparator}$fileName');

    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(outputData),
    );

    print(
      '\nSuccessfully fetched issue data and ${allComments.length} total comments.',
    );
    print('Results saved to: ${outputFile.absolute.path}');
  } finally {
    client.close();
  }
}
