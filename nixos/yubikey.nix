{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    yubikey-manager
    age-plugin-yubikey
    yubikey-touch-detector
    age
  ];

  services.pcscd.enable = true;
  services.udev.packages = with pkgs; [yubikey-manager];
}
