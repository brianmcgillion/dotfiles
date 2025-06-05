_: {
  flake = {
    nixosModules = {
      scripts = import ./scripts;
    };

    overlays.own-pkgs-overlay = final: _prev: {
      rebiber = final.callPackage ./rebiber/default.nix { };
    };
  };
}
