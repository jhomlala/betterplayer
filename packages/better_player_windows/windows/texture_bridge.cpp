#include "texture_bridge.h"

#include <algorithm>
#include <iostream>
#include <windows.h>

namespace better_player_windows {

// Function pointer types for dynamic loading from mpv-2.dll
typedef mpv_handle* (*fn_mpv_create)();
typedef int (*fn_mpv_initialize)(mpv_handle*);
typedef void (*fn_mpv_destroy)(mpv_handle*);
typedef int (*fn_mpv_set_option_string)(mpv_handle*, const char*, const char*);
typedef int (*fn_mpv_get_property)(mpv_handle*, const char*, mpv_format, void*);
typedef int (*fn_mpv_render_context_create)(mpv_render_context**, mpv_handle*, mpv_render_param*);
typedef void (*fn_mpv_render_context_set_update_callback)(mpv_render_context*, mpv_render_update_fn, void*);
typedef int (*fn_mpv_render_context_render)(mpv_render_context*, mpv_render_param*);
typedef void (*fn_mpv_render_context_report_swap)(mpv_render_context*);
typedef void (*fn_mpv_render_context_free)(mpv_render_context*);

struct MpvFunctions {
  HMODULE module = nullptr;
  fn_mpv_create create = nullptr;
  fn_mpv_initialize initialize = nullptr;
  fn_mpv_destroy destroy = nullptr;
  fn_mpv_set_option_string set_option_string = nullptr;
  fn_mpv_get_property get_property = nullptr;
  fn_mpv_render_context_create render_context_create = nullptr;
  fn_mpv_render_context_set_update_callback render_context_set_update_callback = nullptr;
  fn_mpv_render_context_render render_context_render = nullptr;
  fn_mpv_render_context_report_swap render_context_report_swap = nullptr;
  fn_mpv_render_context_free render_context_free = nullptr;

  bool Load() {
    if (module) return true;
    module = LoadLibraryA("mpv-2.dll");
    if (!module) {
      module = LoadLibraryA("libmpv-2.dll");
    }
    if (!module) return false;

    create = (fn_mpv_create)GetProcAddress(module, "mpv_create");
    initialize = (fn_mpv_initialize)GetProcAddress(module, "mpv_initialize");
    destroy = (fn_mpv_destroy)GetProcAddress(module, "mpv_destroy");
    set_option_string = (fn_mpv_set_option_string)GetProcAddress(module, "mpv_set_option_string");
    get_property = (fn_mpv_get_property)GetProcAddress(module, "mpv_get_property");
    render_context_create = (fn_mpv_render_context_create)GetProcAddress(module, "mpv_render_context_create");
    render_context_set_update_callback = (fn_mpv_render_context_set_update_callback)GetProcAddress(module, "mpv_render_context_set_update_callback");
    render_context_render = (fn_mpv_render_context_render)GetProcAddress(module, "mpv_render_context_render");
    render_context_report_swap = (fn_mpv_render_context_report_swap)GetProcAddress(module, "mpv_render_context_report_swap");
    render_context_free = (fn_mpv_render_context_free)GetProcAddress(module, "mpv_render_context_free");

    return create && initialize && destroy && set_option_string &&
           render_context_create && render_context_render && render_context_free;
  }
};

static MpvFunctions g_mpv;

TextureBridge::TextureBridge(flutter::TextureRegistrar* texture_registrar)
    : texture_registrar_(texture_registrar) {}

TextureBridge::~TextureBridge() {
  Dispose();
}

bool TextureBridge::Initialize() {
  std::lock_guard<std::mutex> lock(mutex_);

  if (!g_mpv.Load()) {
    std::cerr << "[BetterPlayerWindows] Could not load mpv-2.dll. Ensure mpv-2.dll is in the application folder." << std::endl;
    return false;
  }

  // 1. Initialize mpv instance
  mpv_ = g_mpv.create();
  if (!mpv_) {
    return false;
  }

  g_mpv.set_option_string(mpv_, "vo", "libmpv");
  g_mpv.set_option_string(mpv_, "keep-open", "yes");
  g_mpv.set_option_string(mpv_, "ao", "wasapi,null");
  g_mpv.set_option_string(mpv_, "audio-fallback-to-null", "yes");

  if (g_mpv.initialize(mpv_) < 0) {
    g_mpv.destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  // 2. Setup mpv render context with software renderer
  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_API_TYPE, const_cast<char*>(MPV_RENDER_API_TYPE_SW)},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };

  int res = g_mpv.render_context_create(&mpv_render_, mpv_, params);
  if (res < 0) {
    std::cerr << "[BetterPlayerWindows] mpv_render_context_create failed: " << res << std::endl;
    mpv_render_ = nullptr;
    g_mpv.destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  if (g_mpv.render_context_set_update_callback) {
    g_mpv.render_context_set_update_callback(mpv_render_, OnMpvUpdate, this);
  }

  // 3. Setup Texture Variant with PixelBufferTexture
  texture_variant_ = std::make_unique<flutter::TextureVariant>(
      flutter::PixelBufferTexture(
          [this](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
            return CopyPixelBuffer(width, height);
          }));

  texture_id_ = texture_registrar_->RegisterTexture(texture_variant_.get());

  return true;
}

void TextureBridge::OnMpvUpdate(void* ctx) {
  auto* self = static_cast<TextureBridge*>(ctx);
  if (self && !self->is_disposed_.load() && self->texture_registrar_ && self->texture_id_ >= 0) {
    self->texture_registrar_->MarkTextureFrameAvailable(self->texture_id_);
  }
}

const FlutterDesktopPixelBuffer* TextureBridge::CopyPixelBuffer(size_t width, size_t height) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (is_disposed_.load() || !mpv_render_) {
    return nullptr;
  }

  if (width == 0 || height == 0) {
    int64_t dw = 0, dh = 0;
    if (mpv_ && g_mpv.get_property) {
      g_mpv.get_property(mpv_, "dwidth", MPV_FORMAT_INT64, &dw);
      g_mpv.get_property(mpv_, "dheight", MPV_FORMAT_INT64, &dh);
    }
    width = dw > 0 ? static_cast<size_t>(dw) : 1280;
    height = dh > 0 ? static_cast<size_t>(dh) : 720;
  }

  size_t required_bytes = width * height * 4;
  if (pixel_buffer_.size() != required_bytes) {
    pixel_buffer_.resize(required_bytes, 0);
  }

  int32_t size[2] = {static_cast<int32_t>(width), static_cast<int32_t>(height)};
  size_t stride = width * 4;
  char format[] = "rgb0";
  mpv_render_param render_params[] = {
      {MPV_RENDER_PARAM_SW_SIZE, size},
      {MPV_RENDER_PARAM_SW_FORMAT, format},
      {MPV_RENDER_PARAM_SW_STRIDE, &stride},
      {MPV_RENDER_PARAM_SW_POINTER, pixel_buffer_.data()},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };

  g_mpv.render_context_render(mpv_render_, render_params);

  desktop_pixel_buffer_.buffer = pixel_buffer_.data();
  desktop_pixel_buffer_.width = width;
  desktop_pixel_buffer_.height = height;
  desktop_pixel_buffer_.release_callback = nullptr;
  desktop_pixel_buffer_.release_context = nullptr;

  return &desktop_pixel_buffer_;
}

void TextureBridge::Dispose() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (is_disposed_.load()) return;
  is_disposed_.store(true);

  if (texture_id_ >= 0 && texture_registrar_) {
    texture_registrar_->UnregisterTexture(texture_id_);
    texture_id_ = -1;
  }

  if (mpv_render_ && g_mpv.render_context_free) {
    g_mpv.render_context_free(mpv_render_);
    mpv_render_ = nullptr;
  }

  if (mpv_ && g_mpv.destroy) {
    g_mpv.destroy(mpv_);
    mpv_ = nullptr;
  }

  pixel_buffer_.clear();
}

}  // namespace better_player_windows
