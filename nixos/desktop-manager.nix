{ pkgs, ... }:
{
  # Enable the GNOME Desktop Environment.
  services = {
    # Enable the X11 windowing system.
    xserver.enable = true;

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
}
