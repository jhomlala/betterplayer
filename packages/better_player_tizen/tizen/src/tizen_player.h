#ifndef FLUTTER_PLUGIN_TIZEN_PLAYER_H_
#define FLUTTER_PLUGIN_TIZEN_PLAYER_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/texture_registrar.h>
#include <player.h>

#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace better_player_tizen {

class TizenPlayer {
 public:
  TizenPlayer(flutter::PluginRegistrar *plugin_registrar,
              flutter::TextureRegistrar *texture_registrar);
  ~TizenPlayer();

  bool Initialize();
  void Dispose();

  void SetDataSource(const std::string &uri,
                     const flutter::EncodableMap &headers);
  void Play();
  void Pause();
  void SeekTo(int32_t position_ms);
  int32_t GetPosition();
  void SetVolume(double volume);
  void SetPlaybackSpeed(double speed);
  void SetLooping(bool looping);

  int64_t GetTextureId() const { return texture_id_; }

 private:
  const FlutterDesktopPixelBuffer *CopyPixelBuffer(size_t width, size_t height);
  void SetUpEventChannel(flutter::BinaryMessenger *messenger);
  void SendEvent(const flutter::EncodableMap &map);

  static void OnPrepared(void *data);
  static void OnCompleted(void *data);
  static void OnBuffering(int percent, void *data);
  static void OnError(int error_code, void *data);
  static void OnVideoFrameDecoded(media_packet_h packet, void *data);

  flutter::PluginRegistrar *plugin_registrar_ = nullptr;
  flutter::TextureRegistrar *texture_registrar_ = nullptr;
  std::unique_ptr<flutter::TextureVariant> texture_variant_;
  FlutterDesktopPixelBuffer desktop_pixel_buffer_{};
  int64_t texture_id_ = -1;

  player_h player_ = nullptr;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  std::mutex buffer_mutex_;
  std::vector<uint8_t> pixel_buffer_;
  size_t buffer_width_ = 0;
  size_t buffer_height_ = 0;

  bool is_initialized_ = false;
  bool is_disposed_ = false;
};

}  // namespace better_player_tizen

#endif  // FLUTTER_PLUGIN_TIZEN_PLAYER_H_
