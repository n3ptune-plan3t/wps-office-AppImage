#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q wps-office | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export APPDIR="${APPDIR:-./AppDir}"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

# Force English environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# quick-sharun deploy needs a .desktop file in $APPDIR/
# Put a placeholder now; the component loop replaces it per-AppImage.
mkdir -p "$APPDIR"
cp /usr/share/applications/wps-office-wps.desktop "$APPDIR/"
export DESKTOP="$APPDIR/wps-office-wps.desktop"
ICON_SRC=$(ls /usr/share/icons/hicolor/*/apps/wps-office-wps.png 2>/dev/null | head -n 1)
if [ -n "$ICON_SRC" ]; then
    export ICON="$ICON_SRC"
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

# Copy all desktop files
mkdir -p "$APPDIR/usr/share/applications"
cp /usr/share/applications/wps-office-*.desktop "$APPDIR/usr/share/applications/" 2>/dev/null || true

# Copy icons for all components
if [ -d /usr/share/icons/hicolor ]; then
    mkdir -p "$APPDIR/usr/share/icons"
    cp -a /usr/share/icons/hicolor "$APPDIR/usr/share/icons/"
fi

# Save the base AppDir (shared deps + office6 tree) for reuse
BASE_APPDIR="${APPDIR}-base"
rm -rf "$BASE_APPDIR"
cp -a "$APPDIR" "$BASE_APPDIR"

# Build one AppImage per component
for component in wps et wpp wpspdf; do

    case "$component" in
        wps)    name="WPS Writer" ;;
        et)     name="WPS Spreadsheets" ;;
        wpp)    name="WPS Presentation" ;;
        wpspdf) name="WPS PDF" ;;
    esac

    COMPONENT_APPDIR="${APPDIR}-${component}"
    rm -rf "$COMPONENT_APPDIR"
    cp -a "$BASE_APPDIR" "$COMPONENT_APPDIR"

    # Set primary desktop file for this component
    DESKTOP_SRC="/usr/share/applications/wps-office-${component}.desktop"
    if [ -f "$DESKTOP_SRC" ]; then
        rm -f "$COMPONENT_APPDIR"/*.desktop  # remove placeholder from base
        cp "$DESKTOP_SRC" "$COMPONENT_APPDIR/"
        sed -i "s/^Name=.*/Name=${name}/" "$COMPONENT_APPDIR/wps-office-${component}.desktop"
        export DESKTOP="$COMPONENT_APPDIR/wps-office-${component}.desktop"
    fi

    # Set icon for this component
    ICON_SRC=$(ls /usr/share/icons/hicolor/*/apps/wps-office-${component}.png 2>/dev/null | head -n 1)
    if [ -z "$ICON_SRC" ]; then
        ICON_SRC=$(ls /usr/share/icons/hicolor/*/apps/wps-office-*.png 2>/dev/null | head -n 1)
    fi
    if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
        export ICON="$ICON_SRC"
    fi

    # Deploy launcher script (with APPDIR derivation patches)
    rm -f "$COMPONENT_APPDIR/bin/$component"
    cp "/usr/bin/$component" "$COMPONENT_APPDIR/bin/$component"
    chmod +x "$COMPONENT_APPDIR/bin/$component"
    sed -i '2 i APPDIR="$(dirname "$(dirname "$(readlink -f "$0")")")"' "$COMPONENT_APPDIR/bin/$component"
    sed -i "s|/usr/lib/office6|\"\${APPDIR}\"/usr/lib/office6|g" "$COMPONENT_APPDIR/bin/$component"

    # Build AppImage
    export APPDIR="$COMPONENT_APPDIR"
    quick-sharun --make-appimage

    # Smoke-test the AppImage (12 seconds)
    latest=$(ls -t "$OUTPATH"/*.AppImage 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        quick-sharun --test "$latest"
    fi

done

rm -rf "$BASE_APPDIR"
#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q wps-office | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

# Force English environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# quick-sharun deploy needs a .desktop file in $APPDIR/
# Put a placeholder now; the component loop replaces it per-AppImage.
mkdir -p "$APPDIR"
cp /usr/share/applications/wps-office-wps.desktop "$APPDIR/"
export DESKTOP="$APPDIR/wps-office-wps.desktop"
ICON_SRC=$(ls /usr/share/icons/hicolor/*/apps/wps-office-wps.png 2>/dev/null | head -n 1)
if [ -n "$ICON_SRC" ]; then
    export ICON="$ICON_SRC"
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

# Copy all desktop files
mkdir -p "$APPDIR/usr/share/applications"
cp /usr/share/applications/wps-office-*.desktop "$APPDIR/usr/share/applications/" 2>/dev/null || true

# Copy icons for all components
if [ -d /usr/share/icons/hicolor ]; then
    mkdir -p "$APPDIR/usr/share/icons"
    cp -a /usr/share/icons/hicolor "$APPDIR/usr/share/icons/"
fi

# Save the base AppDir (shared deps + office6 tree) for reuse
BASE_APPDIR="${APPDIR}-base"
rm -rf "$BASE_APPDIR"
cp -a "$APPDIR" "$BASE_APPDIR"

# Build one AppImage per component
for component in wps et wpp wpspdf; do

    case "$component" in
        wps)    name="WPS Writer" ;;
        et)     name="WPS Spreadsheets" ;;
        wpp)    name="WPS Presentation" ;;
        wpspdf) name="WPS PDF" ;;
    esac

    COMPONENT_APPDIR="${APPDIR}-${component}"
    rm -rf "$COMPONENT_APPDIR"
    cp -a "$BASE_APPDIR" "$COMPONENT_APPDIR"

    # Set primary desktop file for this component
    DESKTOP_SRC="/usr/share/applications/wps-office-${component}.desktop"
    if [ -f "$DESKTOP_SRC" ]; then
        rm -f "$COMPONENT_APPDIR"/*.desktop  # remove placeholder from base
        cp "$DESKTOP_SRC" "$COMPONENT_APPDIR/"
        sed -i "s/^Name=.*/Name=${name}/" "$COMPONENT_APPDIR/wps-office-${component}.desktop"
        export DESKTOP="$COMPONENT_APPDIR/wps-office-${component}.desktop"
    fi

    # Set icon for this component
    ICON_SRC=$(ls /usr/share/icons/hicolor/*/apps/wps-office-${component}.png 2>/dev/null | head -n 1)
    if [ -z "$ICON_SRC" ]; then
        ICON_SRC=$(ls /usr/share/icons/hicolor/*/apps/wps-office-*.png 2>/dev/null | head -n 1)
    fi
    if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
        export ICON="$ICON_SRC"
    fi

    # Deploy launcher script (with APPDIR derivation patches)
    rm -f "$COMPONENT_APPDIR/bin/$component"
    cp "/usr/bin/$component" "$COMPONENT_APPDIR/bin/$component"
    chmod +x "$COMPONENT_APPDIR/bin/$component"
    sed -i '2 i APPDIR="$(dirname "$(dirname "$(readlink -f "$0")")")"' "$COMPONENT_APPDIR/bin/$component"
    sed -i "s|/usr/lib/office6|\"\${APPDIR}\"/usr/lib/office6|g" "$COMPONENT_APPDIR/bin/$component"

    # Build AppImage
    export APPDIR="$COMPONENT_APPDIR"
    quick-sharun --make-appimage

    # Smoke-test the AppImage (12 seconds)
    latest=$(ls -t "$OUTPATH"/*.AppImage 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        quick-sharun --test "$latest"
    fi

done

rm -rf "$BASE_APPDIR"
