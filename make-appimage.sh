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

# Deploy real office6 binaries (/usr/bin/ stubs are 0-byte placeholders)
quick-sharun \
  /usr/lib/office6/wps \
  /usr/lib/office6/et \
  /usr/lib/office6/wpp \
  /usr/lib/office6/wpspdf \
  /usr/lib/office6/wpsd \
  /usr/lib/office6/promecefpluginhost \
  /usr/lib/office6/transerr

# Copy entire office6 tree into AppDir (resources, bundled libs, etc.)
cp -a /usr/lib/office6 "$APPDIR/usr/lib/office6"

# Disable background processes to prevent shutdown crashes
chmod -x "$APPDIR/usr/lib/office6/wpscloudsvr" 2>/dev/null || true
chmod -x "$APPDIR/usr/lib/office6/wpsoffice" 2>/dev/null || true

# Create wrapper scripts that call the real office6 binaries directly
for bin in wps et wpp wpspdf; do
  cat > "$APPDIR/bin/$bin" << 'WRAPPER'
#!/bin/sh
APPDIR="${APPDIR:-$(dirname "$(dirname "$(readlink -f "$0")")")}"
export LD_LIBRARY_PATH="$APPDIR/usr/lib/office6${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$APPDIR/usr/lib/office6/$(basename "$0")" "$@"
WRAPPER
  chmod +x "$APPDIR/bin/$bin"
done

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
