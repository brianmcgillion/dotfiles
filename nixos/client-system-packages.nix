{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.client-system-packages;
in {
  options.modules.client-system-packages = {
    enable = mkEnableOption "Client system packages";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      usbutils
      pciutils
      #Documentation
      linux-manual
      man-pages
      man-pages-posix
      #    nix-doc
    ];
  };
}
