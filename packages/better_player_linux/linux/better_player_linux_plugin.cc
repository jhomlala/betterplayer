#include "include/better_player_linux/better_player_linux_plugin.h"
#include "better_player_linux_plugin_private.h"
#include "texture_bridge.h"

#include <cstring>
#include <map>
#include <memory>
#include <mutex>

struct _BetterPlayerLinuxPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(BetterPlayerLinuxPlugin, better_player_linux_plugin, g_object_get_type())

static std::mutex g_players_mutex;
static std::map<int64_t, std::unique_ptr<better_player_linux::TextureBridge>> g_players;

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  BetterPlayerLinuxPlugin* plugin = BETTER_PLAYER_LINUX_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "create") == 0) {
    auto bridge = std::make_unique<better_player_linux::TextureBridge>(
        fl_plugin_registrar_get_texture_registrar(plugin->registrar));
    if (!bridge->Initialize()) {
      fl_method_call_respond_error(
          method_call, "CREATION_FAILED",
          "Failed to initialize texture bridge and mpv context: libmpv.so not found, see README.",
          nullptr, nullptr);
      return;
    }

    int64_t texture_id = bridge->GetTextureId();
    int64_t mpv_handle = reinterpret_cast<int64_t>(bridge->GetMpvHandle());

    {
      std::lock_guard<std::mutex> lock(g_players_mutex);
      g_players[texture_id] = std::move(bridge);
    }

    g_autoptr(FlValue) response = fl_value_new_map();
    fl_value_set_string_take(response, "textureId", fl_value_new_int(texture_id));
    fl_value_set_string_take(response, "mpvHandle", fl_value_new_int(mpv_handle));

    fl_method_call_respond_success(method_call, response, nullptr);
  } else if (strcmp(method, "dispose") == 0) {
    if (!args || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      fl_method_call_respond_error(method_call, "BAD_ARGS", "Expected map arguments for dispose", nullptr, nullptr);
      return;
    }

    FlValue* texture_id_value = fl_value_lookup_string(args, "textureId");
    if (!texture_id_value || fl_value_get_type(texture_id_value) != FL_VALUE_TYPE_INT) {
      fl_method_call_respond_error(method_call, "BAD_ARGS", "Missing textureId argument for dispose", nullptr, nullptr);
      return;
    }

    int64_t texture_id = fl_value_get_int(texture_id_value);
    std::unique_ptr<better_player_linux::TextureBridge> player_to_destroy;
    {
      std::lock_guard<std::mutex> lock(g_players_mutex);
      auto it = g_players.find(texture_id);
      if (it != g_players.end()) {
        player_to_destroy = std::move(it->second);
        g_players.erase(it);
      }
    }

    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "clear") == 0) {
    std::map<int64_t, std::unique_ptr<better_player_linux::TextureBridge>> players_to_clear;
    {
      std::lock_guard<std::mutex> lock(g_players_mutex);
      players_to_clear = std::move(g_players);
    }
    players_to_clear.clear();
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

static void better_player_linux_plugin_dispose(GObject* object) {
  BetterPlayerLinuxPlugin* self = BETTER_PLAYER_LINUX_PLUGIN(object);
  g_clear_object(&self->registrar);
  g_clear_object(&self->channel);
  G_OBJECT_CLASS(better_player_linux_plugin_parent_class)->dispose(object);
}

static void better_player_linux_plugin_class_init(BetterPlayerLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = better_player_linux_plugin_dispose;
}

static void better_player_linux_plugin_init(BetterPlayerLinuxPlugin* self) {
  self->registrar = nullptr;
  self->channel = nullptr;
}

void better_player_linux_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  BetterPlayerLinuxPlugin* plugin = BETTER_PLAYER_LINUX_PLUGIN(
      g_object_new(better_player_linux_plugin_get_type(), nullptr));

  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "better_player_linux",
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
