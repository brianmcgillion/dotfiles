{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.user-groups;
in {
  options.modules.user-groups = {
    enable = mkEnableOption "User groups configuration";
  };

  config = mkIf cfg.enable {
    users.groups = {
      # Add the plugdev group with no members, do be used as required
      plugdev = { };
    };
  };
}
