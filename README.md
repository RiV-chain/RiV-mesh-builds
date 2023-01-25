# RiV-mesh-build
Repository for RiV-mesh builds such as Windows MSI, Linux deb and MacOS pkg.

## Pre-build steps:
```
$ git clone  --recurse-submodules --remote-submodules git@github.com:RiV-chain/RiV-mesh-builds.git
$ go install github.com/swaggo/swag/cmd/swag@latest
$ swag init -g RiV-mesh/src/restapi/rest_server.go --ot yaml -o contrib/ui/mesh-ui/ui/doc
```

## Builds instructions

### Windows:
```
$ bash -lc "./contrib/msi/build-msi-gui.sh x64"
$ bash -lc "./contrib/msi/build-msi-gui.sh x86"
$ bash -lc "./contrib/msi/build-msi.sh x64"
$ bash -lc "./contrib/msi/build-msi.sh x86"
$ bash -lc "./contrib/msi/build-msi-ie.sh x64"
$ bash -lc "./contrib/msi/build-msi-ie.sh x86"
```

### Debian:
```
PKGARCH=amd64 sh ./contrib/deb/generate-gui.sh
PKGARCH=amd64 sh ./contrib/deb/generate.sh
```

### MacOS:

```
$ PKGARCH=amd64 sh contrib/macos/create-pkg-gui.sh
$ PKGARCH=arm64 sh contrib/macos/create-pkg-gui.sh
$ PKGARCH=amd64 sh contrib/macos/create-pkg.sh
$ PKGARCH=arm64 sh contrib/macos/create-pkg.sh
```
