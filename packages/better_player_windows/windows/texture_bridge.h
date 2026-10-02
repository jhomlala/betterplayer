#ifndef BETTER_PLAYER_WINDOWS_TEXTURE_BRIDGE_H_
#define BETTER_PLAYER_WINDOWS_TEXTURE_BRIDGE_H_

#include <flutter/texture_registrar.h>
#include <memory>
#include <mutex>
#include <vector>

#include "include/mpv/client.h"
#include "include/mpv/render.h"

namespace better_player_windows {

class TextureBridge {
 public:
  explicit TextureBridge(flutter::TextureRegistrar* texture_registrar);
  ~TextureBridge();

  bool Initialize();
  void Dispose();

  int64_t GetTextureId() const { return texture_id_; }
  mpv_handle* GetMpvHandle() const { return mpv_; }

 private:
  static void OnMpvUpdate(void* ctx);
  const FlutterDesktopPixelBuffer* CopyPixelBuffer(size_t width, size_t height);

  flutter::TextureRegistrar* texture_registrar_ = nullptr;
  int64_t texture_id_ = -1;
  std::unique_ptr<flutter::TextureVariant> texture_variant_;

  mpv_handle* mpv_ = nullptr;
  mpv_render_context* mpv_render_ = nullptr;

  std::vector<uint8_t> pixel_buffer_;
  FlutterDesktopPixelBuffer desktop_pixel_buffer_{};

  std::mutex mutex_;
  bool is_disposed_ = false;
};

}  // namespace better_player_windows

#endif  // BETTER_PLAYER_WINDOWS_TEXTURE_BRIDGE_H_
