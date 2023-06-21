# RiV-mesh-build
Repository for RiV-mesh builds such as Windows MSI, Linux deb and MacOS pkg.
Desktop GUI related artifacts such as app icons, styles, layouts can be found here **contrib/ui/mesh-ui/ui**
NAS GUI **contrib/ui/nas-xxx**

## Pre-build steps:
```
$ git clone --recursive https://github.com/RiV-chain/RiV-mesh-builds.git
$ go install github.com/swaggo/swag/cmd/swag@latest
$ swag init -g RiV-mesh/src/restapi/rest_server.go --ot yaml -o contrib/ui/mesh-ui/ui/doc
```

## Builds instructions

### Windows:
#### Install dependencies:
Downalod and install **git-scm**, **7zip**, **signtools**(optional) and point these binaries in system PATH.
#### Install go-winres
```
$ go install github.com/tc-hib/go-winres@latest
```

#### Build:
```
$ ./contrib/msi/build-msi-gui.sh x64
$ ./contrib/msi/build-msi-gui.sh x86
$ ./contrib/msi/build-msi.sh x64
$ ./contrib/msi/build-msi.sh x86
$ ./contrib/msi/build-msi-ie.sh x64
$ ./contrib/msi/build-msi-ie.sh x86
```

### Debian:
#### Install dependencies:
```
$ sudo apt-get install pkg-config rpm imagemagick gtk+-3.0 webkit2gtk-4.0
```
#### Build:
```
$ PKGARCH=amd64 sh ./contrib/deb/generate-gui.sh
$ PKGARCH=amd64 sh ./contrib/deb/generate.sh
```

### MacOS:
#### Install coreutils:
```
$ brew install coreutils
```
#### Build:
```
$ PKGARCH=amd64 sh contrib/macos/create-pkg-gui.sh
$ PKGARCH=arm64 sh contrib/macos/create-pkg-gui.sh
$ PKGARCH=amd64 sh contrib/macos/create-pkg.sh
$ PKGARCH=arm64 sh contrib/macos/create-pkg.sh
```
