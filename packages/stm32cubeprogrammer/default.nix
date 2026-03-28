# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
{
  stdenvNoCC,
  lib,
  requireFile,
  unzip,
  jdk21,
  openjfx21,
  makeWrapper,
  buildFHSEnv,
  makeDesktopItem,
  writeShellScript,
  symlinkJoin,
}:

let
  version = "2.22.0";

  desktopItem = makeDesktopItem {
    name = "STM32CubeProgrammer";
    exec = "STM32CubeProgrammer";
    desktopName = "STM32CubeProgrammer";
    categories = [ "Development" ];
    comment = "STM32 device programming tool";
    terminal = false;
    startupNotify = false;
  };

  package = stdenvNoCC.mkDerivation {
    pname = "stm32cubeprogrammer-unwrapped";
    inherit version;

    # This mechanism requires that the file is registered in the nix store
    # nix-store --add-fixed sha256 /path/to/SetupSTM32CubeProgrammer_linux_64.zip
    src = requireFile {
      name = "SetupSTM32CubeProgrammer_linux_64.zip";
      url = "https://www.st.com/en/development-tools/stm32cubeprog.html";
      hash = "sha256-//oBertNoUWC4Smqmh5Ph+bQcZo8uVDAGE9MtIq2Cqc=";
    };

    nativeBuildInputs = [
      unzip
      makeWrapper
      jdk21
    ];

    dontConfigure = true;
    dontPatchELF = true;
    dontStrip = true;

    unpackPhase = ''
      runHook preUnpack
      unzip $src
      runHook postUnpack
    '';

    buildPhase = ''
      runHook preBuild

      # Create auto-install descriptor for IzPack silent installation
      # Panel IDs extracted from resources/panelsOrder in the installer JAR
      cat > auto-install.xml << AUTOXML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <AutomatedInstallation langpack="eng">
          <com.st.CustomPanels.CheckedHelloPorgrammerPanel id="Hello.panel"/>
          <com.izforge.izpack.panels.info.InfoPanel id="Info.panel"/>
          <com.izforge.izpack.panels.licence.LicencePanel id="Licence.panel"/>
          <com.st.CustomPanels.TargetProgrammerPanel id="target.panel">
              <installpath>$TMPDIR/stm32cubeprog-install</installpath>
          </com.st.CustomPanels.TargetProgrammerPanel>
          <com.st.CustomPanels.AnalyticsPanel id="analytics.panel">
              <entry key="Analytics" value="Disable"/>
          </com.st.CustomPanels.AnalyticsPanel>
          <com.st.CustomPanels.PacksProgrammerPanel id="Packs.panel">
              <pack index="0" name="Core Files" selected="true"/>
              <pack index="1" name="STM32CubeProgrammer" selected="true"/>
              <pack index="2" name="STM32TrustedPackageCreator" selected="true"/>
          </com.st.CustomPanels.PacksProgrammerPanel>
          <com.izforge.izpack.panels.install.InstallPanel id="Install.panel"/>
          <com.izforge.izpack.panels.shortcut.ShortcutPanel id="Shortcut.panel"/>
          <com.st.CustomPanels.FinishProgrammerPanel id="finish.panel"/>
      </AutomatedInstallation>
      AUTOXML

      # Run the IzPack installer using nixpkgs JDK
      # HOME must be writable because the installer tries to modify .bashrc
      export HOME="$TMPDIR/fakehome"
      mkdir -p "$HOME"
      touch "$HOME/.bashrc"

      java -jar SetupSTM32CubeProgrammer-${version}.exe auto-install.xml \
        || true  # Installer may return non-zero even on success

      # Verify installation succeeded
      test -d "$TMPDIR/stm32cubeprog-install/bin" \
        || (echo "Installation failed: bin directory not found"; exit 1)

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      local installDir="$TMPDIR/stm32cubeprog-install"

      # Main application directory
      mkdir -p $out/opt/STM32CubeProgrammer
      cp -r "$installDir"/. $out/opt/STM32CubeProgrammer/

      # Copy the bundled JRE (includes JavaFX, needed for GUI)
      # The JRE is extracted from the zip alongside the installer, not inside the install target
      cp -r jre $out/opt/STM32CubeProgrammer/jre

      # Ensure binaries are executable
      chmod +x $out/opt/STM32CubeProgrammer/bin/STM32_Programmer_CLI \
               $out/opt/STM32CubeProgrammer/bin/STM32_SigningTool_CLI \
               $out/opt/STM32CubeProgrammer/bin/STM32TrustedPackageCreator_CLI \
        2>/dev/null || true

      # Install udev rules
      if [ -d "$installDir/Drivers/rules" ]; then
        mkdir -p $out/lib/udev/rules.d
        cp "$installDir"/Drivers/rules/*.rules $out/lib/udev/rules.d/
      fi

      # Build OpenJFX module JARs from the exploded module directories
      # JDK 21's --module-path requires JARs, not exploded class dirs
      mkdir -p $out/opt/STM32CubeProgrammer/javafx-modules
      for mod in ${openjfx21}/modules/javafx.*; do
        modname=$(basename "$mod")
        jar --create --file "$out/opt/STM32CubeProgrammer/javafx-modules/$modname.jar" -C "$mod" .
      done

      # Desktop entry
      mkdir -p $out/share/applications
      cp ${desktopItem}/share/applications/*.desktop $out/share/applications/

      runHook postInstall
    '';

    meta = {
      description = "All-in-one software tool to program STM32 devices";
      longDescription = ''
        STM32CubeProgrammer provides an all-in-one software tool to program
        STM32 devices in any environment: multi-OS, graphical user interface,
        or command line interface. It supports JTAG, SWD, USB, UART, SPI,
        CAN, and I2C connections.
      '';
      homepage = "https://www.st.com/en/development-tools/stm32cubeprog.html";
      sourceProvenance = with lib.sourceTypes; [
        binaryNativeCode
        binaryBytecode
      ];
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

      # Graphics / Qt deps
      libGL
      libdrm
      libgbm
      libxkbcommon
      libx11
      libxrender
      libxrandr
      libxcb
      libxext
      libxfixes
      libxcomposite
      libxdamage
      libxi
      libxcursor
      libxtst
      freetype
      fontconfig
      xrdb

      # GTK / desktop integration
      gtk3
      glib
      pango
      cairo
      at-spi2-atk
      dbus

      # Crypto
      openssl
      krb5

      # General
      zlib
      cups
      nspr
      nss
      expat
      alsa-lib
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

  # GUI wrapper
  gui = mkFHSWrapper {
    pname = "stm32cubeprogrammer";
    runScript = writeShellScript "stm32cubeprogrammer-gui" ''
      export LD_LIBRARY_PATH="${package}/opt/STM32CubeProgrammer/lib:${openjfx21}/modules_libs/javafx.graphics:${openjfx21}/modules_libs/javafx.media:${openjfx21}/modules_libs/javafx.base''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      # App expects to run from its bin directory for relative path lookups
      cd "${package}/opt/STM32CubeProgrammer/bin"

      # HiDPI scaling: GDK_SCALE works at the GTK level for XWayland apps
      # Override with STM32CUBEPROG_SCALE env var (default: 3 for HiDPI displays)
      export GDK_SCALE=''${STM32CUBEPROG_SCALE:-3}
      export GDK_DPI_SCALE=1

      exec ${jdk21}/bin/java \
        --module-path "${package}/opt/STM32CubeProgrammer/javafx-modules" \
        --add-modules javafx.controls,javafx.fxml,javafx.swing,javafx.graphics \
        --add-opens javafx.graphics/com.sun.javafx.css=ALL-UNNAMED \
        --add-opens javafx.graphics/com.sun.glass.ui=ALL-UNNAMED \
        --add-opens javafx.graphics/com.sun.javafx.application=ALL-UNNAMED \
        --add-opens javafx.base/com.sun.javafx.runtime=ALL-UNNAMED \
        --add-exports javafx.graphics/com.sun.glass.ui=ALL-UNNAMED \
        --add-exports javafx.graphics/com.sun.javafx.application=ALL-UNNAMED \
        -jar "${package}/opt/STM32CubeProgrammer/bin/STM32CubeProgrammerLauncher" "$@"
    '';
    extraCommands = ''
      mkdir -p $out/share/applications
      ln -sf ${package}/share/applications/* $out/share/applications/

      # Expose udev rules for services.udev.packages
      if [ -d "${package}/lib/udev" ]; then
        mkdir -p $out/lib/udev
        ln -sf ${package}/lib/udev/* $out/lib/udev/
      fi
    '';
  };

  # CLI wrapper
  cli = mkFHSWrapper {
    pname = "STM32_Programmer_CLI";
    runScript = writeShellScript "stm32-programmer-cli" ''
      export LD_LIBRARY_PATH="${package}/opt/STM32CubeProgrammer/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      cd "${package}/opt/STM32CubeProgrammer/bin"
      exec "${package}/opt/STM32CubeProgrammer/bin/STM32_Programmer_CLI" "$@"
    '';
  };

  # Signing tool CLI wrapper
  signingCli = mkFHSWrapper {
    pname = "STM32_SigningTool_CLI";
    runScript = writeShellScript "stm32-signingtool-cli" ''
      export LD_LIBRARY_PATH="${package}/opt/STM32CubeProgrammer/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      cd "${package}/opt/STM32CubeProgrammer/bin"
      exec "${package}/opt/STM32CubeProgrammer/bin/STM32_SigningTool_CLI" "$@"
    '';
  };

  # TPC GUI wrapper
  tpc = mkFHSWrapper {
    pname = "STM32TrustedPackageCreator";
    runScript = writeShellScript "stm32-tpc" ''
      export LD_LIBRARY_PATH="${package}/opt/STM32CubeProgrammer/lib:${openjfx21}/modules_libs/javafx.graphics:${openjfx21}/modules_libs/javafx.media:${openjfx21}/modules_libs/javafx.base''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      cd "${package}/opt/STM32CubeProgrammer/bin"

      scale=''${GDK_SCALE:-1}
      if command -v xrdb >/dev/null 2>&1; then
        dpi=$(xrdb -query 2>/dev/null | grep -i "Xft.dpi" | awk '{print $2}')
        if [ -n "$dpi" ] && [ "$dpi" -gt 96 ] 2>/dev/null; then
          scale=$(( dpi / 96 ))
        fi
      fi

      exec ${jdk21}/bin/java \
        --module-path "${package}/opt/STM32CubeProgrammer/javafx-modules" \
        --add-modules javafx.controls,javafx.fxml,javafx.swing,javafx.graphics \
        --add-opens javafx.graphics/com.sun.javafx.css=ALL-UNNAMED \
        --add-opens javafx.graphics/com.sun.glass.ui=ALL-UNNAMED \
        --add-opens javafx.graphics/com.sun.javafx.application=ALL-UNNAMED \
        --add-opens javafx.base/com.sun.javafx.runtime=ALL-UNNAMED \
        --add-exports javafx.graphics/com.sun.glass.ui=ALL-UNNAMED \
        --add-exports javafx.graphics/com.sun.javafx.application=ALL-UNNAMED \
        -Dglass.gtk.uiScale="$scale" \
        -jar "${package}/opt/STM32CubeProgrammer/bin/STM32TrustedPackageCreator" "$@"
    '';
  };
in
symlinkJoin {
  name = "stm32cubeprogrammer-${version}";
  paths = [
    gui
    cli
    signingCli
    tpc
  ];
  passthru = {
    unwrapped = package;
    inherit
      gui
      cli
      signingCli
      tpc
      ;
  };
  inherit (package) meta;
}
