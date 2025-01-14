#!/bin/sh

# This is a lazy script to create a .deb for Debian/Ubuntu. It installs
# mesh and enables it in systemd. You can give it the PKGARCH= argument
# i.e. PKGARCH=i386 sh contrib/deb/generate.sh

if [ `pwd` != `git rev-parse --show-toplevel` ]
then
  echo "You should run this script from the top-level directory of the git repo"
  exit 1
fi

PKGBRANCH=$(sh -c 'cd RiVPN && basename `git name-rev --name-only HEAD`')
PKG=$(sh -c 'cd RiVPN && contrib/semver/name.sh')
PKGVERSION=$(sh -c 'cd RiVPN && contrib/semver/version.sh --bare')
PKGNAME=$PKG-$PKGVERSION-$PKGARCH
PKGFILE=$PKGNAME.deb
PKGREPLACES=mesh

if [ $PKGBRANCH = "master" ]; then
  PKGREPLACES=mesh-develop
fi

get_rustarch() {
  local PKGARCH=$1
  local RUSTARCH

  case "${PKGARCH}" in
    "amd64")
      RUSTARCH=x86_64
      ;;
    "i386")
      RUSTARCH=i686
      ;;
    "arm64")
      RUSTARCH=aarch64
      ;;
    *)
      echo "Unsupported architecture: ${PKGARCH}" >&2
      return 1
      ;;
  esac

  echo "$RUSTARCH"
  return 0
}

#could be static
buildbin() {
  local CMD=$(realpath "$1")

  # Define RUSTOS
  RUSTOS=linux

  # Set the RUSTRCH based on PKGARCH
  RUSTARCH=$(get_rustarch "$PKGARCH")

  echo "Building: $CMD for $RUSTOS-$RUSTARCH"

  # Run the build command with the correct RUSTARCH and RUSTOS
  (cd "$CMD" && cargo tauri build --target ${RUSTARCH}-unknown-${RUSTOS}-gnu)
}

build_mesh_ui() {
  buildbin ./contrib/ui/mesh-ui/desktop
}

GOOS=linux
if [ $PKGARCH = "amd64" ]; then
  GOARCH=amd64
elif [ $PKGARCH = "i386" ]; then
  GOARCH=386
elif [ $PKGARCH = "arm" ]; then
  GOARCH=386
else
  echo "Specify PKGARCH=amd64, arm or i386"
  exit 1
fi

(cd RiV-mesh && GOOS=$GOOS GOARCH=$GOARCH ./build)
(cd RiVPN && GOOS=$GOOS GOARCH=$GOARCH ./build)

build_mesh_ui

echo "Building $PKGFILE"

mkdir -p /tmp/$PKGNAME/
mkdir -p /tmp/$PKGNAME/debian/
mkdir -p /tmp/$PKGNAME/DEBIAN/
mkdir -p /tmp/$PKGNAME/usr/bin/
mkdir -p /tmp/$PKGNAME/usr/local/bin/
mkdir -p /tmp/$PKGNAME/etc/systemd/system/
mkdir -p /tmp/$PKGNAME/usr/share/applications/
mkdir -p /tmp/$PKGNAME/etc/
mkdir -p /tmp/$PKGNAME/usr/share/riv
mkdir -p /tmp/$PKGNAME/etc/xdg/autostart
chmod 0775 /tmp/$PKGNAME/ -R

for resolution in 16x16 24x24 32x32 48x48 64x64 192x192 256x256 512x512; do
  echo "Converting icon for: $resolution"
  mkdir -p /tmp/$PKGNAME/usr/share/icons/hicolor/$resolution/apps && \
  convert-im6.q16 -colorspace sRGB logos/riv.png -resize $resolution PNG8:/tmp/$PKGNAME/usr/share/icons/hicolor/$resolution/apps/riv.png  && \
  chmod 644 /tmp/$PKGNAME/usr/share/icons/hicolor/$resolution/apps/riv.png
done

cp -r contrib/ui/mesh-ui/ui /tmp/$PKGNAME/usr/share/riv

# Set the RUSTRCH based on PKGARCH
RUSTARCH=$(get_rustarch "$PKGARCH")

cp contrib/ui/mesh-ui/desktop/src-tauri/target/${RUSTARCH}-unknown-linux-gnu/release/mesh-ui .

cat > /tmp/$PKGNAME/usr/share/applications/riv.desktop << EOF
[Desktop Entry]
Name=RiV mesh
GenericName=Mesh network
Comment=RiV-mesh is an early-stage implementation of a fully end-to-end encrypted IPv6 network
Exec=sh -c "/usr/bin/mesh-ui"
Terminal=false
Type=Application
Icon=riv
Categories=Network;FileTransfer;
StartupNotify=false
EOF

cat > /tmp/$PKGNAME/debian/changelog << EOF
Please see https://github.com/RiV-chain/RiV-mesh/
EOF
echo 9 > /tmp/$PKGNAME/debian/compat
cat > /tmp/$PKGNAME/DEBIAN/control << EOF
Package: mesh
Version: $PKGVERSION
Section: contrib/net
Priority: extra
Architecture: $PKGARCH
Replaces: $PKGREPLACES
Conflicts: $PKGREPLACES
Maintainer: Vadym Vikulin <vadym.vikulin@rivchain.org>
Description: RiV-mesh is an implementation of a fully end-to-end encrypted IPv6 network.
 It is lightweight, self-arranging, supported on multiple platforms and
 allows pretty much any IPv6-capable application to communicate securely with
 other RiV-mesh nodes.
EOF
cat > /tmp/$PKGNAME/debian/copyright << EOF
Please see https://github.com/RiV-chain/RiV-mesh/
EOF
cat > /tmp/$PKGNAME/debian/docs << EOF
Please see https://github.com/RiV-chain/RiV-mesh/
EOF
cat > /tmp/$PKGNAME/debian/install << EOF
usr/bin/mesh usr/bin
usr/bin/meshctl usr/bin
usr/bin/mesh-ui usr/bin
usr/local/bin/meshctl usr/local/bin
usr/share/riv/ui usr/share/riv
etc/xdg/autostart/riv.desktop etc/xdg/autostart
etc/systemd/system/*.service etc/systemd/system
usr/share/applications/riv.desktop usr/share/applications
usr/share/icons/hicolor/16x16/apps/riv.png usr/share/icons/hicolor/16x16/apps
usr/share/icons/hicolor/24x24/apps/riv.png usr/share/icons/hicolor/24x24/apps
usr/share/icons/hicolor/32x32/apps/riv.png usr/share/icons/hicolor/32x32/apps
usr/share/icons/hicolor/48x48/apps/riv.png usr/share/icons/hicolor/48x48/apps
usr/share/icons/hicolor/64x64/apps/riv.png usr/share/icons/hicolor/64x64/apps
usr/share/icons/hicolor/192x192/apps/riv.png usr/share/icons/hicolor/192x192/apps
usr/share/icons/hicolor/256x256/apps/riv.png usr/share/icons/hicolor/256x256/apps
usr/share/icons/hicolor/512x512/apps/riv.png usr/share/icons/hicolor/512x512/apps
EOF

cat > /tmp/$PKGNAME/DEBIAN/postinst << EOF
#!/bin/sh

if ! getent group mesh 2>&1 > /dev/null; then
  groupadd --system --force mesh || echo "Failed to create group 'mesh' - please create it manually and reinstall"
fi

if [ -f /etc/mesh.conf ]; then
  mkdir -p /var/backups
  echo "Backing up configuration file to /var/backups/mesh.conf.`date +%Y%m%d`"
  cp /etc/mesh.conf /var/backups/mesh.conf.`date +%Y%m%d`
  echo "Normalising and updating /etc/mesh.conf"
  /usr/bin/mesh -useconf -normaliseconf < /var/backups/mesh.conf.`date +%Y%m%d` > /etc/mesh.conf
else
  echo "Generating initial configuration file /etc/mesh.conf"
  echo "Please familiarise yourself with this file before starting Mesh"
  sh -c 'umask 0027 && /usr/bin/mesh -genconf > /etc/mesh.conf'
fi
chgrp mesh /etc/mesh.conf
chmod 755 /etc/mesh.conf
if command -v systemctl >/dev/null; then
  systemctl daemon-reload || echo -n "daemon not reloaded!"
  systemctl enable mesh || echo -n "systemctl enable failed!"
  systemctl restart mesh || echo -n "systemctl restart failed!"
fi
update-icon-caches /usr/share/icons/*
update-desktop-database /usr/share/applications
EOF

cat > /tmp/$PKGNAME/DEBIAN/prerm << EOF
#!/bin/sh
if command -v systemctl >/dev/null; then
  if systemctl is-active --quiet mesh; then
    systemctl stop mesh || true
  fi
  systemctl disable mesh || true
fi
EOF

cp RiVPN/mesh /tmp/$PKGNAME/usr/bin/
cp RiV-mesh/meshctl /tmp/$PKGNAME/usr/bin/
cp mesh-ui /tmp/$PKGNAME/usr/bin/
ln -s /usr/bin/meshctl /tmp/$PKGNAME/usr/local/bin/meshctl
cp contrib/systemd/*.service /tmp/$PKGNAME/etc/systemd/system/
cp /tmp/$PKGNAME/usr/share/applications/riv.desktop /tmp/$PKGNAME/etc/xdg/autostart
chmod 0775 /tmp/$PKGNAME/DEBIAN/*
chmod 644 /tmp/$PKGNAME/etc/systemd/system/*
chmod 644 /tmp/$PKGNAME/usr/share/applications/riv.desktop
chmod 644 /tmp/$PKGNAME/etc/xdg/autostart/*
chmod 755 /tmp/$PKGNAME/usr/bin/*
chmod -R u+rwX,go+rX,g-w /tmp/$PKGNAME/usr/share/riv/ui

dpkg-deb --build --root-owner-group /tmp/$PKGNAME
cp /tmp/$PKGFILE .

rm -rf /tmp/$PKGNAME
