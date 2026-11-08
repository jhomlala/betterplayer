#include "better_player_tizen_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <mutex>
#include <string>

#include "tizen_player.h"

namespace better_player_tizen {

class BetterPlayerTizenPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  BetterPlayerTizenPlugin(
      flutter::PluginRegistrar *registrar,
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);
  virtual ~BetterPlayerTizenPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  TizenPlayer *FindPlayer(const flutter::EncodableMap *args,
                          flutter::MethodResult<flutter::EncodableValue> *result);

  flutter::PluginRegistrar *registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::mutex mutex_;
  std::map<int64_t, std::unique_ptr<TizenPlayer>> players_;
};

void BetterPlayerTizenPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "better_player_tizen",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<BetterPlayerTizenPlugin>(
      registrar, std::move(channel));

  plugin->channel_->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

BetterPlayerTizenPlugin::BetterPlayerTizenPlugin(
    flutter::PluginRegistrar *registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel)
    : registrar_(registrar), channel_(std::move(channel)) {}

BetterPlayerTizenPlugin::~BetterPlayerTizenPlugin() {
  std::lock_guard<std::mutex> lock(mutex_);
  players_.clear();
}

TizenPlayer *BetterPlayerTizenPlugin::FindPlayer(
    const flutter::EncodableMap *args,
    flutter::MethodResult<flutter::EncodableValue> *result) {
  if (!args) {
    result->Error("BAD_ARGS", "Expected map arguments");
    return nullptr;
  }

  auto it = args->find(flutter::EncodableValue("textureId"));
  if (it == args->end()) {
    result->Error("BAD_ARGS", "Missing textureId argument");
    return nullptr;
  }

  int64_t texture_id = it->second.LongValue();
  std::lock_guard<std::mutex> lock(mutex_);
  auto player_it = players_.find(texture_id);
  if (player_it == players_.end()) {
    result->Error("NOT_FOUND", "Player not found");
    return nullptr;
  }
  return player_it->second.get();
}

void BetterPlayerTizenPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string &method = method_call.method_name();
  const auto *args =
      std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (method == "create") {
    auto player = std::make_unique<TizenPlayer>(
        registrar_, registrar_->texture_registrar());
    if (!player->Initialize()) {
      result->Error("CREATION_FAILED", "Failed to initialize Tizen player");
      return;
    }

    int64_t texture_id = player->GetTextureId();
    {
      std::lock_guard<std::mutex> lock(mutex_);
      players_[texture_id] = std::move(player);
    }

    flutter::EncodableMap response;
    response[flutter::EncodableValue("textureId")] =
        flutter::EncodableValue(texture_id);
    result->Success(flutter::EncodableValue(response));
  } else if (method == "dispose") {
    if (!args) {
      result->Error("BAD_ARGS", "Expected map arguments for dispose");
      return;
    }
    auto it = args->find(flutter::EncodableValue("textureId"));
    if (it == args->end()) {
      result->Error("BAD_ARGS", "Missing textureId argument for dispose");
      return;
    }
    int64_t texture_id = it->second.LongValue();

    std::unique_ptr<TizenPlayer> player_to_destroy;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      auto player_it = players_.find(texture_id);
      if (player_it != players_.end()) {
        player_to_destroy = std::move(player_it->second);
        players_.erase(player_it);
      }
    }
    player_to_destroy.reset();
    result->Success();
  } else if (method == "clear") {
    std::lock_guard<std::mutex> lock(mutex_);
    players_.clear();
    result->Success();
  } else if (method == "setDataSource") {
    TizenPlayer *player = FindPlayer(args, result.get());
    if (!player) return;

    std::string uri;
    auto uri_it = args->find(flutter::EncodableValue("uri"));
    if (uri_it != args->end() && std::holds_alternative<std::string>(uri_it->second)) {
      uri = std::get<std::string>(uri_it->second);
    }

    flutter::EncodableMap headers;
    auto headers_it = args->find(flutter::EncodableValue("headers"));
    if (headers_it != args->end() &&
        std::holds_alternative<flutter::EncodableMap>(headers_it->second)) {
      headers = std::get<flutter::EncodableMap>(headers_it->second);
    }

    player->SetDataSource(uri, headers);
    result->Success();
  } else if (method == "play") {
    TizenPlayer *player = FindPlayer(args, result.get());
    if (!player) return;
    player->Play();
    result->Success();
  } else if (method == "pause") {
    TizenPlayer *player = FindPlayer(args, result.get());
    if (!player) return;
    player->Pause();
    result->Success();
  } else if (method == "seekTo") {
    TizenPlayer *player = FindPlayer(args, result.get());
    if (!player) return;
    int32_t position_ms = 0;
    auto it = args->find(flutter::EncodableValue("position"));
    if (it != args->end()) {
      position_ms = static_cast<int32_t>(it->second.LongValue());
    }
    player->SeekTo(position_ms);
    result->Success();
  } else if (method == "getPosition") {
    TizenPlayer *player = FindPlayer(args, result.get());
    if (!player) return;
    int32_t position_ms = player->GetPosition();
    result->Success(flutter::EncodableValue(position_ms));
  } else if (method == "setVolume") {
    TizenPlayer *player = FindPlayer(args, result.get());
    if (!player) return;
    double volume = 1.0;
    auto it = args->find(flutter::EncodableValue("volume"));
    if (it != args->end()) {
      if (std::holds_alternative<double>(it->second)) {
        volume = std::get<double>(it->second);
      } else if (std::holds_alternative<int32_t>(it->second)) {
        volume = static_cast<double>(std::get<int32_t>(it->second));
      } else if (std::holds_alternative<int64_t>(it->second)) {
        volume = static_cast<double>(std::get<int64_t>(it->second));
      }
    }
    player->SetVolume(volume);
    result->Success();
  } else if (method == "setSpeed") {
    TizenPlayer *player = FindPlayer(args, result.get());
    if (!player) return;
    double speed = 1.0;
    auto it = args->find(flutter::EncodableValue("speed"));
    if (it != args->end()) {
      if (std::holds_alternative<double>(it->second)) {
        speed = std::get<double>(it->second);
      } else if (std::holds_alternative<int32_t>(it->second)) {
        speed = static_cast<double>(std::get<int32_t>(it->second));
      } else if (std::holds_alternative<int64_t>(it->second)) {
        speed = static_cast<double>(std::get<int64_t>(it->second));
      }
    }
    player->SetPlaybackSpeed(speed);
    result->Success();
  } else if (method == "setLooping") {
    TizenPlayer *player = FindPlayer(args, result.get());
    if (!player) return;
    bool looping = false;
    auto it = args->find(flutter::EncodableValue("looping"));
    if (it != args->end() && std::holds_alternative<bool>(it->second)) {
      looping = std::get<bool>(it->second);
    }
    player->SetLooping(looping);
    result->Success();
  } else if (method == "setTrackParameters") {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace better_player_tizen

void BetterPlayerTizenPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  better_player_tizen::BetterPlayerTizenPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrar>(registrar));
}
