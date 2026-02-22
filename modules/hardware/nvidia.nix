# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
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
# - Enables nvidia-suspend/resume/hibernate systemd services
# - Sets NVreg_PreserveVideoMemoryAllocations=1 to save VRAM on suspend
# - Required for working S3 suspend/resume with proprietary driver
# - Fine-grained power management disabled (runtime D3, laptops only)
#
# Driver type:
# - Defaults to closed-source kernel module (open=false via mkDefault)
# - Hosts can override with hardware.nvidia.open = true
# - Blackwell+ GPUs (e.g. RTX 5080) require open = true
# - Open kernel module supports Turing and newer
#
# Usage:
#   imports = [ self.nixosModules.hardware-nvidia ];
#
# Used by: arcadia (AMD + NVIDIA desktop), argus (Intel + NVIDIA desktop)
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
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = lib.mkDefault false;
      nvidiaSettings = true;
      package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.production;
    };
    graphics.enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
