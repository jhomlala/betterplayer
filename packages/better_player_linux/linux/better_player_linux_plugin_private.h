#ifndef BETTER_PLAYER_LINUX_PLUGIN_PRIVATE_H_
#define BETTER_PLAYER_LINUX_PLUGIN_PRIVATE_H_

#include <flutter_linux/flutter_linux.h>

#include "include/better_player_linux/better_player_linux_plugin.h"

// Dispatches a method call to the plugin implementation.
FlMethodResponse* better_player_linux_plugin_handle_method_call(
    BetterPlayerLinuxPlugin* self,
    FlMethodCall* method_call);

#endif  // BETTER_PLAYER_LINUX_PLUGIN_PRIVATE_H_
