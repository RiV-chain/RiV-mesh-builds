#!/bin/sh

# This script generates an MSI file for Mesh for a given architecture. It
# needs to run on Windows within MSYS2 and Go 1.19 or later must be installed on
# the system and within the PATH. This is ran currently by Appveyor or GitHub Actions (see
# appveyor.yml in the repository root) for both x86 and x64.
#
# Author: Neil Alexander <neilalexander@users.noreply.github.com>, Vadym Vikulin <vadym.vikulin@rivchain.org>

# Get arch from command line if given
PKGARCH=$1
SIGN=$2

if [ "${PKGARCH}" == "" ];
then
  echo "tell me the architecture: x86, x64 or arm"
  exit 1
fi

# Get the rest of the repository history. This is needed within Appveyor because
# otherwise we don't get all of the branch histories and therefore the semver
# scripts don't work properly.
if [ "${APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH}" != "" ];
then
  git fetch --all
  git checkout ${APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH}
elif [ "${APPVEYOR_REPO_BRANCH}" != "" ];
then
  git fetch --all
  git checkout ${APPVEYOR_REPO_BRANCH}
fi

#Build winres
go-winres simply --icon RiV-mesh/riv.ico --file-version $PKGVERSION --file-description "RiV-mesh (c) service, 2023 RIV CHAIN" \
--product-version $PKGVERSION --product-name "RiV-mesh" --copyright "Copyright (c) 2023, RIV CHAIN"
cp *.syso RiV-mesh/cmd/mesh
go-winres simply --file-version $PKGVERSION --file-description "RiV-mesh (c) CLI, 2023 RIV CHAIN" \
--product-version $PKGVERSION --product-name "RiV-mesh" --copyright "Copyright (c) 2023, RIV CHAIN" --manifest cli
cp *.syso RiV-mesh/cmd/meshctl

# Build Mesh!
[ "${PKGARCH}" == "x64" ] && (cd RiV-mesh && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ ./build)
[ "${PKGARCH}" == "x86" ] && (cd RiV-mesh && GOOS=windows GOARCH=386 CGO_ENABLED=0 CC=i686-w64-mingw32-gcc CXX=i686-w64-mingw32-g++ ./build)
[ "${PKGARCH}" == "arm" ] && (cd RiV-mesh && GOOS=windows GOARCH=arm CGO_ENABLED=0 ./build)
