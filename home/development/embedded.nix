{ pkgs, ... }:
{
  home.packages = with pkgs; [
    #TODO needs a fix that is in unstable pipeline
    #minicom
    usbutils
  ];
}
