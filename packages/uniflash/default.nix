# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
{
  stdenvNoCC,
  lib,
  fetchurl,
  buildFHSEnv,
  writeShellScript,
  symlinkJoin,
  glibc,
}:

let
  version = "9.5.0";
  buildId = "5651";

  package = stdenvNoCC.mkDerivation {
    pname = "uniflash-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://dr-download.ti.com/software-development/software-programming-tool/MD-QeJBJLj8gq/${version}/uniflash_sl.${version}.${buildId}.run";
      hash = "sha256-/2gUq90WcEIGmnmpjaNGXxaSEXQn12B7AaHTgUNjn3M=";
    };

    dontUnpack = true;
    dontConfigure = true;
    dontPatchELF = true;
    dontStrip = true;

    buildPhase = ''
      runHook preBuild

      # The installer is a BitRock InstallBuilder ELF binary that expects
      # /lib64/ld-linux-x86-64.so.2 — invoke it via the nix glibc interpreter
      export HOME="$TMPDIR/fakehome"
      mkdir -p "$HOME"

      ${glibc}/lib/ld-linux-x86-64.so.2 $src \
        --mode unattended \
        --prefix "$TMPDIR/uniflash" \
        || true  # Installer may warn about missing GUI libs but still extracts

      # Verify installation succeeded
      test -f "$TMPDIR/uniflash/dslite.sh" \
        || (echo "Installation failed: dslite.sh not found"; exit 1)

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      local installDir="$TMPDIR/uniflash"

      # Main application directory
      mkdir -p $out/opt/uniflash
      cp -r "$installDir"/. $out/opt/uniflash/

      # Ensure key binaries are executable
      chmod +x $out/opt/uniflash/dslite.sh
      chmod +x $out/opt/uniflash/deskdb/content/TICloudAgent/linux/ccs_base/DebugServer/bin/DSLite

      # Fix broken absolute symlinks created by installer
      # The installer creates absolute symlinks to $TMPDIR paths for shared
      # fonts ($TMPDIR is /build in the default sandbox, but not guaranteed)
      find $out -type l -lname "$TMPDIR/*" -delete

      # Re-create the font links as relative symlinks
      local fontsDir="$out/opt/uniflash/uniflash/public/fonts"
      local slFontsDir="$out/opt/uniflash/simplelink/imagecreator/web/fonts"
      if [ -d "$fontsDir" ] && [ -d "$slFontsDir" ]; then
        ln -sf "../../../../../uniflash/public/fonts/roboto" "$slFontsDir/roboto/roboto" 2>/dev/null || true
        ln -sf "../../../../../uniflash/public/fonts/open-sans" "$slFontsDir/open-sans/open-sans" 2>/dev/null || true
      fi

      # Install udev rules for TI debug probes (XDS200, XDS110, etc.)
      mkdir -p $out/lib/udev/rules.d
      cp "$installDir/TICloudAgentHostApp/install_scripts/71-ti-permissions.rules" \
         $out/lib/udev/rules.d/
      cp "$installDir/TICloudAgentHostApp/install_scripts/70-mm-no-ti-emulators.rules" \
         $out/lib/udev/rules.d/
      # Blackhawk XDS probes (XDS560, XDS510 USB variants)
      cp "$installDir/deskdb/content/TICloudAgent/linux/ccs_base/emulation/Blackhawk/Install/71-bh-permissions.rules" \
         $out/lib/udev/rules.d/

      runHook postInstall
    '';

    meta = {
      description = "TI Uniform Flash Programmer for microcontrollers and DSPs";
      longDescription = ''
        UniFlash is a software tool for programming on-chip flash memory
        on TI microcontrollers and wireless connectivity devices. It supports
        XDS200, XDS110, and XDS100 JTAG debug probes for C2000, MSP430,
        MSP432, CC-series, Sitara, and other TI device families.
      '';
      homepage = "https://www.ti.com/tool/UNIFLASH";
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };

  # Shared FHS target packages for all wrappers
  fhsTargetPkgs =
    pkgs: with pkgs; [
      # USB and hardware access
      libusb1
      udev

      # Graphics / display (for GUI - node-webkit based)
      libGL
      libgbm
      libdrm
      libxkbcommon
      libx11
      libxcb
      libxext
      libxrandr
      libxcomposite
      libxdamage
      libxfixes
      libxi
      libxcursor
      libxtst
      libxrender

      # GTK / desktop integration
      gtk3
      glib
      pango
      cairo
      at-spi2-atk
      dbus

      # Crypto / networking
      openssl
      nss
      nspr

      # General
      zlib
      expat
      cups
      alsa-lib
      freetype
      fontconfig
    ];

  # Helper to create an FHS-wrapped entry point
  mkFHSWrapper =
    {
      pname,
      runScript,
      extraCommands ? "",
    }:
    buildFHSEnv {
      inherit pname version;
      inherit (package) meta;
      inherit runScript;
      targetPkgs = fhsTargetPkgs;
      extraInstallCommands = extraCommands;
    };

  # CLI wrapper (dslite - primary flash/debug tool)
  cli = mkFHSWrapper {
    pname = "dslite";
    runScript = writeShellScript "dslite" ''
      export LD_LIBRARY_PATH="${package}/opt/uniflash/deskdb/content/TICloudAgent/linux/ccs_base/DebugServer/drivers:${package}/opt/uniflash/deskdb/content/TICloudAgent/linux/ccs_base/common/bin''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      cd "${package}/opt/uniflash"
      exec "${package}/opt/uniflash/dslite.sh" "$@"
    '';
    extraCommands = ''
      # Expose udev rules for services.udev.packages
      if [ -d "${package}/lib/udev" ]; then
        mkdir -p $out/lib/udev
        ln -sf ${package}/lib/udev/* $out/lib/udev/
      fi
    '';
  };

  # GUI wrapper (node-webkit based)
  gui = mkFHSWrapper {
    pname = "uniflash";
    runScript = writeShellScript "uniflash-gui" ''
      export LD_LIBRARY_PATH="${package}/opt/uniflash/deskdb/content/TICloudAgent/linux/ccs_base/DebugServer/drivers:${package}/opt/uniflash/deskdb/content/TICloudAgent/linux/ccs_base/common/bin''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      cd "${package}/opt/uniflash"
      exec "${package}/opt/uniflash/node-webkit/nw" "${package}/opt/uniflash" "$@"
    '';
  };
in
symlinkJoin {
  name = "uniflash-${version}";
  paths = [
    cli
    gui
  ];
  passthru = {
    unwrapped = package;
    inherit cli gui;
  };
  inherit (package) meta;
}
