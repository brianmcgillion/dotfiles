{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.browsers.chromium;
in
{
  config = mkIf cfg {
    programs.chromium = {
      enable = true;
      # Add your Chromium configuration here
    };
  };
}
