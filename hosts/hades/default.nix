# SPDX-License-Identifier: MIT
{ ... }:
{
  imports = [ (import ./hardware-configuration.nix) ] ++ [ (import ./networking.nix) ];

  # Bootloader.
  boot = {
    # Setup keyfile
    initrd.secrets = {
      "/crypto_keyfile.bin" = null;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.05";
}
