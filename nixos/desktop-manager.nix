{ pkgs, ... }:
{
  # Enable the GNOME Desktop Environment.
  services = {
    # Enable the X11 windowing system.
    xserver.enable = true;

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    # disable gnome managing the ssh-agent
    #gnome.gcr-ssh-agent.enable = false;
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
