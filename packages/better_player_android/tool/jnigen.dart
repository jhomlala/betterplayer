import 'dart:io';
import 'package:jnigen/jnigen.dart';

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  
  // Broadly search the ENTIRE example/build directory
  final buildDir = Directory.fromUri(packageRoot.resolve('example/build'));
  final classPaths = <Uri>[];
  
  if (buildDir.existsSync()) {
    for (final entity in buildDir.listSync(recursive: true)) {
      if (entity is File) {
        final path = entity.path.replaceAll(r'\', '/');
        // If we find any JAR related to our plugin, add it!
        if (path.endsWith('.jar') && path.contains('better_player_android')) {
          classPaths.add(entity.uri);
        } else if (path.endsWith('.class') && path.contains('pl/hasoft/better_player')) {
          // If we find loose class files, add the root directory
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
