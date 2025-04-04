{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.desktop-manager;
in
{
  options.modules.desktop-manager = {
    enable = mkEnableOption "Desktop manager configuration";
  };

  config = mkIf cfg.enable {
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.xserver = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      epiphany
      evolution
      evolutionWithPlugins
      evolution-data-server
      geary
      gnome-music
      gnome-contacts
      cheese
    ];
  };
}
