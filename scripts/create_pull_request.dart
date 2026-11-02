import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.length < 4) {
    print(
      'Usage: dart run scripts/create_pull_request.dart <TITLE> <HEAD_BRANCH> <BASE_BRANCH> <BODY_FILE_PATH> [owner/repo] [--draft]',
    );
    exit(1);
  }

  final isDraft = args.contains('--draft');
  final positionalArgs = args.where((arg) => arg != '--draft').toList();

  final title = positionalArgs[0];
  final headBranch = positionalArgs[1];
  final baseBranch = positionalArgs[2];
  final bodyFilePath = positionalArgs[3];
  final repo = positionalArgs.length > 4
      ? positionalArgs[4]
      : 'jhomlala/betterplayer';

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

  final payload = <String, dynamic>{
    'title': title,
    'head': headBranch,
    'base': baseBranch,
    'body': bodyRaw,
    if (isDraft) 'draft': true,
  };

  final request = await HttpClient().postUrl(uri)
    ..headers.add(HttpHeaders.authorizationHeader, 'token $token')
    ..headers.add(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json')
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(payload));

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
