#!/bin/sh

# This is a lazy script to create a .bin for WD NAS build.
# You can give it the PKGARCH= argument
# i.e. PKGARCH=x86_64 contrib/nas/nas-asustor.sh

if [ `pwd` != `git rev-parse --show-toplevel` ]
then
  echo "You should run this script from the top-level directory of the git repo"
  exit 1
fi

PKGBRANCH=$(sh -c 'cd RiV-mesh && basename `git name-rev --name-only HEAD`')
PKG=$(sh -c 'cd RiV-mesh && contrib/semver/name.sh')
PKGVERSION=$(sh -c 'cd RiV-mesh && contrib/semver/version.sh --bare')
PKGARCH=${PKGARCH-amd64}
PKGFOLDER=$ENV_TAG-$PKGARCH-$PKGVERSION
PKGFILE=mesh-$PKGFOLDER.apk
PKGREPLACES=mesh

if [ $PKGBRANCH = "master" ]; then
  PKGREPLACES=mesh-develop
fi

GOOS=linux
if [ $PKGARCH = "x86-64" ]; then
  GOARCH=amd64
elif [ $PKGARCH = "arm" ]; then
  GOARCH=arm
  GOARM=7
elif [ $PKGARCH = "arm64" ]; then
  GOARCH=arm64
elif [ $PKGARCH = "i386" ]; then
  GOARCH=386
else
  echo "Specify PKGARCH=x86-64, arm, arm64 or i386"
  exit 1
fi

(cd RiV-mesh && GOOS=$GOOS GOARCH=$GOARCH ./build)

echo "Building $PKGFOLDER"

rm -rf /tmp/$PKGFOLDER

mkdir -p /tmp/$PKGFOLDER/bin
mkdir -p /tmp/$PKGFOLDER/var/log
chmod 0775 /tmp/$PKGFOLDER/ -R

echo "coping ui package..."
cp contrib/ui/nas-asustor/* /tmp/$PKGFOLDER/ -r
cp -r -n contrib/ui/mesh-ui/ui/* /tmp/$PKGFOLDER/www/

echo "Converting icon for: 90x90"
convert-im6.q16 -colorspace sRGB logos/riv.png -resize 90x90 PNG32:/tmp/$PKGFOLDER/CONTROL/icon.png
chmod 644 /tmp/$PKGFOLDER/CONTROL/icon.png

cat > /tmp/$PKGFOLDER/CONTROL/config.json << EOF
{
	"general": {
		"package": "mesh-$ENV_TAG",
		"name": "RiV Mesh",
		"version": "$PKGVERSION",
		"depends": [],
		"conflicts": [],
		"developer": "Riv Chain ltd",
		"maintainer": "Riv Chain ltd",
		"email": "vadym.vikulin@rivchain.org",
		"website": "https://github.com/RiV-chain/RiV-mesh",
		"architecture": "$PKGARCH",
		"firmware": "2.4.0"
	},
	"adm-desktop": {
		"app": {
			"type":"custom",
			"protocol":"http",
			"port": 19019,
			"url": "/"
		},
		"privilege": {
			"accessible": "administrators",
			"customizable": true
		}
	},
	"register": {
		"share-folder": [
		],
		"prerequisites": {
			"enable-service": [],
			"restart-service": []
		},
		"boot-priority": {
			"start-order": 95,
			"stop-order": 5
		},
		"port": []
	}
}
EOF

cat > /tmp/$PKGFOLDER/CHANGELOG.md << EOF
See https://github.com/RiV-chain/RiV-mesh
EOF

cat > /tmp/$PKGFOLDER/CONTROL/changelog.txt << EOF
See https://github.com/RiV-chain/RiV-mesh
EOF

cp RiV-mesh/mesh /tmp/$PKGFOLDER/bin
cp RiV-mesh/meshctl /tmp/$PKGFOLDER/bin
cp RiV-mesh/LICENSE /tmp/$PKGFOLDER/CONTROL/license.txt
chmod +x /tmp/$PKGFOLDER/bin/*
chmod 0775 /tmp/$PKGFOLDER/www -R

fakeroot python2 ./contrib/nas/tool/asustor_apkg_tools.py create /tmp/$PKGFOLDER

rm -rf /tmp/$PKGFOLDER/
#mv *.apk $PKGFILE
