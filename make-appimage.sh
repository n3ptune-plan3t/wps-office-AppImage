#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q wps-office-cn | awk '{print $2; exit}') # example command to get version of application here
export ARCH VERSION
export APPDIR="./AppDir"
export OUTPATH=./dist
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$OUTPATH"
#export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

# Disable background processes to prevent shutdown crashes
echo "Applying post-install fixes..."
chmod -x /usr/lib/office6/wpscloudsvr
chmod -x /usr/lib/office6/wpsoffice

# Force English environment and strip Chinese resources
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Remove Chinese language files to ensure English fallback
if [ -d "/usr/lib/office6/mui/zh_CN" ]; then
    rm -rf "/usr/lib/office6/mui/zh_CN"
fi

export ICON="/usr/share/icons/hicolor/scalable/apps/wps-office.svg"
PRIMARY_DESKTOP=$(ls /usr/share/applications/*.desktop | head -n 1)
cp "$PRIMARY_DESKTOP" "$APPDIR/"
export DESKTOP="$APPDIR/$(basename "$PRIMARY_DESKTOP")"

# Deploy dependencies
quick-sharun /usr/bin/wps

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage
