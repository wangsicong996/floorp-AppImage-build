#!/bin/sh

set -ex

ARCH=$(uname -m)
case "$ARCH" in
	x86_64|aarch64)
		;;
	arm64)
		ARCH="aarch64"
		;;
	*)
		echo "Unsupported architecture: $ARCH" >&2
		exit 1
		;;
esac
export ARCH

REPO="https://api.github.com/repos/Floorp-Projects/Floorp/releases"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
REPOSITORY="${GITHUB_REPOSITORY:-Portable-Linux-Apps/floorp-AppImage}"
UPINFO="gh-releases-zsync|$(echo "$REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
DESKTOP="https://github.com/flathub/one.ablaze.floorp/raw/refs/heads/master/src/one.ablaze.floorp.desktop"

tarball_url=$(wget "$REPO" -O - | sed 's/[()",{} ]/\n/g' \
	| grep -oi "https.*linux-$ARCH.tar.xz" | head -1)
export VERSION=$(echo "$tarball_url" | awk -F'/' '{print $(NF-1); exit}')
echo "$VERSION" > ~/version

wget "$tarball_url" -O ./package.tar.xz
tar xvf ./package.tar.xz
rm -f ./package.tar.xz

mv -v ./floorp ./AppDir && (
	cd ./AppDir
	cp -v ./browser/chrome/icons/default/default128.png ./one.ablaze.floorp.png
	cp -v ./browser/chrome/icons/default/default128.png ./.DirIcon
	wget "$DESKTOP" -O ./floorp.desktop

	cat > ./AppRun <<- 'KEK'
	#!/bin/sh
	CURRENTDIR="$(dirname "$(readlink -f "$0")")"
	export PATH="${CURRENTDIR}:${PATH}"
	export MOZ_LEGACY_PROFILES=1          # Prevent per installation profiles
	export MOZ_APP_LAUNCHER="${APPIMAGE}" # Allows setting as default browser
	exec "${CURRENTDIR}/floorp" "$@"
	KEK
	chmod +x ./AppRun

	# disable automatic updates
	mkdir -p ./distribution
	cat >> ./distribution/policies.json <<- 'KEK'
	{
	  "policies": {
	    "DisableAppUpdate": true,
	    "AppAutoUpdate": false,
	    "BackgroundAppUpdate": false
	  }
	}
	KEK
)

wget "$APPIMAGETOOL" -O ./appimagetool.AppImage
chmod +x ./appimagetool.AppImage

APPIMAGE_NAME="Floorp-${VERSION}-${ARCH}.AppImage"
VERSION="$VERSION" \
UPDATE_INFORMATION="$UPINFO" \
ARCH="$ARCH" \
./appimagetool.AppImage --appimage-extract-and-run ./AppDir "./$APPIMAGE_NAME"
