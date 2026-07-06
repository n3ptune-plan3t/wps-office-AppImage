#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q wps-office | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export APPDIR="${APPDIR:-$PWD/AppDir}"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

# Force English environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Handle icon (must be before quick-sharun, which calls _get_icon)
PRIMARY_ICON=$(ls /usr/share/icons/hicolor/256x256/mimetypes/wps-office2019-wpsmain.png 2>/dev/null | head -n 1)
if [ -z "$PRIMARY_ICON" ]; then
    PRIMARY_ICON=$(ls /usr/share/icons/hicolor/*/apps/wps-office-kingsoft.png 2>/dev/null | head -n 1)
fi
if [ -z "$PRIMARY_ICON" ]; then
    PRIMARY_ICON=$(ls /usr/share/icons/hicolor/*/apps/wps-office*.png 2>/dev/null | head -n 1)
fi
if [ -n "$PRIMARY_ICON" ] && [ -f "$PRIMARY_ICON" ]; then
    export ICON="$PRIMARY_ICON"
fi

# Handle desktop file (must be before quick-sharun, which calls _get_desktop)
PRIMARY_DESKTOP=$(ls /usr/share/applications/wps-office-wps.desktop 2>/dev/null | head -n 1)
if [ -z "$PRIMARY_DESKTOP" ]; then
    PRIMARY_DESKTOP=$(ls /usr/share/applications/wps-office*.desktop 2>/dev/null | head -n 1)
fi
if [ -n "$PRIMARY_DESKTOP" ] && [ -f "$PRIMARY_DESKTOP" ]; then
    export DESKTOP="$PRIMARY_DESKTOP"
fi

# Deploy office6 ELF binaries for library dependency resolution only
quick-sharun \
  /usr/lib/office6/wps \
  /usr/lib/office6/et \
  /usr/lib/office6/wpp \
  /usr/lib/office6/wpspdf \
  /usr/lib/office6/wpsd \
  /usr/lib/office6/promecefpluginhost \
  /usr/lib/office6/transerr

# Copy entire office6 tree into AppDir (resources, bundled libs, etc.)
mkdir -p "$APPDIR/usr/lib"
cp -a /usr/lib/office6 "$APPDIR/usr/lib/office6"

# Disable background processes to prevent shutdown crashes
chmod -x "$APPDIR/usr/lib/office6/wpscloudsvr" 2>/dev/null || true
chmod -x "$APPDIR/usr/lib/office6/wpsoffice" 2>/dev/null || true

# Deploy WPS launcher scripts from /usr/bin/ (they contain env setup like
# gApp, gOptExt, etc.) and patch them to find office6 inside the AppDir
for bin in wps et wpp wpspdf; do
  rm -f "$APPDIR/bin/$bin"
  cp /usr/bin/"$bin" "$APPDIR/bin/$bin"
  chmod +x "$APPDIR/bin/$bin"
  # Replace hardcoded /usr/lib/office6 with AppDir-relative path
  sed -i "s|/usr/lib/office6|\${APPDIR}/usr/lib/office6|g" "$APPDIR/bin/$bin"
done

# Rename Name= in the primary desktop file so the AppImage is named
# WPS_Office instead of WPS_Writer (all components are bundled)
sed -i 's/^Name=.*/Name=WPS Office/' "$APPDIR"/*.desktop

# Copy all desktop files for desktop integration
mkdir -p "$APPDIR/usr/share/applications"
cp /usr/share/applications/wps-office-*.desktop "$APPDIR/usr/share/applications/" 2>/dev/null || true

# Copy icons for all components
if [ -d /usr/share/icons/hicolor ]; then
    mkdir -p "$APPDIR/usr/share/icons"
    cp -a /usr/share/icons/hicolor "$APPDIR/usr/share/icons/"
fi

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds
quick-sharun --test ./dist/*.AppImage
