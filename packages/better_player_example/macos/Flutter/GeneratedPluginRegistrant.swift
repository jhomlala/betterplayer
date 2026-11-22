//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import better_player_macos
import bonsoir_darwin
import package_info_plus
import wakelock_plus

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  BetterPlayerPlugin.register(with: registry.registrar(forPlugin: "BetterPlayerPlugin"))
  SwiftBonsoirPlugin.register(with: registry.registrar(forPlugin: "SwiftBonsoirPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  WakelockPlusMacosPlugin.register(with: registry.registrar(forPlugin: "WakelockPlusMacosPlugin"))
}
