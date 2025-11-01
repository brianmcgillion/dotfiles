# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# Home-manager server profile
{ ... }:
{
  imports = [
    ../home.nix
    ../shell/basic.nix
    ../shell/fzf.nix
  ];
}
