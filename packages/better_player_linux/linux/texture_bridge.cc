#include "texture_bridge.h"

#include <dlfcn.h>
#include <algorithm>
#include <iostream>

namespace better_player_linux {

// Function pointer types for dynamic loading from libmpv.so
typedef mpv_handle* (*fn_mpv_create)();
typedef int (*fn_mpv_initialize)(mpv_handle*);
typedef void (*fn_mpv_destroy)(mpv_handle*);
typedef int (*fn_mpv_set_option_string)(mpv_handle*, const char*, const char*);
typedef int (*fn_mpv_get_property)(mpv_handle*, const char*, mpv_format, void*);
typedef int (*fn_mpv_render_context_create)(mpv_render_context**, mpv_handle*, mpv_render_param*);
typedef void (*fn_mpv_render_context_set_update_callback)(mpv_render_context*, mpv_render_update_fn, void*);
typedef int (*fn_mpv_render_context_render)(mpv_render_context*, mpv_render_param*);
typedef void (*fn_mpv_render_context_free)(mpv_render_context*);

struct MpvFunctions {
  void* module = nullptr;
  fn_mpv_create create = nullptr;
  fn_mpv_initialize initialize = nullptr;
  fn_mpv_destroy destroy = nullptr;
  fn_mpv_set_option_string set_option_string = nullptr;
  fn_mpv_get_property get_property = nullptr;
  fn_mpv_render_context_create render_context_create = nullptr;
  fn_mpv_render_context_set_update_callback render_context_set_update_callback = nullptr;
  fn_mpv_render_context_render render_context_render = nullptr;
  fn_mpv_render_context_free render_context_free = nullptr;

  bool Load() {
    if (module) return true;
    const char* candidates[] = {"libmpv.so.2", "libmpv.so.1", "libmpv.so"};
    for (const char* name : candidates) {
      module = dlopen(name, RTLD_LAZY);
      if (module) break;
    }
    if (!module) return false;

    create = (fn_mpv_create)dlsym(module, "mpv_create");
    initialize = (fn_mpv_initialize)dlsym(module, "mpv_initialize");
    destroy = (fn_mpv_destroy)dlsym(module, "mpv_destroy");
    set_option_string = (fn_mpv_set_option_string)dlsym(module, "mpv_set_option_string");
    get_property = (fn_mpv_get_property)dlsym(module, "mpv_get_property");
    render_context_create = (fn_mpv_render_context_create)dlsym(module, "mpv_render_context_create");
    render_context_set_update_callback =
        (fn_mpv_render_context_set_update_callback)dlsym(module, "mpv_render_context_set_update_callback");
    render_context_render = (fn_mpv_render_context_render)dlsym(module, "mpv_render_context_render");
    render_context_free = (fn_mpv_render_context_free)dlsym(module, "mpv_render_context_free");

    return create && initialize && destroy && set_option_string &&
           render_context_create && render_context_render && render_context_free;
  }
};

static MpvFunctions g_mpv;

}  // namespace better_player_linux

// GObject subclass of FlPixelBufferTexture
struct _BetterPlayerTexture {
  FlPixelBufferTexture parent_instance;
  better_player_linux::TextureBridge* bridge;
};

G_DECLARE_FINAL_TYPE(BetterPlayerTexture,
                     better_player_texture,
                     BETTER_PLAYER,
                     TEXTURE,
                     FlPixelBufferTexture)

#ifndef BETTER_PLAYER_TEXTURE
#define BETTER_PLAYER_TEXTURE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), better_player_texture_get_type(), BetterPlayerTexture))
#endif

G_DEFINE_TYPE(BetterPlayerTexture, better_player_texture, fl_pixel_buffer_texture_get_type())

static gboolean better_player_texture_copy_pixels(
    FlPixelBufferTexture* texture,
    const uint8_t** out_buffer,
    uint32_t* width,
    uint32_t* height,
    GError** error) {
  auto* self = BETTER_PLAYER_TEXTURE(texture);
  if (!self->bridge) {
    return FALSE;
  }
  return self->bridge->CopyPixels(out_buffer, width, height);
}

static void better_player_texture_class_init(BetterPlayerTextureClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = better_player_texture_copy_pixels;
}

static void better_player_texture_init(BetterPlayerTexture* self) {
  self->bridge = nullptr;
}

namespace better_player_linux {

TextureBridge::TextureBridge(FlTextureRegistrar* texture_registrar)
    : texture_registrar_(texture_registrar) {}

TextureBridge::~TextureBridge() {
  Dispose();
}

bool TextureBridge::Initialize() {
  std::lock_guard<std::mutex> lock(mutex_);

  if (!g_mpv.Load()) {
    std::cerr << "[BetterPlayerLinux] Could not load libmpv.so. Ensure libmpv is installed via package manager." << std::endl;
    return false;
  }

  // 1. Initialize mpv instance
  mpv_ = g_mpv.create();
  if (!mpv_) {
    return false;
  }

  g_mpv.set_option_string(mpv_, "vo", "libmpv");
  g_mpv.set_option_string(mpv_, "keep-open", "yes");
  g_mpv.set_option_string(mpv_, "ao", "pulse,alsa,null");
  g_mpv.set_option_string(mpv_, "audio-fallback-to-null", "yes");
  g_mpv.set_option_string(mpv_, "hwdec", "auto-safe");

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
    std::cerr << "[BetterPlayerLinux] mpv_render_context_create failed: " << res << std::endl;
    mpv_render_ = nullptr;
    g_mpv.destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  if (g_mpv.render_context_set_update_callback) {
    g_mpv.render_context_set_update_callback(mpv_render_, OnMpvUpdate, this);
  }

  // 3. Setup GObject FlPixelBufferTexture
  auto* texture = BETTER_PLAYER_TEXTURE(g_object_new(better_player_texture_get_type(), nullptr));
  texture->bridge = this;
  fl_texture_ = texture;

  if (!fl_texture_registrar_register_texture(texture_registrar_, FL_TEXTURE(texture))) {
    std::cerr << "[BetterPlayerLinux] fl_texture_registrar_register_texture failed" << std::endl;
    g_object_unref(texture);
    fl_texture_ = nullptr;
    return false;
  }

  texture_id_ = fl_texture_get_id(FL_TEXTURE(texture));
  return true;
}

void TextureBridge::OnMpvUpdate(void* ctx) {
  auto* self = static_cast<TextureBridge*>(ctx);
  if (self && !self->is_disposed_.load() && self->texture_registrar_ && self->fl_texture_) {
    fl_texture_registrar_mark_texture_frame_available(
        self->texture_registrar_, FL_TEXTURE(self->fl_texture_));
  }
}

gboolean TextureBridge::CopyPixels(const uint8_t** out_buffer, uint32_t* width, uint32_t* height) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (is_disposed_.load() || !mpv_render_) {
    return FALSE;
  }

  size_t w = *width;
  size_t h = *height;

  if (w == 0 || h == 0) {
    int64_t dw = 0, dh = 0;
    if (mpv_ && g_mpv.get_property) {
      g_mpv.get_property(mpv_, "dwidth", MPV_FORMAT_INT64, &dw);
      g_mpv.get_property(mpv_, "dheight", MPV_FORMAT_INT64, &dh);
    }
    w = dw > 0 ? static_cast<size_t>(dw) : 1280;
    h = dh > 0 ? static_cast<size_t>(dh) : 720;
  }

  size_t required_bytes = w * h * 4;
  if (pixel_buffer_.size() != required_bytes) {
    pixel_buffer_.resize(required_bytes, 0);
  }

  int32_t size[2] = {static_cast<int32_t>(w), static_cast<int32_t>(h)};
  size_t stride = w * 4;
  char format[] = "rgb0";
  mpv_render_param render_params[] = {
      {MPV_RENDER_PARAM_SW_SIZE, size},
      {MPV_RENDER_PARAM_SW_FORMAT, format},
      {MPV_RENDER_PARAM_SW_STRIDE, &stride},
      {MPV_RENDER_PARAM_SW_POINTER, pixel_buffer_.data()},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };

  g_mpv.render_context_render(mpv_render_, render_params);

  *out_buffer = pixel_buffer_.data();
  *width = static_cast<uint32_t>(w);
  *height = static_cast<uint32_t>(h);

  return TRUE;
}

void TextureBridge::Dispose() {
  FlPixelBufferTexture* texture_to_unregister = nullptr;
  FlTextureRegistrar* registrar = nullptr;

  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (is_disposed_.load()) return;
    is_disposed_.store(true);

    if (fl_texture_ && texture_registrar_) {
      texture_to_unregister = static_cast<FlPixelBufferTexture*>(fl_texture_);
      registrar = texture_registrar_;
      fl_texture_ = nullptr;
      texture_id_ = -1;
    }
  }

  // Unregister outside of mutex_ to avoid deadlocks with raster thread callbacks
  if (texture_to_unregister && registrar) {
    fl_texture_registrar_unregister_texture(registrar, FL_TEXTURE(texture_to_unregister));
    g_object_unref(texture_to_unregister);
  }

  std::lock_guard<std::mutex> lock(mutex_);
  if (mpv_render_) {
    if (g_mpv.render_context_set_update_callback) {
      g_mpv.render_context_set_update_callback(mpv_render_, nullptr, nullptr);
    }
    if (g_mpv.render_context_free) {
      g_mpv.render_context_free(mpv_render_);
    }
    mpv_render_ = nullptr;
  }

  if (mpv_ && g_mpv.destroy) {
    g_mpv.destroy(mpv_);
    mpv_ = nullptr;
  }

  pixel_buffer_.clear();
}

}  // namespace better_player_linux
