cmake_minimum_required(VERSION 3.10)
project(better_player_linux LANGUAGES C CXX)

set(PLUGIN_NAME better_player_linux_plugin)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

add_library(${PLUGIN_NAME} SHARED
  "better_player_linux_plugin.cc"
  "texture_bridge.cc"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET "hidden"
  VISIBILITY_INLINES_HIDDEN YES
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  PkgConfig::GTK
  ${CMAKE_DL_LIBS}
)
