import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.length < 2) {
    print(
      'Usage: dart run scripts/change_issue_state.dart <ISSUE_NUMBER> <STATE> [owner/repo]',
    );
    print('  <STATE> must be either "open" or "closed"');
    exit(1);
  }

  final issueNumber = args[0];
  final state = args[1].toLowerCase();
  final repo = args.length > 2 ? args[2] : 'jhomlala/betterplayer';

  if (state != 'open' && state != 'closed') {
    print('Error: <STATE> must be either "open" or "closed". Got: $state');
    exit(1);
  }

  final token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    print('Error: GITHUB_TOKEN environment variable is not set.');
    exit(1);
  }

  final uri = Uri.parse('https://api.github.com/repos/$repo/issues/$issueNumber');

  // We use PATCH method to update the issue state
  final request = await HttpClient().patchUrl(uri)
    ..headers.add(HttpHeaders.authorizationHeader, 'token $token')
    ..headers.add(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json')
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'state': state}));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();

  if (response.statusCode == 200) {
    print('Issue #$issueNumber successfully updated to state: $state.');
  } else {
    print('Failed to update issue. Status code: ${response.statusCode}');
    print('Response: $responseBody');
    exit(1);
  }
}
