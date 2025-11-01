# SPDX-License-Identifier: MIT
# Home-manager server profile
{ ... }:
{
  imports = [
    ../home.nix
    ../shell/basic.nix
    ../shell/fzf.nix
  ];
}
