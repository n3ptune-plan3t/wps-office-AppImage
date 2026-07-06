#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q wps-office | awk '{print $2; exit}') # example command to get version of application here
export ARCH VERSION
export OUTPATH=./dist
#export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

# Disable background processes to prevent shutdown crashes
echo "Applying post-install fixes..."
chmod -x /usr/lib/office6/wpscloudsvr
chmod -x /usr/lib/office6/wpsoffice

# Force English environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Handle icon - prefer large PNG icon from mimetypes or apps dirs
PRIMARY_ICON=$(ls /usr/share/icons/hicolor/256x256/mimetypes/wps-office2019-wpsmain.png 2>/dev/null | head -n 1)
if [ -z "$PRIMARY_ICON" ]; then
    PRIMARY_ICON=$(ls /usr/share/icons/hicolor/*/apps/wps-office-kingsoft.png 2>/dev/null | head -n 1)
fi
if [ -z "$PRIMARY_ICON" ]; then
    PRIMARY_ICON=$(ls /usr/share/icons/hicolor/*/apps/wps-office*.png 2>/dev/null | head -n 1)
fi
if [ -n "$PRIMARY_ICON" ]; then
    export ICON="$PRIMARY_ICON"
fi

# Handle desktop file - ensure it's not copied to itself
PRIMARY_DESKTOP=$(ls /usr/share/applications/wps-office-wps.desktop 2>/dev/null | head -n 1)
if [ -z "$PRIMARY_DESKTOP" ]; then
    PRIMARY_DESKTOP=$(ls /usr/share/applications/wps-office*.desktop 2>/dev/null | head -n 1)
fi
DESKTOP_NAME="$(basename "$PRIMARY_DESKTOP")"
if [ -f "/usr/share/applications/$DESKTOP_NAME" ]; then
    export DESKTOP="$DESKTOP_NAME"
fi

# Deploy dependencies
quick-sharun /usr/bin/wps
quick-sharun /usr/bin/et
quick-sharun /usr/bin/wpp
quick-sharun /usr/bin/wpspdf
quick-sharun /usr/lib/office6/wpsd
quick-sharun /usr/lib/office6/promecefpluginhost
quick-sharun /usr/lib/office6/transerr

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage
