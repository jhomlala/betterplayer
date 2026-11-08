#include "tizen_player.h"

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <iostream>

namespace better_player_tizen {

TizenPlayer::TizenPlayer(flutter::PluginRegistrar *plugin_registrar,
                         flutter::TextureRegistrar *texture_registrar)
    : plugin_registrar_(plugin_registrar),
      texture_registrar_(texture_registrar) {}

TizenPlayer::~TizenPlayer() { Dispose(); }

bool TizenPlayer::Initialize() {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  int ret = player_create(&player_);
  if (ret != PLAYER_ERROR_NONE) {
    std::cerr << "[BetterPlayerTizen] player_create failed: " << ret
              << std::endl;
    return false;
  }

  player_set_completed_cb(player_, OnCompleted, this);
  player_set_buffering_cb(player_, OnBuffering, this);
  player_set_error_cb(player_, OnError, this);
  player_set_interrupted_cb(player_, OnInterrupted, this);
  player_set_media_packet_video_frame_decoded_cb(
      player_, OnVideoFrameDecoded, this);

  texture_variant_ = std::make_unique<flutter::TextureVariant>(
      flutter::PixelBufferTexture([this](size_t width, size_t height) {
        return this->CopyPixelBuffer(width, height);
      }));

  texture_id_ = texture_registrar_->RegisterTexture(texture_variant_.get());
  SetUpEventChannel(plugin_registrar_->messenger());
  return true;
}

void TizenPlayer::SetUpEventChannel(flutter::BinaryMessenger *messenger) {
  std::string channel_name =
      "better_player_tizen/video_events_" + std::to_string(texture_id_);
  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, channel_name,
          &flutter::StandardMethodCodec::GetInstance());

  auto handler =
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](const flutter::EncodableValue *arguments,
                 std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
                     &&events)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            std::lock_guard<std::mutex> lock(event_mutex_);
            event_sink_ = std::move(events);
            return nullptr;
          },
          [this](const flutter::EncodableValue *arguments)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            std::lock_guard<std::mutex> lock(event_mutex_);
            event_sink_ = nullptr;
            return nullptr;
          });

  event_channel_->SetStreamHandler(std::move(handler));
}

void TizenPlayer::SendEvent(const flutter::EncodableMap &map) {
  if (is_disposed_.load()) {
    return;
  }
  std::lock_guard<std::mutex> lock(event_mutex_);
  if (event_sink_) {
    event_sink_->Success(flutter::EncodableValue(map));
  }
}

const FlutterDesktopPixelBuffer *TizenPlayer::CopyPixelBuffer(size_t width,
                                                              size_t height) {
  std::lock_guard<std::mutex> lock(buffer_mutex_);
  if (is_disposed_.load() || pixel_buffer_.empty()) {
    return nullptr;
  }
  desktop_pixel_buffer_.buffer = pixel_buffer_.data();
  desktop_pixel_buffer_.width = buffer_width_ > 0 ? buffer_width_ : width;
  desktop_pixel_buffer_.height = buffer_height_ > 0 ? buffer_height_ : height;
  desktop_pixel_buffer_.release_callback = nullptr;
  desktop_pixel_buffer_.release_context = nullptr;
  return &desktop_pixel_buffer_;
}

void TizenPlayer::OnVideoFrameDecoded(media_packet_h packet, void *data) {
  auto *self = static_cast<TizenPlayer *>(data);
  if (!self || !packet) {
    if (packet) {
      media_packet_destroy(packet);
    }
    return;
  }

  void *buffer_ptr = nullptr;
  int ret = media_packet_get_buffer_data_ptr(packet, &buffer_ptr);
  uint64_t packet_size = 0;
  media_packet_get_buffer_size(packet, &packet_size);
  if (ret != 0 || !buffer_ptr || packet_size == 0) {
    media_packet_destroy(packet);
    return;
  }

  int width = 0;
  int height = 0;
  {
    std::lock_guard<std::recursive_mutex> lock(self->player_mutex_);
    if (self->is_disposed_.load() || !self->player_) {
      media_packet_destroy(packet);
      return;
    }
    player_get_video_size(self->player_, &width, &height);
  }

  if (width <= 0 || height <= 0) {
    media_packet_destroy(packet);
    return;
  }

  size_t buffer_size = static_cast<size_t>(width) * static_cast<size_t>(height) * 4;
  size_t copy_bytes = std::min(buffer_size, static_cast<size_t>(packet_size));
  {
    std::lock_guard<std::mutex> lock(self->buffer_mutex_);
    if (self->pixel_buffer_.size() != buffer_size) {
      self->pixel_buffer_.assign(buffer_size, 0);
    }
    self->buffer_width_ = static_cast<size_t>(width);
    self->buffer_height_ = static_cast<size_t>(height);
    std::copy_n(static_cast<const uint8_t *>(buffer_ptr), copy_bytes,
                self->pixel_buffer_.data());
  }

  media_packet_destroy(packet);

  if (self->last_width_ != static_cast<size_t>(width) ||
      self->last_height_ != static_cast<size_t>(height)) {
    self->last_width_ = static_cast<size_t>(width);
    self->last_height_ = static_cast<size_t>(height);
    flutter::EncodableMap size_event;
    size_event[flutter::EncodableValue("event")] =
        flutter::EncodableValue("changedSize");
    size_event[flutter::EncodableValue("width")] =
        flutter::EncodableValue(static_cast<int32_t>(width));
    size_event[flutter::EncodableValue("height")] =
        flutter::EncodableValue(static_cast<int32_t>(height));
    self->SendEvent(size_event);
  }

  if (!self->is_disposed_.load() && self->texture_registrar_ &&
      self->texture_id_ >= 0) {
    self->texture_registrar_->MarkTextureFrameAvailable(self->texture_id_);
  }
}

void TizenPlayer::SetDataSource(const std::string &uri,
                                const flutter::EncodableMap &headers) {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  if (player_ == nullptr || is_disposed_.load()) {
    return;
  }

  if (is_initialized_.exchange(false)) {
    player_stop(player_);
    player_unprepare(player_);
  }

  for (const auto &kv : headers) {
    if (std::holds_alternative<std::string>(kv.first) &&
        std::holds_alternative<std::string>(kv.second)) {
      const auto &key = std::get<std::string>(kv.first);
      const auto &val = std::get<std::string>(kv.second);
      if ((key == "Cookie" || key == "cookie") && !val.empty()) {
        player_set_streaming_cookie(player_, val.c_str(), val.size());
      }
    }
  }

  int ret = player_set_uri(player_, uri.c_str());
  if (ret != PLAYER_ERROR_NONE) {
    std::cerr << "[BetterPlayerTizen] player_set_uri failed: " << ret
              << std::endl;
    OnError(ret, this);
    return;
  }

  ret = player_prepare_async(player_, OnPrepared, this);
  if (ret != PLAYER_ERROR_NONE) {
    std::cerr << "[BetterPlayerTizen] player_prepare_async failed: " << ret
              << std::endl;
    OnError(ret, this);
  }
}

void TizenPlayer::OnPrepared(void *data) {
  auto *self = static_cast<TizenPlayer *>(data);
  if (!self || self->is_disposed_.load()) {
    return;
  }

  int duration_ms = 0;
  int width = 0;
  int height = 0;
  {
    std::lock_guard<std::recursive_mutex> lock(self->player_mutex_);
    if (self->is_disposed_.load() || !self->player_) {
      return;
    }
    player_get_duration(self->player_, &duration_ms);
    player_get_video_size(self->player_, &width, &height);
    self->is_initialized_.store(true);
  }

  flutter::EncodableMap event;
  event[flutter::EncodableValue("event")] =
      flutter::EncodableValue("initialized");
  event[flutter::EncodableValue("duration")] =
      flutter::EncodableValue(static_cast<int32_t>(duration_ms));
  event[flutter::EncodableValue("width")] =
      flutter::EncodableValue(static_cast<int32_t>(width));
  event[flutter::EncodableValue("height")] =
      flutter::EncodableValue(static_cast<int32_t>(height));

  self->SendEvent(event);
}

void TizenPlayer::OnCompleted(void *data) {
  auto *self = static_cast<TizenPlayer *>(data);
  if (!self || self->is_disposed_.load()) {
    return;
  }

  self->is_completed_.store(true);
  flutter::EncodableMap event;
  event[flutter::EncodableValue("event")] = flutter::EncodableValue("completed");
  self->SendEvent(event);
}

void TizenPlayer::OnBuffering(int percent, void *data) {
  auto *self = static_cast<TizenPlayer *>(data);
  if (!self || self->is_disposed_.load()) {
    return;
  }

  int duration_ms = 0;
  {
    std::lock_guard<std::recursive_mutex> lock(self->player_mutex_);
    if (self->is_disposed_.load() || !self->player_) {
      return;
    }
    player_get_duration(self->player_, &duration_ms);
  }
  int32_t buffered_end = static_cast<int32_t>(duration_ms * (percent / 100.0));

  if (percent < 100) {
    if (!self->is_buffering_.exchange(true)) {
      flutter::EncodableMap start_event;
      start_event[flutter::EncodableValue("event")] =
          flutter::EncodableValue("bufferingStart");
      self->SendEvent(start_event);
    }
  } else {
    if (self->is_buffering_.exchange(false)) {
      flutter::EncodableMap end_event;
      end_event[flutter::EncodableValue("event")] =
          flutter::EncodableValue("bufferingEnd");
      self->SendEvent(end_event);
    }
  }

  flutter::EncodableList ranges;
  flutter::EncodableList range;
  range.push_back(flutter::EncodableValue(static_cast<int32_t>(0)));
  range.push_back(flutter::EncodableValue(buffered_end));
  ranges.push_back(flutter::EncodableValue(range));

  flutter::EncodableMap event;
  event[flutter::EncodableValue("event")] =
      flutter::EncodableValue("bufferingUpdate");
  event[flutter::EncodableValue("values")] = flutter::EncodableValue(ranges);
  self->SendEvent(event);
}

void TizenPlayer::OnError(int error_code, void *data) {
  auto *self = static_cast<TizenPlayer *>(data);
  if (!self || self->is_disposed_.load()) {
    return;
  }

  self->is_initialized_.store(false);
  self->is_buffering_.store(false);

  std::lock_guard<std::mutex> lock(self->event_mutex_);
  if (self->event_sink_) {
    self->event_sink_->Error(
        "PLAYER_ERROR",
        "Tizen media player error: " + std::to_string(error_code));
  }
}

void TizenPlayer::OnInterrupted(player_interrupted_code_e code, void *data) {
  auto *self = static_cast<TizenPlayer *>(data);
  if (!self || self->is_disposed_.load()) {
    return;
  }

  flutter::EncodableMap event;
  event[flutter::EncodableValue("event")] =
      flutter::EncodableValue("isPlayingStateUpdate");
  event[flutter::EncodableValue("isPlaying")] = flutter::EncodableValue(false);
  self->SendEvent(event);
}

void TizenPlayer::Play() {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  if (player_ == nullptr || is_disposed_.load()) return;
  if (is_completed_.exchange(false)) {
    player_set_play_position(player_, 0, true, nullptr, nullptr);
  }
  player_start(player_);

  flutter::EncodableMap event;
  event[flutter::EncodableValue("event")] =
      flutter::EncodableValue("isPlayingStateUpdate");
  event[flutter::EncodableValue("isPlaying")] = flutter::EncodableValue(true);
  SendEvent(event);
}

void TizenPlayer::Pause() {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  if (player_ == nullptr || is_disposed_.load()) return;
  player_pause(player_);

  flutter::EncodableMap event;
  event[flutter::EncodableValue("event")] =
      flutter::EncodableValue("isPlayingStateUpdate");
  event[flutter::EncodableValue("isPlaying")] = flutter::EncodableValue(false);
  SendEvent(event);
}

void TizenPlayer::SeekTo(int32_t position_ms) {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  if (player_ == nullptr || is_disposed_.load()) return;
  player_set_play_position(player_, position_ms, true, nullptr, nullptr);
}

int32_t TizenPlayer::GetPosition() {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  if (player_ == nullptr || is_disposed_.load()) return 0;
  int position_ms = 0;
  player_get_play_position(player_, &position_ms);
  return static_cast<int32_t>(position_ms);
}

void TizenPlayer::SetVolume(double volume) {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  if (player_ == nullptr || is_disposed_.load()) return;
  float vol = static_cast<float>(std::clamp(volume, 0.0, 1.0));
  player_set_volume(player_, vol, vol);
}

void TizenPlayer::SetPlaybackSpeed(double speed) {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  if (player_ == nullptr || is_disposed_.load()) return;
  if (std::isfinite(speed) && speed > 0.0) {
    player_set_playback_rate(player_, static_cast<float>(speed));
  }
}

void TizenPlayer::SetLooping(bool looping) {
  std::lock_guard<std::recursive_mutex> lock(player_mutex_);
  if (player_ == nullptr || is_disposed_.load()) return;
  player_set_looping(player_, looping);
}

void TizenPlayer::Dispose() {
  if (is_disposed_.exchange(true)) {
    return;
  }

  player_h player_to_destroy = nullptr;
  {
    std::lock_guard<std::recursive_mutex> lock(player_mutex_);
    player_to_destroy = player_;
    player_ = nullptr;
  }

  if (player_to_destroy) {
    player_unset_completed_cb(player_to_destroy);
    player_unset_buffering_cb(player_to_destroy);
    player_unset_error_cb(player_to_destroy);
    player_unset_interrupted_cb(player_to_destroy);
    player_unset_media_packet_video_frame_decoded_cb(player_to_destroy);
    player_stop(player_to_destroy);
    player_unprepare(player_to_destroy);
    player_destroy(player_to_destroy);
  }

  if (texture_registrar_ && texture_id_ >= 0) {
    texture_registrar_->UnregisterTexture(texture_id_);
    texture_id_ = -1;
  }

  if (event_channel_) {
    event_channel_->SetStreamHandler(nullptr);
    event_channel_ = nullptr;
  }
  {
    std::lock_guard<std::mutex> lock(event_mutex_);
    event_sink_ = nullptr;
  }

  std::lock_guard<std::mutex> lock(buffer_mutex_);
  pixel_buffer_.clear();
}

}  // namespace better_player_tizen
