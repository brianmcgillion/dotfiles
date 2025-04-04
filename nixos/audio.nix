# SPDX-License-Identifier: Apache-2.0
{ config, lib, pkgs, ... }:

let 
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.audio;
in {
  options.modules.audio = {
    enable = mkEnableOption "Audio configuration";
  };

  config = mkIf cfg.enable {
    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
