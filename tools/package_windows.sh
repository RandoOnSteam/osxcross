#!/bin/sh
set -e
tools=$(cd "$(dirname "$0")" && pwd)
target="$1"
stage="$2"
flavor="$3"
excluded=
if [ "$flavor" = public ]; then
  excluded=SDK
fi
rm -rf "$stage"
mkdir -p "$stage/etc" "$stage/ucrt64/bin" "$stage/ucrt64/lib/clang"
for version in "$target"/*; do
  case "${version##*/}" in
    etc) ;;
    *) python3 "$tools/copy_resolved.py" "$version" "$stage/${version##*/}" $excluded ;;
  esac
done
{
  echo "none / cygdrive binary,posix=0,noacl,user 0 0"
  echo "none /tmp usertemp binary,posix=0,noacl 0 0"
} > "$stage/etc/fstab"
cp -f /ucrt64/bin/clang.exe /ucrt64/bin/clang++.exe "$stage/ucrt64/bin/"
cp -rL /ucrt64/lib/clang/* "$stage/ucrt64/lib/clang/"
ldd /ucrt64/bin/clang.exe | awk '$3 ~ /^\/ucrt64\/bin\// { print $3 }' | while read -r library; do
  cp -f "$library" "$stage/ucrt64/bin/"
done
if [ "$flavor" = public ]; then
  mkdir -p "$stage/share/osxcross/quirks"
  cp -f "$tools/../oclang/quirks/"*.h "$stage/share/osxcross/quirks/"
  cp -f "$tools/install-sdk.cmake" "$stage/"
  cp -f "$tools/README.windows.txt" "$stage/README.txt"
  cp -f "$tools/../COPYING" "$stage/COPYING.osxcross"
  for version in "$stage"/*/bin; do
    mkdir -p "${version%/bin}/SDK"
  done
fi
