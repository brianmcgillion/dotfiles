# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
let
  update-host = pkgs.writeScriptBin "update-host" ''
    pushd $HOME/.dotfiles
    nix flake update
    popd
  '';
  rebuild-host = pkgs.writeScriptBin "rebuild-host" ''
    pushd $HOME/.dotfiles
    sudo nixos-rebuild switch --flake .#$HOSTNAME "$@"
    popd
  '';
  rebuild-nubes = pkgs.writeScriptBin "rebuild-nubes" ''
    pushd $HOME/.dotfiles
    nixos-rebuild switch --flake .#nubes --target-host "root@nubes" "$@"
    popd
  '';
  rebuild-caelus = pkgs.writeScriptBin "rebuild-caelus" ''
    pushd $HOME/.dotfiles
    nixos-rebuild switch --flake .#caelus --target-host "root@caelus" "$@"
    popd
  '';
  rebuild-x1 = pkgs.writeScriptBin "rebuild-x1" ''
    nixos-rebuild --flake .#lenovo-x1-carbon-gen11-debug --target-host "root@ghaf-host" --no-reexec boot "$@"
  '';
  rebuild-alien = pkgs.writeScriptBin "rebuild-alien" ''
    nixos-rebuild --flake .#alienware-m18-debug --target-host "root@ghaf-host" --no-reexec boot "$@"
  '';
  rebuild-agx = pkgs.writeScriptBin "rebuild-agx" ''
    nixos-rebuild --flake .#nvidia-jetson-orin-agx-debug-from-x86_64 --target-host "root@agx-host" --no-reexec boot "$@"
  '';
  rebuild-darter = pkgs.writeScriptBin "rebuild-darter" ''
    nixos-rebuild --flake .#system76-darp11-b-debug --target-host "root@ghaf-host" --no-reexec boot "$@"
  '';
in
#https://discourse.nixos.org/t/install-shell-script-on-nixos/6849/10
#ownfile = pkgs.callPackage ./ownfile.nix {};
{
  environment.systemPackages = [
    # keep-sorted start
    rebuild-agx
    rebuild-alien
    rebuild-caelus
    rebuild-darter
    rebuild-host
    rebuild-nubes
    rebuild-x1
    update-host
    #ownfile
    # keep-sorted end
  ];
}
