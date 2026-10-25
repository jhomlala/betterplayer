#ifndef FLUTTER_PLUGIN_BETTER_PLAYER_LINUX_PLUGIN_H_
#define FLUTTER_PLUGIN_BETTER_PLAYER_LINUX_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

G_DECLARE_FINAL_TYPE(BetterPlayerLinuxPlugin, better_player_linux_plugin,
                     BETTER_PLAYER, LINUX_PLUGIN, GObject)

#ifndef BETTER_PLAYER_LINUX_PLUGIN
#define BETTER_PLAYER_LINUX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), better_player_linux_plugin_get_type(), BetterPlayerLinuxPlugin))
#endif

FLUTTER_PLUGIN_EXPORT void better_player_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_BETTER_PLAYER_LINUX_PLUGIN_H_
