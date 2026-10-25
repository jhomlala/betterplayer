#ifndef BETTER_PLAYER_LINUX_TEXTURE_BRIDGE_H_
#define BETTER_PLAYER_LINUX_TEXTURE_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <vector>

#include "include/mpv/client.h"
#include "include/mpv/render.h"

namespace better_player_linux {

class TextureBridge {
 public:
  explicit TextureBridge(FlTextureRegistrar* texture_registrar);
  ~TextureBridge();

  TextureBridge(const TextureBridge&) = delete;
  TextureBridge& operator=(const TextureBridge&) = delete;

  bool Initialize();
  void Dispose();

  int64_t GetTextureId() const { return texture_id_; }
  mpv_handle* GetMpvHandle() const { return mpv_; }

  gboolean CopyPixels(const uint8_t** out_buffer, uint32_t* width, uint32_t* height);

 private:
  static void OnMpvUpdate(void* ctx);

  FlTextureRegistrar* texture_registrar_ = nullptr;
  void* fl_texture_ = nullptr;  // Pointer to BetterPlayerTexture GObject
  int64_t texture_id_ = -1;

  mpv_handle* mpv_ = nullptr;
  mpv_render_context* mpv_render_ = nullptr;

  std::vector<uint8_t> pixel_buffer_;
  std::mutex mutex_;
  std::atomic<bool> is_disposed_{false};
};

}  // namespace better_player_linux

#endif  // BETTER_PLAYER_LINUX_TEXTURE_BRIDGE_H_
