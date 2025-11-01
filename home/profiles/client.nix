# SPDX-License-Identifier: MIT
# Home-manager client profile
{ ... }:
{
  imports = [
    ../home.nix
    ../apps
    ../browsers
    ../development
    ../security
    ../shell
  ];
}
