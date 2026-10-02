cmake_minimum_required(VERSION 3.14)
project(better_player_windows LANGUAGES CXX)

set(PLUGIN_NAME better_player_windows_plugin)

add_library(${PLUGIN_NAME} SHARED
  "better_player_windows_plugin.cpp"
  "better_player_windows_plugin.h"
  "texture_bridge.cpp"
  "texture_bridge.h"
  "include/better_player_windows/better_player_windows_plugin.h"
)

apply_standard_settings(${PLUGIN_NAME})

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE d3d11.lib dxgi.lib)

# Copy mpv-2.dll or libmpv-2.dll to the runtime output directory if present in libs
set(MPV_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libs")
if(EXISTS "${MPV_DIR}/mpv-2.dll")
  add_custom_command(TARGET ${PLUGIN_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${MPV_DIR}/mpv-2.dll"
      $<TARGET_FILE_DIR:${PLUGIN_NAME}>
  )
endif()
if(EXISTS "${MPV_DIR}/libmpv-2.dll")
  add_custom_command(TARGET ${PLUGIN_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${MPV_DIR}/libmpv-2.dll"
      $<TARGET_FILE_DIR:${PLUGIN_NAME}>
  )
endif()
