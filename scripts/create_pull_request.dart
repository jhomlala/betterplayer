import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.length < 4) {
    print(
      'Usage: dart run scripts/create_pull_request.dart <TITLE> <HEAD_BRANCH> <BASE_BRANCH> <BODY_FILE_PATH> [owner/repo]',
    );
    exit(1);
  }

  final title = args[0];
  final headBranch = args[1];
  final baseBranch = args[2];
  final bodyFilePath = args[3];
  final repo = args.length > 4 ? args[4] : 'jhomlala/betterplayer';

  final token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    print('Error: GITHUB_TOKEN environment variable is not set.');
    exit(1);
  }

  final file = File(bodyFilePath);
  if (!await file.exists()) {
    print('Error: Body file not found at $bodyFilePath');
    exit(1);
  }

  final bodyRaw = await file.readAsString();
  final uri = Uri.parse('https://api.github.com/repos/$repo/pulls');

  final request = await HttpClient().postUrl(uri)
    ..headers.add(HttpHeaders.authorizationHeader, 'token $token')
    ..headers.add(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json')
    ..headers.contentType = ContentType.json
    ..write(
      jsonEncode({
        'title': title,
        'head': headBranch,
        'base': baseBranch,
        'body': bodyRaw,
      }),
    );

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();

  if (response.statusCode == 201) {
    final jsonResponse = jsonDecode(responseBody);
    final prUrl = jsonResponse['html_url'];
    print('Pull Request successfully created!');
    print('URL: $prUrl');
  } else {
    print('Failed to create Pull Request. Status code: ${response.statusCode}');
    print('Response: $responseBody');
    exit(1);
  }
}
