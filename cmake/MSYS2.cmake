set(MSYS2_VERSION "20260927" CACHE STRING "MSYS2 base archive date")
set(MSYS2_SHA256 "ea2f31a0b6ade63914ce441ffb022f0f6aa96982bfefa2326460a26d5fb01322" CACHE STRING "MSYS2 base archive SHA256")
set(MSYS2_ROOT "${CMAKE_BINARY_DIR}/msys64" CACHE PATH "MSYS2 installation used for the build")

function(msys2_run)
  execute_process(
    COMMAND "${MSYS2_ROOT}/usr/bin/bash.exe" -lc "${ARGV0}"
    RESULT_VARIABLE result)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "MSYS2 command failed (${result}): ${ARGV0}")
  endif()
endfunction()

function(msys2_bootstrap)
  set(ENV{MSYSTEM} "UCRT64")
  set(ENV{CHERE_INVOKING} "1")
  set(ENV{MSYS2_PATH_TYPE} "minimal")
  set(archive "${CMAKE_BINARY_DIR}/downloads/msys2-base-x86_64-${MSYS2_VERSION}.tar.xz")
  if(NOT EXISTS "${MSYS2_ROOT}/usr/bin/bash.exe")
    file(DOWNLOAD
      "https://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-${MSYS2_VERSION}.tar.xz"
      "${archive}"
      EXPECTED_HASH SHA256=${MSYS2_SHA256}
      SHOW_PROGRESS)
    get_filename_component(parent "${MSYS2_ROOT}" DIRECTORY)
    file(MAKE_DIRECTORY "${parent}/msys2-extract")
    file(ARCHIVE_EXTRACT INPUT "${archive}" DESTINATION "${parent}/msys2-extract")
    file(RENAME "${parent}/msys2-extract/msys64" "${MSYS2_ROOT}")
    file(REMOVE_RECURSE "${parent}/msys2-extract")
    msys2_run("true")
    msys2_run("pacman -Syuu --noconfirm --noprogressbar")
    msys2_run("pacman -Syuu --noconfirm --noprogressbar")
  endif()
  list(JOIN ARGN " " packages)
  string(SHA256 wanted "${packages}")
  set(stamp "${MSYS2_ROOT}/.packages-${wanted}")
  if(NOT EXISTS "${stamp}")
    msys2_run("pacman -S --needed --noconfirm --noprogressbar ${packages}")
    file(WRITE "${stamp}" "${packages}\n")
  endif()
endfunction()
