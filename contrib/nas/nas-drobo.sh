#!/bin/sh

# This is a lazy script to create a .bin for WD NAS build.
# You can give it the PKGARCH= argument
# i.e. PKGARCH=armv7 contrib/nas/nas-drobo.sh

if [ `pwd` != `git rev-parse --show-toplevel` ]
then
  echo "You should run this script from the top-level directory of the git repo"
  exit 1
fi

PKGBRANCH=$(sh -c 'cd RiV-mesh && basename `git name-rev --name-only HEAD`')
PKG=$(sh -c 'cd RiV-mesh && contrib/semver/name.sh')
PKGVERSION=$(sh -c 'cd RiV-mesh && contrib/semver/version.sh --bare')
PKGNAME=$ENV_TAG-$PKGARCH-$PKGVERSION
PKGFOLDER=$PKGNAME/mesh
PKGFILE=mesh-$PKGNAME.tar.gz
PKGREPLACES=mesh

if [ $PKGBRANCH = "master" ]; then
  PKGREPLACES=mesh-develop
fi

GOOS=linux
if [ $PKGARCH = "armv7" ]; then
  GOARCH=arm
  GOARM=7
else
  echo "Specify PKGARCH=armv7"
  exit 1
fi

(cd RiV-mesh && GOOS=$GOOS GOARCH=$GOARCH ./build)

echo "Building $PKGFOLDER"

rm -rf /tmp/$PKGFOLDER

mkdir -p /tmp/$PKGFOLDER/bin
mkdir -p /tmp/$PKGFOLDER/config
mkdir -p /tmp/$PKGFOLDER/var/log
mkdir -p /tmp/$PKGFOLDER/lib/modules

if [ $ENV_TAG = "nas-drobo-5n" ]; then
   for kernel in 3.2.96-3 3.2.58-2 3.2.58-1 3.2.58 3.2.27; do
     echo "Loading tun module for Linux kernel $kernel"
     wget -N ftp://updates.drobo.com/droboapps/kernelmodules/5N/3.2.96-3/tun.ko -P /tmp/$PKGFOLDER/lib/modules/$kernel
   done
elif [ $ENV_TAG = "nas-drobo-5n2" ]; then
   for kernel in 3.2.96-3 3.2.58-2; do
     echo "Loading tun module for Linux kernel $kernel"
     wget -N ftp://updates.drobo.com/droboapps/kernelmodules/5N2/3.2.96-3/tun.ko -P /tmp/$PKGFOLDER/lib/modules/$kernel
   done
elif [ $ENV_TAG = "nas-drobo-b810n" ]; then
   for kernel in 3.2.96-3 3.2.58-2 3.2.58-1 3.2.58; do
     echo "Loading tun module for Linux kernel $kernel"
     wget -N ftp://updates.drobo.com/droboapps/kernelmodules/B810n/3.2.96-3/tun.ko -P /tmp/$PKGFOLDER/lib/modules/$kernel
   done
else
  echo "Specify ENV_TAG=nas-drobo-5n or nas-drobo-5n2 or nas-drobo-b810n"
  exit 1
fi

mkdir -p /tmp/$PKGFOLDER/tmp
chmod 0775 /tmp/$PKGFOLDER/ -R

echo "coping ui package..."
cp contrib/ui/nas-drobo/Content/* /tmp/$PKGFOLDER/ -r
cp -r -n contrib/ui/mesh-ui/ui/* /tmp/$PKGFOLDER/www/

cat > /tmp/$PKGFOLDER/version.txt << EOF
$PKGVERSION
EOF

cp RiV-mesh/mesh /tmp/$PKGFOLDER/bin
cp RiV-mesh/meshctl /tmp/$PKGFOLDER/bin
cp RiV-mesh/LICENSE /tmp/$PKGFOLDER/
chmod +x /tmp/$PKGFOLDER/*.sh
chmod +x /tmp/$PKGFOLDER/bin/*
chmod 0775 /tmp/$PKGFOLDER/www -R

current_dir=$(pwd)

cd /tmp/$PKGFOLDER && tar czf ../mesh.tgz $(ls .)
cd ../ && md5sum mesh.tgz > mesh.tgz.md5
tar czf $PKGFILE mesh.tgz mesh.tgz.md5

mv $PKGFILE "$current_dir"

cd "$current_dir"

rm -rf /tmp/$PKGNAME/

