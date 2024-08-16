{ pkgs, ... }:
let
  update-host = pkgs.writeScriptBin "update-host" ''
    pushd $HOME/.dotfiles
    nix flake update
    popd
  '';
  rebuild-host = pkgs.writeScriptBin "rebuild-host" ''
    pushd $HOME/.dotfiles
    sudo nixos-rebuild switch --flake .#$HOSTNAME $@
    popd
  '';
  rebuild-nephele = pkgs.writeScriptBin "rebuild-nephele" ''
    pushd $HOME/.dotfiles
    nixos-rebuild switch --flake .#nephele --target-host "root@nephele" $@
    popd
  '';
  rebuild-caelus = pkgs.writeScriptBin "rebuild-caelus" ''
    pushd $HOME/.dotfiles
    nixos-rebuild switch --flake .#caelus --target-host "root@caelus" $@
    popd
  '';
  rebuild-x1 = pkgs.writeScriptBin "rebuild-x1" ''
    nixos-rebuild --flake .#lenovo-x1-carbon-gen11-debug --target-host "root@ghaf-host" --fast boot $@
  '';
  rebuild-agx = pkgs.writeScriptBin "rebuild-agx" ''
    nixos-rebuild --flake .#nvidia-jetson-orin-agx-debug-from-x86_64 --target-host "root@agx-host" --fast boot $@
  '';
in
#https://discourse.nixos.org/t/install-shell-script-on-nixos/6849/10
#ownfile = pkgs.callPackage ./ownfile.nix {};
{
  environment.systemPackages = [
    rebuild-host
    rebuild-nephele
    rebuild-caelus
    rebuild-x1
    rebuild-agx
    update-host
    #ownfile
  ];
}
