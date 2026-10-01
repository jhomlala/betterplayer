import 'dart:io';
import 'package:ffigen/ffigen.dart' as fg;
import 'package:logging/logging.dart';
import 'package:swiftgen/swiftgen.dart';

/// macOS FFI binding generator using swiftgen and ffigen.
Future<void> main() async {
  final logger = Logger('swiftgen');
  logger.onRecord.listen((record) {
    stderr.writeln('${record.level.name}: ${record.message}');
  });

  final packageRoot = Platform.script.resolve('../');

  final sdkPath = (await Process.run('xcrun', [
    '--sdk',
    'macosx',
    '--show-sdk-path',
  ])).stdout.toString().trim();
  final sdkVersion = (await Process.run('xcrun', [
    '--sdk',
    'macosx',
    '--show-sdk-version',
  ])).stdout.toString().trim();

  await SwiftGenerator(
    target: Target(
      triple: 'arm64-apple-macos$sdkVersion',
      sdk: Uri.directory(sdkPath),
    ),
    inputs: [
      ObjCCompatibleSwiftFileInput(
        files: [
          packageRoot.resolve(
            'macos/better_player_macos/Sources/better_player_macos/BetterPlayerApi.swift',
          ),
          packageRoot.resolve(
            'macos/better_player_macos/Sources/better_player_macos/BetterPlayer.swift',
          ),
          packageRoot.resolve(
            'macos/better_player_macos/Sources/better_player_macos/BetterPlayerTimeUtils.swift',
          ),
          packageRoot.resolve(
            'macos/better_player_macos/Sources/better_player_macos/BetterPlayerView.swift',
          ),
        ],
      ),
    ],
    output: Output(
      module: 'better_player_macos',
      dartFile: packageRoot.resolve('lib/src/better_player_macos_ffi.g.dart'),
      objectiveCFile: packageRoot.resolve(
        'macos/better_player_macos/Sources/better_player_macos_objc/better_player.m',
      ),
    ),
    ffigen: FfiGeneratorOptions(
      objectiveC: fg.ObjectiveC(
        interfaces: fg.Interfaces(
          include: (decl) =>
              ['BetterPlayerApi', 'BetterPlayer'].contains(decl.originalName),
        ),
        protocols: fg.Protocols(
          include: (decl) => [
            'BetterPlayerCallback',
            'BetterPlayerLogCallback',
          ].contains(decl.originalName),
        ),
      ),
    ),
  ).generate(logger: logger);

  // Apply monkey-patches to resolve header imports and force-load symbols
  final objcFile = packageRoot.resolve(
    'macos/better_player_macos/Sources/better_player_macos_objc/better_player.m',
  );
  final file = File.fromUri(objcFile);
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'#import\s+"[^"]+better_player_macos\.h"'),
      '',
    );
    content = content.replaceAll(
      '@protocol(BetterPlayerCallback)',
      'NSProtocolFromString(@"BetterPlayerCallback")',
    );
    content = content.replaceAll(
      '@protocol(BetterPlayerLogCallback)',
      'NSProtocolFromString(@"BetterPlayerLogCallback")',
    );
    content += '\nvoid better_player_macos_force_load_symbols(void) {}\n';
    file.writeAsStringSync(content);

    final dartFile = File(
      packageRoot
          .resolve('lib/src/better_player_macos_ffi.g.dart')
          .toFilePath(),
    );
    if (dartFile.existsSync()) {
      var dartContent = dartFile.readAsStringSync();
      dartContent = dartContent.replaceAll(
        '"better_player_macos.BetterPlayerCallback"',
        '"BetterPlayerCallback"',
      );
      dartContent = dartContent.replaceAll(
        '"better_player_macos.BetterPlayerLogCallback"',
        '"BetterPlayerLogCallback"',
      );
      dartFile.writeAsStringSync(dartContent);
    }
  }
}
