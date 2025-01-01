#!/bin/sh

# This script generates an MSI file for Mesh for a given architecture. It
# needs to run on Windows within MSYS2 and Go 1.19 or later must be installed on
# the system and within the PATH. This is ran currently by Appveyor or GitHub Actions (see
# appveyor.yml in the repository root) for both x86 and x64.
#
# Author: Neil Alexander <neilalexander@users.noreply.github.com>, Vadym Vikulin <vadym.vikulin@rivchain.org>

# Get arch from command line if given

ARGS="-v"

PKGARCH=$1
SIGN=$2

TARGET_PATH=$(pwd)
while getopts "utc:l:dro:psg:b:" option
do
  case "$option"
  in
  u) UPX=true;;
  t) TABLES=true;;
  c) GCFLAGS="$GCFLAGS $OPTARG";;
  l) LDFLAGS="$LDFLAGS $OPTARG";;
  d) ARGS="$ARGS -tags debug" DEBUG=true;;
  r) ARGS="$ARGS -race";;
  o) ARGS="$ARGS -o $OPTARG";;
  p) ARGS="$ARGS -buildmode=pie";;
  # statically linked executable
  s) STATIC=" -linkmode external -extldflags=-static";;
  # build target
  g) TARGET=$OPTARG;;
  # build path
  b) TARGET_PATH=$OPTARG;;
  esac
done

if [ -z $TABLES ] && [ -z $DEBUG ]; then
  LDFLAGS="$LDFLAGS -s -w"
fi

get_rustarch() {
  local PKGARCH=$1
  local RUSTARCH

  case "${PKGARCH}" in
    "x64")
      RUSTARCH=x86_64
      ;;
    "x86")
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
  RUSTOS=windows

  # Set the RUSTRCH based on PKGARCH
  RUSTARCH=$(get_rustarch "$PKGARCH")

  echo "Building: $CMD for $RUSTOS-$RUSTARCH"

  # Run the build command with the correct RUSTARCH and RUSTOS
  (cd "$CMD" && cargo tauri build --target ${RUSTARCH}-pc-${RUSTOS}-msvc)
}

setup_repo() {
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
}

generate_doc() {
  swag init -g RiV-mesh/src/restapi/rest_server.go --ot yaml -o contrib/ui/mesh-ui/ui/doc
}

setup_wix() {
  # Install prerequisites within MSYS2
  pacman -S --needed --noconfirm unzip git curl

  # Download the wix tools!
  dotnet tool install --global wix --version 5.0.0
}

prepare_metadata() {
  # Work out metadata for the package info
  PKGNAME=$(sh -c 'cd RiVPN && contrib/semver/name.sh')
  PKGVERSION=$(sh -c 'cd RiVPN && contrib/msi/msversion.sh --bare')
  PKGVERSIONMS=$(echo $PKGVERSION | tr - .)
  PKGUIFOLDER=contrib/ui/mesh-ui/ui/
  PKGLICENSEFILE=RiV-mesh/LICENSE.rtf
}

copy_res(){
  #Need to build only for Mesh. UI build maintained by tauri

  #Build winres
  go-winres simply --icon logos/riv.ico --file-version $PKGVERSION --file-description "RiV-mesh (c) service, 2025 RIV CHAIN" \
  --product-version $PKGVERSION --product-name "RiV-mesh" --copyright "Copyright (c) 2025, RIV CHAIN"
  cp *.syso RiVPN/cmd/mesh
  go-winres simply --file-version $PKGVERSION --file-description "RiV-mesh (c) CLI, 2025 RIV CHAIN" \
  --product-version $PKGVERSION --product-name "RiV-mesh" --copyright "Copyright (c) 2025, RIV CHAIN" --manifest cli
  cp *.syso RiV-mesh/cmd/meshctl
}

build_mesh() {
  # Build Mesh!
  [ "${PKGARCH}" == "x64" ] && (cd RiV-mesh && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ ./build)
  [ "${PKGARCH}" == "x86" ] && (cd RiV-mesh && GOOS=windows GOARCH=386 CGO_ENABLED=0 CC=i686-w64-mingw32-gcc CXX=i686-w64-mingw32-g++ ./build)
  [ "${PKGARCH}" == "arm64" ] && (cd RiV-mesh && GOOS=windows GOARCH=arm64 CGO_ENABLED=0 ./build)
}

build_vpn() {
  # Build Mesh!
  [ "${PKGARCH}" == "x64" ] && (cd RiVPN && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ ./build)
  [ "${PKGARCH}" == "x86" ] && (cd RiVPN && GOOS=windows GOARCH=386 CGO_ENABLED=0 CC=i686-w64-mingw32-gcc CXX=i686-w64-mingw32-g++ ./build)
  [ "${PKGARCH}" == "arm64" ] && (cd RiVPN && GOOS=windows GOARCH=arm64 CGO_ENABLED=0 ./build)
}

build_mesh_ui() {
  buildbin ./contrib/ui/mesh-ui/desktop
}

sign_exe() {
  #Sign Mesh binaries
  [ "${SIGN}" == "sign" ] && cmd \""/c signtool sign /debug /v /tr http://timestamp.sectigo.com /td sha256 /fd sha256 /a RiVPN/mesh.exe RiV-mesh/meshctl.exe mesh-ui.exe"\"
}

prepare_msi_build() {
  # Download the Wintun driver
  if [ ! -d wintun ];
  then
    curl --insecure -o wintun.zip https://www.wintun.net/builds/wintun-0.14.1.zip
    unzip wintun.zip
  fi
  if [ $PKGARCH = "x64" ]; then
    PKGWINTUNDLL=wintun/bin/amd64/wintun.dll
  elif [ $PKGARCH = "x86" ]; then
    PKGWINTUNDLL=wintun/bin/x86/wintun.dll
  elif [ $PKGARCH = "arm64" ]; then
    PKGWINTUNDLL=wintun/bin/arm64/wintun.dll
  else
    echo "wasn't sure which architecture to get wintun for"
    exit 1
  fi

  # Create the postinstall script
cat > updateconfig.bat << EOF
  if not exist %ALLUSERSPROFILE%\\RiV-mesh (
    mkdir %ALLUSERSPROFILE%\\RiV-mesh
  )
  if not exist %ALLUSERSPROFILE%\\RiV-mesh\\mesh.conf (
    if exist mesh.exe (
      mesh.exe -genconf > %ALLUSERSPROFILE%\\RiV-mesh\\mesh.conf
    )
  )
EOF

  cp logos/riv.ico "$PKGUIFOLDER"/favicon.ico

  #fix me: move icons here from RiV-mesh repo
  cp logos/riv.ico .
  #copy exe to current folder
  cp RiV-mesh/meshctl .
  cp RiVPN/mesh* .

  # Define RUSTOS
  RUSTOS=windows

  # Set the RUSTRCH based on PKGARCH
  RUSTARCH=$(get_rustarch "$PKGARCH")

  cp contrib/ui/mesh-ui/desktop/src-tauri/target/${RUSTARCH}-pc-${RUSTOS}-msvc/release/mesh-ui.exe .

  PKG_UI_ASSETS_ZIP=$(pwd)/ui.zip
  ( cd "$PKGUIFOLDER" && 7z a "$PKG_UI_ASSETS_ZIP" * )
  PKG_UI_ASSETS_ZIP=ui.zip

  if [ $PKGNAME != "master" ]; then
    PKGDISPLAYNAME="RiV-mesh Network (${PKGNAME} branch)"
  else
    PKGDISPLAYNAME="RiV-mesh Network"
  fi

case "${PKGARCH}" in
  "x64")
    PKGGUID="5bcfdddd-66a7-4eb7-b5f7-4a7500dcc65d"
    PKGINSTFOLDER="ProgramFiles64Folder"
    ;;
  "x86")
    PKGGUID="cbf6ffa1-219e-4bb2-a0e5-74dbf1b58a45"
    PKGINSTFOLDER="ProgramFilesFolder"
    ;;
  "arm64")
    PKGGUID="a5a03811-6607-42da-b8d6-561e14b68d87"
    PKGINSTFOLDER="ProgramFiles64Folder"
    ;;
  *)
    echo "Unknown architecture: ${PKGARCH}"
    exit 1
    ;;
esac

# Generate the wix.xml file
cat > wix.xml << EOF
<?xml version="1.0" encoding="windows-1252"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product
    Name="${PKGDISPLAYNAME}"
    Id="*"
    UpgradeCode="${PKGGUID}"
    Language="1033"
    Codepage="1252"
    Version="${PKGVERSIONMS}"
    Manufacturer="RiV-chain">

    <Package
      Id="*"
      Keywords="Installer"
      Description="RiV-mesh Network Installer"
      Comments="RiV-mesh Network standalone router for Windows."
      Manufacturer="RiV-chain"
      InstallerVersion="500"
      InstallScope="perMachine"
      Languages="1033"
      Compressed="yes"
      SummaryCodepage="1252" />

    <MajorUpgrade
      AllowDowngrades="yes" />

    <Media
      Id="1"
      Cabinet="Media.cab"
      EmbedCab="yes"
      CompressionLevel="high" />

    <Icon Id="icon.ico" SourceFile="riv.ico"/>
    <Property Id="ARPPRODUCTICON" Value="icon.ico" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="DesktopFolder"  SourceName="Desktop"/>
      <Directory Id="${PKGINSTFOLDER}" Name="PFiles">
        <Directory Id="MeshInstallFolder" Name="RiV-mesh">
          <Component Id="MainExecutable" Guid="c2119231-2aa3-4962-867a-9759c87beb24">
            <File
              Id="Mesh"
              Name="mesh.exe"
              DiskId="1"
              Source="mesh.exe"
              KeyPath="yes" />
            <File
              Id="Wintun"
              Name="wintun.dll"
              DiskId="1"
              Source="${PKGWINTUNDLL}" />
            <ServiceInstall
              Id="MeshServiceInstaller"
              Account="LocalSystem"
              Description="RiV-mesh Network router process"
              DisplayName="RiV-mesh Service"
              ErrorControl="normal"
              LoadOrderGroup="NetworkProvider"
              Name="Mesh"
              Start="auto"
              Type="ownProcess"
              Arguments='-useconffile "%ALLUSERSPROFILE%\\RiV-mesh\\mesh.conf" -logto "%ALLUSERSPROFILE%\\RiV-mesh\\mesh.log" -httpaddress "http://localhost:19019" -wwwroot "[MeshInstallFolder]ui.zip"'
              Vital="yes" />
            <ServiceControl
              Id="MeshServiceControl"
              Name="Mesh"
              Start="install"
              Stop="both"
              Remove="uninstall" />
          </Component>
          <Component Id="CtrlExecutable" Guid="a916b730-974d-42a1-b687-d9d504cbb86a">
            <File
              Id="Meshctl"
              Name="meshctl.exe"
              DiskId="1"
              Source="meshctl.exe"
              KeyPath="yes"/>
            <Environment
              Id="UpdatePath"
              Name="PATH"
              Value="[MeshInstallFolder]"
              Permanent="no"
              Part="last"
              Action="set"
              System="yes"/>
          </Component>

          <Component Id="UIExecutable" Guid="ef9f30e0-8274-4526-835b-51bc09b5b1b7">

            <File
              Id="MeshUI"
              Name="mesh-ui.exe"
              DiskId="1"
              Source="mesh-ui.exe"
              KeyPath="yes" />
            <File
              Id="UiAssets"
              Name="ui.zip"
              DiskId="1"
              Source="${PKG_UI_ASSETS_ZIP}" />

          </Component>


          <Component Id="ConfigScript" Guid="64a3733b-c98a-4732-85f3-20cd7da1a785">
            <File
              Id="Configbat"
              Name="updateconfig.bat"
              DiskId="1"
              Source="updateconfig.bat"
              KeyPath="yes"/>
          </Component>
        </Directory>
      </Directory>
    </Directory>

    <Feature Id="MeshFeature" Title="Mesh" Level="1">
      <ComponentRef Id="MainExecutable" />
      <ComponentRef Id="UIExecutable" />
      <ComponentRef Id="CtrlExecutable" />
      <ComponentRef Id="cmpDesktopShortcut" />
      <ComponentRef Id="ConfigScript" />
    </Feature>

    <CustomAction
      Id="UpdateGenerateConfig"
      Directory="MeshInstallFolder"
      ExeCommand="cmd.exe /c updateconfig.bat"
      Execute="deferred"
      Return="check"
      Impersonate="yes" />

    <!-- Step 2: Add UI to your installer / Step 4: Trigger the custom action -->
    <UI>
        <UIRef Id="WixUI_Minimal" />
        <Publish Dialog="ExitDialog"
            Control="Finish"
            Event="DoAction"
            Value="LaunchApplication">WIXUI_EXITDIALOGOPTIONALCHECKBOX = 1 and NOT Installed</Publish>
    </UI>
    <WixVariable Id="WixUILicenseRtf" Value="${PKGLICENSEFILE}" />
    <Property Id="WIXUI_EXITDIALOGOPTIONALCHECKBOXTEXT" Value="Launch RiV-mesh" />
    <CustomAction Id="LaunchApplication"
      FileKey="MeshUI"
      Impersonate="yes"
      ExeCommand=""
      Return="asyncNoWait" />

    <!-- Step 3: Include the custom action -->
    <Property Id="ASSISTANCE_START_VIA_REGISTRY">1</Property>
    <InstallExecuteSequence>
      <Custom
        Action="UpdateGenerateConfig"
        Before="StartServices">
          NOT Installed AND NOT REMOVE
      </Custom>
    </InstallExecuteSequence>

    <Component Id="cmpDesktopShortcut" Guid="e32e4d07-abf8-4c37-a2c3-1ca4b4f98adc" Directory="DesktopFolder" >
        <Shortcut Id="RiVMeshDesktopShortcut"
             Name="RiV-mesh"
             Description="RiV-mesh is IoT E2E encrypted network"
             Directory="DesktopFolder"
             Target="[MeshInstallFolder]mesh-ui.exe"
             WorkingDirectory="MeshInstallFolder"/>
        <RegistryValue Root="HKCU"
            Key="Software\RiV-chain\RiV-mesh"
            Name="installed"
            Type="integer"
            Value="1"
            KeyPath="yes" />
        <RegistryValue Id="MerAs.rst" Root="HKCU" Action="write"
            Key="Software\Microsoft\Windows\CurrentVersion\Run"
            Name="RiV-mesh client"
            Type="string"
            Value='"[MeshInstallFolder]mesh-ui.exe"' />
        <Condition>ASSISTANCE_START_VIA_REGISTRY</Condition>
     </Component>

  </Product>
</Wix>
EOF

}

build_msi(){
  # Generate the MSI
  CANDLEFLAGS="-nologo"
  LIGHTFLAGS="-nologo -spdb -sice:ICE71 -sice:ICE61"
  candle $CANDLEFLAGS -out ${PKGNAME}-${PKGVERSION}-${PKGARCH}.wixobj -arch ${PKGARCH} wix.xml && \
  light $LIGHTFLAGS -ext WixUIExtension -ext WixUtilExtension -out ${PKGNAME}-${PKGVERSION}-${PKGARCH}.msi ${PKGNAME}-${PKGVERSION}-${PKGARCH}.wixobj
}

sign_msi() {
  #Sign MSI
  if [[ "${SIGN}" == "sign" ]];
  then
    cmd \""/c signtool sign /debug /v /tr http://timestamp.sectigo.com /td sha256 /fd sha256 /a ${PKGNAME}-${PKGVERSION}-${PKGARCH}.msi"\"
  fi
}

if [ "${PKGARCH}" == "" ];
then
  echo "tell me the architecture: x86, x64 or arm"
  exit 1
fi

case $TARGET in
  "mesh_ui")
    build_mesh_ui
    ;;
  *)
    setup_repo
    generate_doc
    setup_wix
    prepare_metadata
    copy_res
    build_mesh
    build_vpn
    build_mesh_ui
    sign_exe
    prepare_msi_build
    build_msi
    sign_msi
    ;;
esac
