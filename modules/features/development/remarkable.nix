# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# reMarkable tablet integration tools
#
# Provides tools for syncing and managing reMarkable Paper Pro tablet.
# Enables bidirectional workflow between Emacs org-mode and reMarkable.
#
# Uses USB Web Interface (http://10.11.99.1) - NO developer mode required!
# Enable on device: Settings → Storage → USB web interface
#
# Features:
# - remarkable-sync: CLI sync tool (shared package, see
#   packages/remarkable-sync/ — also used by the home-manager automation
#   units in home/apps/remarkable.nix)
# - rmapi: Command-line access to reMarkable Cloud API (optional)
#
# Usage:
#   features.development.remarkable.enable = true;
#
# Enabled by default in: profile-client
#
# Workflow:
# - Export org-mode notes to PDF for reading on reMarkable
# - Download annotated PDFs (annotations pre-rendered by device)
# - Use org-noter to add structured notes to annotated PDFs
# - Integrate with citar for academic paper management
#
# See also: Emacs config.org reMarkable section for Elisp integration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development.remarkable;
in
{
  options.features.development.remarkable = {
    enable = lib.mkEnableOption "reMarkable tablet integration tools";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      # keep-sorted start
      pkgs.remarkable-sync # USB web interface sync script
      pkgs.rmapi # Cloud API CLI (optional, for evaluation)
      # keep-sorted end
    ];

    # Ensure USB RNDIS networking works (reMarkable appears as USB ethernet)
    # NetworkManager usually handles this automatically, but we ensure the module is loaded
    boot.kernelModules = [
      "rndis_host"
      "cdc_ether"
    ];
  };
}
