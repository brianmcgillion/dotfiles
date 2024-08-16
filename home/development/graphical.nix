{ pkgs, ... }:
{
  # graphical tools used for developement
  home.packages = with pkgs; [ bcompare ];
}
