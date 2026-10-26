cmake_minimum_required(VERSION 3.20)
project(osxcross NONE)

if(NOT CMAKE_HOST_WIN32)
  message(FATAL_ERROR "This CMake build is for Windows hosts. Use ./build.sh elsewhere.")
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/MSYS2.cmake)

set(OSXCROSS_SDK_VERSIONS "10.6;10.13;10.14" CACHE STRING "SDK versions to build, each from tarballs/MacOSX<version>.sdk.tar.xz")
set(OSXCROSS_BUILD_FLAVOR "stable" CACHE STRING "osxcross build flavor: stable, latest or llvm")
set(OSXCROSS_TARGET_ROOT "${CMAKE_SOURCE_DIR}/target" CACHE PATH "Each SDK is installed to <root>/<version>")

msys2_bootstrap(
  base-devel git cmake gcc python
  libxml2-devel openssl-devel zlib-devel liblzma-devel libbz2-devel
  mingw-w64-ucrt-x86_64-clang
  mingw-w64-ucrt-x86_64-lld
  mingw-w64-ucrt-x86_64-llvm-tools)

set(toolchains)
foreach(version IN LISTS OSXCROSS_SDK_VERSIONS)
  set(target "${OSXCROSS_TARGET_ROOT}/${version}")
  set(stamp "${CMAKE_BINARY_DIR}/osxcross-${version}.stamp")
  add_custom_command(
    OUTPUT "${stamp}"
    COMMAND ${CMAKE_COMMAND} -E env
      MSYSTEM=MSYS CHERE_INVOKING=1 MSYS2_PATH_TYPE=minimal
      "${MSYS2_ROOT}/usr/bin/bash.exe" -lc
      "sh '${CMAKE_SOURCE_DIR}/tools/build_windows.sh' '${version}' '${OSXCROSS_BUILD_FLAVOR}' \"$(cygpath -u '${target}')\" \"$(cygpath -u '${CMAKE_BINARY_DIR}/work-${version}')\""
    COMMAND ${CMAKE_COMMAND} -E touch "${stamp}"
    DEPENDS "${CMAKE_SOURCE_DIR}/tarballs/MacOSX${version}.sdk.tar.xz"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    USES_TERMINAL
    VERBATIM)
  add_custom_target(osxcross-${version} DEPENDS "${stamp}")
  list(APPEND toolchains osxcross-${version})
endforeach()

add_custom_target(osxcross ALL)
add_dependencies(osxcross ${toolchains})
