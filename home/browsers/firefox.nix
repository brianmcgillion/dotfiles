{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.browsers.firefox;
in {
  config = mkIf cfg {
    programs.firefox = {
      enable = true;
      # Add your Firefox configuration here
    };
  };
}
