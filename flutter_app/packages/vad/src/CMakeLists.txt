# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(vad_library VERSION 0.0.1 LANGUAGES C)

add_library(vad SHARED
  "vad.c"
)

set_target_properties(vad PROPERTIES
  PUBLIC_HEADER vad.h
  OUTPUT_NAME "vad"
)

target_compile_definitions(vad PUBLIC DART_SHARED_LIB)
