//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <better_player_windows/better_player_windows_plugin.h>
#include <bonsoir_windows/bonsoir_windows_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  BetterPlayerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("BetterPlayerWindowsPlugin"));
  BonsoirWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("BonsoirWindowsPluginCApi"));
}
