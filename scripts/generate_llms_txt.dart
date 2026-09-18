import 'dart:io';

void main() {
  final docsDir = Directory('docs');
  final staticDir = Directory('docs/static');
  
  if (!staticDir.existsSync()) {
    staticDir.createSync(recursive: true);
  }

  final files = docsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();
  
  // Sort files for consistent output
  files.sort((a, b) => a.path.compareTo(b.path));

  final llmsTxt = StringBuffer();
  llmsTxt.writeln('# Better Player');
  llmsTxt.writeln('> The most advanced video player for Flutter — HLS, DASH, DRM (Widevine/FairPlay/ClearKey), subtitles, caching, PiP, playlists. Replaces video_player and chewie with a single package.');
  llmsTxt.writeln();
  llmsTxt.writeln('## Documentation');
  
  final llmsFullTxt = StringBuffer();
  llmsFullTxt.writeln('# Better Player - Full Documentation');
  llmsFullTxt.writeln();

  for (final file in files) {
    final fileName = file.uri.pathSegments.last;
    final slug = fileName.replaceAll('.md', '');
    llmsTxt.writeln('- [$slug](https://jhomlala.github.io/betterplayer/$slug)');
    
    llmsFullTxt.writeln('---');
    llmsFullTxt.writeln('# $fileName');
    llmsFullTxt.writeln('---');
    llmsFullTxt.writeln(file.readAsStringSync());
    llmsFullTxt.writeln();
  }

  File('docs/static/llms.txt').writeAsStringSync(llmsTxt.toString());
  File('docs/static/llms-full.txt').writeAsStringSync(llmsFullTxt.toString());
  
  print('Generated llms.txt and llms-full.txt in docs/static/');
}
