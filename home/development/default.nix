{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.development;
in
{
  imports = [
    ./base_system.nix
    ./graphical.nix
    ./embedded.nix
  ];

  config = mkIf cfg.enable {
    # Enable specific development modules based on their respective flags
    modules.home.development = {
      base = lib.mkDefault cfg.base;
      graphical = lib.mkDefault cfg.graphical;
      embedded = lib.mkDefault cfg.embedded;
    };
  };
}
