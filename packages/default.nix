# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
_: {
  flake = {
    nixosModules = {
      scripts = import ./scripts;
    };

    overlays.own-pkgs-overlay = final: _prev: {
      # ghidra-mcp-bridge = final.callPackage ./ghidra-mcp-bridge/default.nix { };
      # ghidra-mcp-extension = final.callPackage ./ghidra-mcp-extension/default.nix {
      #   inherit (final) ghidra;
      # };
      rebiber = final.callPackage ./rebiber/default.nix { };
      stm32cubeprogrammer = final.callPackage ./stm32cubeprogrammer/default.nix { };
      svd2py = final.callPackage ./svd2py/default.nix { };

      # claude-code 2.1.88 was unpublished from npm; override to 2.1.91
      # Remove once nixpkgs updates to a version that exists on npm.
      claude-code = final.callPackage ./claude-code/default.nix { };
    };
  };
}
