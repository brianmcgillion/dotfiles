{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.security;
in
{
  imports = [
    ./ssh_config.nix
    ./gpg.nix
  ];

  config = mkIf cfg.enable {
    # Enable specific security modules based on their respective flags
    modules.home.security = {
      ssh = lib.mkDefault cfg.ssh;
      gpg = lib.mkDefault false; # Default to disabled
    };
  };
}
