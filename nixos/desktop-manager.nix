{pkgs, ...}: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    evolution
    evolutionWithPlugins
    evolution-data-server
    gnome.geary
    gnome.gnome-music
    gnome.gnome-contacts
    gnome.cheese
  ];
}
