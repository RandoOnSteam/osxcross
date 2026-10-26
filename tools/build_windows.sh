#!/bin/sh
set -e
cd "$(dirname "$0")/.."
export PATH="/usr/bin:/ucrt64/bin:$PATH"
export CC="clang --target=x86_64-pc-cygwin --sysroot=/ -D_GNU_SOURCE"
export CXX="clang++ --target=x86_64-pc-cygwin --sysroot=/ -D_GNU_SOURCE"
export CONFIG_SITE="$(pwd)/tools/config.site.msys"
export SDK_VERSION="$1"
export BUILD_FLAVOR="$2"
export TARGET_DIR="$3"
export BUILD_DIR="$4"
export UNATTENDED=1
export MSYS=winsymlinks:native
rm -f "$TARGET_DIR/bin/ld"
for library in "$TARGET_DIR"/bin/*.dll; do
  if [ -f "/usr/bin/${library##*/}" ]; then
    rm -f "$library"
  fi
done
./build.sh
links=$(find "$TARGET_DIR/bin" -maxdepth 1 -type l ! -name '*.exe')
for link in $links; do
  target=$(readlink "$link") || continue
  case "$link:$target" in
    *.exe:*) ;;
    *:/*) ;;
    *:*.exe)
      rm -f "$link"
      ln -f "$TARGET_DIR/bin/$target" "$link.exe"
      ;;
  esac
done
for file in "$TARGET_DIR"/bin/*.exe; do
  ldd "$file" | awk '$3 ~ /^\/usr\/bin\// { print $3 }'
done | sort -u | while read -r library; do
  cp -f "$library" "$TARGET_DIR/bin/"
done
linker=$(cd "$TARGET_DIR/bin" && ls *-apple-darwin*-ld.exe | head -n 1)
(cd "$TARGET_DIR/bin" && MSYS2_ARG_CONV_EXCL='*' cmd /c mklink /H ld "$linker" > /dev/null)
hostroot=$(cygpath -m /ucrt64)
hostroot=${hostroot// /\\040}
mkdir -p "$TARGET_DIR/../etc"
{
  echo "none / cygdrive binary,posix=0,noacl,user 0 0"
  echo "none /tmp usertemp binary,posix=0,noacl 0 0"
  echo "$hostroot /ucrt64 ntfs binary,noacl,auto 0 0"
} > "$TARGET_DIR/../etc/fstab"
