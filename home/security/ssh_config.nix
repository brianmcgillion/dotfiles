_: {
  programs.ssh = {
    extraConfig = ''
      host ghaf
           user ghaf
           hostname 192.168.10.149
    '';
  };

  services = {
    ssh-agent.enable = true;
  };
}
