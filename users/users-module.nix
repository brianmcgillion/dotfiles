# SPDX-License-Identifier: Apache-2.0
{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = [
    ./bmg.nix
    ./groups.nix
    ./root.nix
  ];

  options.setup.users = {
    enable = mkEnableOption "User configuration";

    enableBmg = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Brian user account";
    };

    enableRoot = mkOption {
      type = types.bool;
      default = false;
      description = "Enable root user account configuration";
    };

    enableGroups = mkOption {
      type = types.bool;
      default = false;
      description = "Enable custom user groups";
    };
  };

  config = {
    # Map the setup.users options to the individual module enable flags
    modules.user-bmg.enable = config.setup.users.enable && config.setup.users.enableBmg;
    modules.user-root.enable = config.setup.users.enable && config.setup.users.enableRoot;
    modules.user-groups.enable = config.setup.users.enable && config.setup.users.enableGroups;
  };
}
