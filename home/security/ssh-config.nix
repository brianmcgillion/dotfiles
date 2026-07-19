# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# SSH agent and personal host aliases
#
# These aliases are user-scoped (~/.ssh/config): they carry personal
# usernames and lab addresses, so they don't belong in /etc/ssh/ssh_config
# where they would apply to root and any other account. The build-machine
# aliases used by the nix daemon stay system-wide in
# modules/features/system/remote-builders.nix.
#
# Uses the current programs.ssh.settings API (the old matchBlocks alias is
# deprecated). Attribute names become `Host <name>` blocks and directives use
# upstream OpenSSH names (HostName, User, IdentityFile, ...). enableDefaultConfig
# is turned off and the previous default "*" block is pinned explicitly, so the
# generated config is unchanged and home-manager stops warning about implicit
# defaults being removed.
{ osConfig, ... }:
let
  # Same key the nix daemon uses for the build machines; single-sourced from
  # the remote-builders feature rather than re-typed per host alias.
  builderKey = osConfig.features.system.remote-builders.sshKey;
in
{
  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      # Global defaults (enableDefaultConfig is off, so these are set here).
      "*" = {
        # Never forward the agent globally — it exposes the agent socket to
        # the remote host. ProxyJump (used by the ghaf-* hosts) is the safe
        # alternative.
        ForwardAgent = false;
        # Deliberately NOT "yes". The primary keys are PIN-protected
        # (verify-required) FIDO2 tokens, and the ssh-agent has no way to
        # prompt for the PIN. Loading them into the agent makes ssh (and git
        # signing) route through it and fail with "agent refused operation".
        # Left off so ssh uses the key files directly, where the PIN/touch
        # prompt works. ControlMaster below already gives connection reuse.
        AddKeysToAgent = "no";
        Compression = false;
        # Detect dead connections (roaming laptop, lab boxes over VPN) after
        # ~3 missed 60s probes instead of hanging until the TCP timeout.
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        # Multiplex connections: extra sessions to a host reuse the first
        # authenticated connection — no second YubiKey touch, instant
        # ProxyJump reuse. Master lingers 10m after the last session.
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "10m";
      };

      hetzarm = {
        User = "bmg";
        HostName = "65.21.20.242";
      };
      nubes = {
        HostName = "65.108.111.248";
        Port = 22;
      };
      caelus = {
        HostName = "95.217.167.39";
      };
      vedenemo-builder = {
        User = "bmg";
        HostName = "builder.vedenemo.dev";
        IdentityFile = builderKey;
      };
      ghaf-net = {
        User = "ghaf";
        IdentityFile = builderKey;
        # alternates: 192.168.10.108 (x1-carbon), 192.168.10.34 (usb-ethernet)
        HostName = "192.168.10.229"; # darter-pro
      };
      ghaf-usb = {
        User = "ghaf";
        IdentityFile = builderKey;
        HostName = "192.168.10.34"; # usb-ethernet
      };
      ghaf-host = {
        User = "ghaf";
        IdentityFile = builderKey;
        HostName = "192.168.100.2";
        ProxyJump = "ghaf-net";
      };
      ghaf-host-usb = {
        User = "ghaf";
        IdentityFile = builderKey;
        HostName = "192.168.100.2";
        ProxyJump = "ghaf-usb";
      };
      ghaf-ui = {
        User = "ghaf";
        IdentityFile = builderKey;
        HostName = "192.168.100.3";
        ProxyJump = "ghaf-net";
      };
      agx-host = {
        User = "ghaf";
        IdentityFile = builderKey;
        HostName = "192.168.10.149";
      };
      uae-lab-node1 = {
        User = "bmg";
        HostName = "10.161.5.196";
      };
      bmg-vps = {
        User = "ubuntu";
        HostName = "35.178.208.8";
      };
      bmg-sh-gr = {
        User = "ubuntu";
        HostName = "3.79.116.201";
        IdentityFile = builderKey;
      };
    };
  };
}
