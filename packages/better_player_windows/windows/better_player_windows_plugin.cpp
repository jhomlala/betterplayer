#include "better_player_windows_plugin.h"

namespace better_player_windows {

// static
void BetterPlayerWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "better_player_windows",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<BetterPlayerWindowsPlugin>(
      registrar, std::move(channel));

  plugin->channel_->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

BetterPlayerWindowsPlugin::BetterPlayerWindowsPlugin(
    flutter::PluginRegistrarWindows *registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel)
    : registrar_(registrar), channel_(std::move(channel)) {}

BetterPlayerWindowsPlugin::~BetterPlayerWindowsPlugin() {
  std::lock_guard<std::mutex> lock(mutex_);
  players_.clear();
}

void BetterPlayerWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("create") == 0) {
    auto bridge = std::make_unique<TextureBridge>(registrar_->texture_registrar());
    if (!bridge->Initialize()) {
      result->Error("INITIALIZE_FAILED", "Failed to initialize D3D11 texture and mpv context.");
      return;
    }

    int64_t texture_id = bridge->GetTextureId();
    int64_t mpv_handle = reinterpret_cast<int64_t>(bridge->GetMpvHandle());

    {
      std::lock_guard<std::mutex> lock(mutex_);
      players_[texture_id] = std::move(bridge);
    }

    flutter::EncodableMap response;
    response[flutter::EncodableValue("textureId")] = flutter::EncodableValue(texture_id);
    response[flutter::EncodableValue("mpvHandle")] = flutter::EncodableValue(mpv_handle);
    result->Success(flutter::EncodableValue(response));
  } else if (method_call.method_name().compare("dispose") == 0) {
    const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("BAD_ARGS", "Expected map arguments for dispose");
      return;
    }

    auto texture_id_it = arguments->find(flutter::EncodableValue("textureId"));
    if (texture_id_it == arguments->end()) {
      result->Error("BAD_ARGS", "Missing textureId argument for dispose");
      return;
    }

    int64_t texture_id = texture_id_it->second.LongValue();
    {
      std::lock_guard<std::mutex> lock(mutex_);
      players_.erase(texture_id);
    }

    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace better_player_windows
