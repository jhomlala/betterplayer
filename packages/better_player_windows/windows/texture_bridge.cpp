#include "texture_bridge.h"

#include <iostream>
#include <windows.h>

namespace better_player_windows {

// Function pointer types for dynamic loading from mpv-2.dll
typedef mpv_handle* (*fn_mpv_create)();
typedef int (*fn_mpv_initialize)(mpv_handle*);
typedef void (*fn_mpv_destroy)(mpv_handle*);
typedef int (*fn_mpv_set_option_string)(mpv_handle*, const char*, const char*);
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

  // 1. Create D3D11 Device and Context
  D3D_FEATURE_LEVEL feature_levels[] = {
      D3D_FEATURE_LEVEL_11_1,
      D3D_FEATURE_LEVEL_11_0,
  };
  D3D_FEATURE_LEVEL feature_level;

  HRESULT hr = D3D11CreateDevice(
      nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr,
      D3D11_CREATE_DEVICE_BGRA_SUPPORT, feature_levels,
      ARRAYSIZE(feature_levels), D3D11_SDK_VERSION, &d3d11_device_,
      &feature_level, &d3d11_context_);

  if (FAILED(hr)) {
    // Fallback to WARP software renderer if hardware device creation fails
    hr = D3D11CreateDevice(
        nullptr, D3D_DRIVER_TYPE_WARP, nullptr,
        D3D11_CREATE_DEVICE_BGRA_SUPPORT, feature_levels,
        ARRAYSIZE(feature_levels), D3D11_SDK_VERSION, &d3d11_device_,
        &feature_level, &d3d11_context_);
    if (FAILED(hr)) {
      return false;
    }
  }

  // 2. Initialize mpv instance
  mpv_ = g_mpv.create();
  if (!mpv_) {
    return false;
  }

  g_mpv.set_option_string(mpv_, "vo", "libmpv");
  g_mpv.set_option_string(mpv_, "hwdec", "auto-safe");
  g_mpv.set_option_string(mpv_, "keep-open", "yes");
  g_mpv.set_option_string(mpv_, "ao", "wasapi,null");
  g_mpv.set_option_string(mpv_, "audio-fallback-to-null", "yes");

  if (g_mpv.initialize(mpv_) < 0) {
    g_mpv.destroy(mpv_);
    mpv_ = nullptr;
    return false;
  }

  // 3. Setup Texture Variant with GpuSurfaceTexture
  texture_variant_ = std::make_unique<flutter::TextureVariant>(
      flutter::GpuSurfaceTexture(
          kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
          [this](size_t width, size_t height) {
            return ObtainDescriptor(width, height);
          }));

  texture_id_ = texture_registrar_->RegisterTexture(texture_variant_.get());

  // 4. Setup mpv render context
  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_API_TYPE, const_cast<char*>("dxgi")},
      {MPV_RENDER_PARAM_DXGI_INIT_PARAMS, d3d11_device_.Get()},
      {MPV_RENDER_PARAM_INVALID, nullptr},
  };

  if (g_mpv.render_context_create(&mpv_render_, mpv_, params) < 0) {
    mpv_render_ = nullptr;
  } else if (g_mpv.render_context_set_update_callback) {
    g_mpv.render_context_set_update_callback(mpv_render_, OnMpvUpdate, this);
  }

  return true;
}

void TextureBridge::OnMpvUpdate(void* ctx) {
  auto* self = static_cast<TextureBridge*>(ctx);
  if (self && !self->is_disposed_ && self->texture_registrar_ && self->texture_id_ >= 0) {
    self->texture_registrar_->MarkTextureFrameAvailable(self->texture_id_);
  }
}

const FlutterDesktopGpuSurfaceDescriptor* TextureBridge::ObtainDescriptor(size_t width, size_t height) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (is_disposed_ || !d3d11_device_) {
    return nullptr;
  }

  if (width == 0 || height == 0) {
    width = 1;
    height = 1;
  }

  // Recreate D3D11 texture if dimensions changed
  if (!texture_ || gpu_surface_descriptor_.width != width || gpu_surface_descriptor_.height != height) {
    D3D11_TEXTURE2D_DESC desc = {};
    desc.Width = static_cast<UINT>(width);
    desc.Height = static_cast<UINT>(height);
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.Usage = D3D11_USAGE_DEFAULT;
    desc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
    desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED;

    HRESULT hr = d3d11_device_->CreateTexture2D(&desc, nullptr, &texture_);
    if (FAILED(hr)) {
      return nullptr;
    }

    Microsoft::WRL::ComPtr<IDXGIResource> dxgi_resource;
    hr = texture_.As(&dxgi_resource);
    if (SUCCEEDED(hr)) {
      dxgi_resource->GetSharedHandle(&shared_handle_);
    }

    gpu_surface_descriptor_.struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
    gpu_surface_descriptor_.handle = shared_handle_;
    gpu_surface_descriptor_.width = width;
    gpu_surface_descriptor_.height = height;
    gpu_surface_descriptor_.visible_width = width;
    gpu_surface_descriptor_.visible_height = height;
    gpu_surface_descriptor_.release_callback = nullptr;
    gpu_surface_descriptor_.release_context = nullptr;
  }

  // Render mpv frame into D3D11 render target if render context is active
  if (mpv_render_ && g_mpv.render_context_render) {
    mpv_render_param render_params[] = {
        {MPV_RENDER_PARAM_INVALID, nullptr},
    };
    g_mpv.render_context_render(mpv_render_, render_params);
    if (g_mpv.render_context_report_swap) {
      g_mpv.render_context_report_swap(mpv_render_);
    }
  }

  return &gpu_surface_descriptor_;
}

void TextureBridge::Dispose() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (is_disposed_) return;
  is_disposed_ = true;

  if (mpv_render_ && g_mpv.render_context_free) {
    g_mpv.render_context_free(mpv_render_);
    mpv_render_ = nullptr;
  }

  if (mpv_ && g_mpv.destroy) {
    g_mpv.destroy(mpv_);
    mpv_ = nullptr;
  }

  if (texture_id_ >= 0 && texture_registrar_) {
    texture_registrar_->UnregisterTexture(texture_id_);
    texture_id_ = -1;
  }

  texture_.Reset();
  d3d11_context_.Reset();
  d3d11_device_.Reset();
}

}  // namespace better_player_windows
