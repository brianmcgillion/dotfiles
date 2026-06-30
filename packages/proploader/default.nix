# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# PropLoader: Parallax's command-line loader for the Propeller (P8X32A). Loads
# programs into Propeller RAM/EEPROM over serial (or WiFi). Useful for flashing
# and updating Propeller-based hardware such as the JTAGulator.
#
# Build notes: the upstream Makefile builds out-of-tree into
# ../proploader-<os>-build, does not auto-detect the OS for non-Windows hosts
# (so OS=linux must be passed), and derives VERSION from `git describe` (absent
# in the sandbox, hence the explicit VERSION). The second-stage loader is a Spin
# program compiled with openspin at build time and embedded into the binary via
# the in-tree bin2c/split helpers, so there are no runtime data files.
{
  lib,
  stdenv,
  fetchFromGitHub,
  openspin,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "proploader";
  version = "1.0-37-unstable-2023-06-14";

  src = fetchFromGitHub {
    owner = "parallaxinc";
    repo = "PropLoader";
    rev = "a1b4cd87cedfb1141d9be888335bca130b486425";
    hash = "sha256-IkkgM0qy7PDbIQwI23R6QzXPrx+awVIqunkBVq5iIEE=";
  };

  nativeBuildInputs = [ openspin ];

  strictDeps = true;

  # The dir-creation rules (%/created) race under parallel make.
  enableParallelBuilding = false;

  makeFlags = [
    "OS=linux"
    "VERSION=${finalAttrs.version}"
  ];

  # Upstream's `install` target copies to ~/bin; the artifact lands out-of-tree.
  installPhase = ''
    runHook preInstall
    install -Dm755 ../proploader-linux-build/bin/proploader "$out/bin/proploader"
    runHook postInstall
  '';

  meta = {
    description = "Command-line loader for the Parallax Propeller (e.g. flashing the JTAGulator)";
    homepage = "https://github.com/parallaxinc/PropLoader";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "proploader";
  };
})
