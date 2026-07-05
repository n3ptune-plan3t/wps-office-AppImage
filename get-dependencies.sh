#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
# pacman -Syu --noconfirm PACKAGESHERE
pacman -Syu --noconfirm base-devel desktop-file-utils fontconfig glu hicolor-icon-theme \
    libpulse libtool libxrender libxslt libxss sdl2 shared-mime-info sqlite xdg-utils \
    xorg-mkfontscale libjpeg-turbo

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME
make-aur-package wps-office-cn

# If the application needs to be manually built that has to be done down here

# if you also have to make nightly releases check for DEVEL_RELEASE = 1
#
# if [ "${DEVEL_RELEASE-}" = 1 ]; then
# 	nightly build steps
# else
# 	regular build steps
# fi
