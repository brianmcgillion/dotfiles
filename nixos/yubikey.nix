{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.yubikey;
in {
  options.modules.yubikey = {
    enable = mkEnableOption "YubiKey support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      yubikey-manager
      age-plugin-yubikey
      yubikey-touch-detector
      age
    ];

    services.pcscd.enable = true;
    services.udev.packages = with pkgs; [ yubikey-manager ];
  };
}
