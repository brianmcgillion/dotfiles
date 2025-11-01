# SPDX-License-Identifier: MIT
# Audio support with PipeWire
#
# Configures PipeWire as the system audio server, replacing PulseAudio.
# PipeWire provides low-latency audio with support for both ALSA and PulseAudio clients.
#
# Features:
# - PipeWire audio server
# - ALSA compatibility layer
# - 32-bit ALSA support for compatibility
# - PulseAudio compatibility layer
# - RealtimeKit for priority management
#
# Usage:
#   features.desktop.audio.enable = true;
#
# Enabled by default in: profile-client
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.desktop.audio;
in
{
  options.features.desktop.audio = {
    enable = lib.mkEnableOption "audio support with PipeWire";
  };

  config = lib.mkIf cfg.enable {
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
