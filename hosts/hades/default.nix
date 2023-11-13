# SPDX-License-Identifier: MIT
{ ...}: {
  imports =
    [(import ./hardware-configuration.nix)]
    ++ [(import ./networking.nix)];

  # Bootloader.
  boot = {
    # Setup keyfile
    initrd.secrets = {
      "/crypto_keyfile.bin" = null;
    };
  };
}
