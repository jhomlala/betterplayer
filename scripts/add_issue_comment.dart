import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart run scripts/add_issue_comment.dart <ISSUE_NUMBER> <COMMENT_FILE_PATH> [owner/repo]');
    exit(1);
  }

  final issueNumber = args[0];
  final commentFilePath = args[1];
  final repo = args.length > 2 ? args[2] : 'jhomlala/betterplayer';

  final token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    print('Error: GITHUB_TOKEN environment variable is not set.');
    exit(1);
  }

  final file = File(commentFilePath);
  if (!await file.exists()) {
    print('Error: Comment file not found at \');
    exit(1);
  }

  final bodyRaw = await file.readAsString();
  final uri = Uri.parse('https://api.github.com/repos/\/issues/\/comments');

  final request = await HttpClient().postUrl(uri)
    ..headers.add(HttpHeaders.authorizationHeader, 'token \')
    ..headers.add(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json')
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'body': bodyRaw}));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();

  if (response.statusCode == 201) {
    print('Comment successfully posted to issue #\.');
  } else {
    print('Failed to post comment. Status code: \');
    print('Response: \');
    exit(1);
  }
}
