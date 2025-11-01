# SPDX-License-Identifier: MIT
# NVIDIA GPU configuration
#
# Configures NVIDIA proprietary drivers for desktop systems with NVIDIA GPUs.
# Uses production drivers for stability.
#
# Features:
# - NVIDIA modesetting (required for Wayland)
# - Production driver version (stable)
# - Proprietary kernel module (not nouveau)
# - NVIDIA settings application
# - Graphics hardware acceleration
# - X11 and Wayland support
#
# Power management:
# - Standard power management disabled (can cause suspend issues)
# - Fine-grained power management disabled (experimental, Turing+ only)
#
# Driver type:
# - Closed-source kernel module (open=false)
# - Open kernel module only supports Turing and newer
#
# Usage:
#   imports = [ self.nixosModules.hardware-nvidia ];
#
# Used by: arcadia (AMD + NVIDIA desktop)
#
# Note: Requires compatible GPU. Check supported GPUs at:
# https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
{
  config,
  lib,
  ...
}:
{
  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };
    graphics.enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
