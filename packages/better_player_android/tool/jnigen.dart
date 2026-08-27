import 'dart:io';
import 'package:jnigen/jnigen.dart';

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  
  // Find where the kotlin classes were actually compiled
  final buildDir = Directory.fromUri(packageRoot.resolve('example/build/better_player_android'));
  List<Uri> classPaths = [];
  if (buildDir.existsSync()) {
    for (var entity in buildDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.class')) {
        // Add the directory containing 'pl/hasoft/better_player' to the classPath
        final path = entity.path.replaceAll('\\', '/');
        if (path.contains('pl/hasoft/better_player')) {
          final rootPath = path.substring(0, path.indexOf('pl/hasoft/better_player'));
          final uri = Uri.directory(rootPath);
          if (!classPaths.contains(uri)) {
            classPaths.add(uri);
          }
        }
      }
    }
  }

  print('Discovered classPaths: $classPaths');

  generateJniBindings(Config(
    outputConfig: OutputConfig(
      dartConfig: DartCodeOutputConfig(
        path: packageRoot.resolve('lib/src/better_player_android_jni.g.dart'),
        structure: OutputStructure.singleFile,
      ),
    ),
    androidSdkConfig: AndroidSdkConfig(
      addGradleDeps: true,
      androidExample: 'example', // Points to example app for Gradle resolution
    ),
    classPath: classPaths,
    classes: [
      'pl.hasoft.better_player.BetterPlayerApi',
      'pl.hasoft.better_player.BetterPlayerCallback',
      'pl.hasoft.better_player.BetterPlayer',
    ],
  ));
}
