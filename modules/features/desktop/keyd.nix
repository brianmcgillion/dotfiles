# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Brian McGillion
# Per-device keyboard remapping via keyd
#
# Unlike global XKB options, keyd can target specific keyboards by device ID,
# making it ideal for setups with programmable external keyboards that handle
# their own remapping.
#
# Usage:
#   features.desktop.keyd = {
#     enable = true;
#     keyboards.internal = {
#       ids = [ "0001:0001" ];
#       settings.main = {
#         capslock = "leftcontrol";
#         leftcontrol = "capslock";
#       };
#     };
#   };
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.desktop.keyd;
in
{
  options.features.desktop.keyd = {
    enable = lib.mkEnableOption "per-device keyboard remapping via keyd";

    keyboards = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Keyboard configs passed to services.keyd.keyboards. Use `sudo keyd monitor` to find device IDs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.keyd = {
      enable = true;
      inherit (cfg) keyboards;
    };
  };
}
