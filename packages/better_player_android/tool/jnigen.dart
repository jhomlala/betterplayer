import 'dart:io';
import 'package:jnigen/jnigen.dart';

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  
  // Find where the kotlin classes were actually compiled
  final buildDir = Directory.fromUri(packageRoot.resolve('example/build/better_player_android'));
  List<Uri> classPaths = [];
  if (buildDir.existsSync()) {
    for (var entity in buildDir.listSync(recursive: true)) {
      if (entity is File) {
        if (entity.path.endsWith('.jar')) {
          classPaths.add(entity.uri);
        } else if (entity.path.endsWith('BetterPlayerApi.class')) {
          // Found the class! Walk up the tree to the root of the package structure
          // pl/hasoft/better_player/BetterPlayerApi.class
          var rootDir = entity.parent.parent.parent.parent;
          if (!classPaths.contains(rootDir.uri)) {
            classPaths.add(rootDir.uri);
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
