{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.security.gpg;
in
{
  config = mkIf cfg {
    programs.gpg = {
      enable = true;
      # GPG configuration here
    };
  };
}
