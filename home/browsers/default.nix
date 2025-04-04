{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.browsers;
in {
  imports = [
    # Import browser configuration files
    ./firefox.nix
    ./chrome.nix
    ./chromium.nix
  ];

  config = mkIf cfg.enable {
    # Enable specific browser modules based on their respective flags
    modules.home.browsers = {
      firefox = lib.mkDefault cfg.firefox;
      chrome = lib.mkDefault cfg.chrome;
      chromium = lib.mkDefault cfg.chromium;
    };
  };
}
