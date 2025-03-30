{ pkgs, ... }:
{
  # graphical tools used for development
  home.packages = with pkgs; [
    bcompare
    mendeley
  ];
  #services.flameshot.enable = true;
}
