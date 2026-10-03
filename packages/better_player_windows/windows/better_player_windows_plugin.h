#ifndef BETTER_PLAYER_WINDOWS_PLUGIN_H_
#define BETTER_PLAYER_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <map>
#include <mutex>

#include "texture_bridge.h"

namespace better_player_windows {

class BetterPlayerWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  BetterPlayerWindowsPlugin(
      flutter::PluginRegistrarWindows *registrar,
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);

  virtual ~BetterPlayerWindowsPlugin();

  BetterPlayerWindowsPlugin(const BetterPlayerWindowsPlugin&) = delete;
  BetterPlayerWindowsPlugin& operator=(const BetterPlayerWindowsPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows *registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  std::map<int64_t, std::unique_ptr<TextureBridge>> players_;
  std::mutex mutex_;
};

}  // namespace better_player_windows

#endif  // BETTER_PLAYER_WINDOWS_PLUGIN_H_
