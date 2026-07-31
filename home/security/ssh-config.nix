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
      # Safety net for anything that reaches the lab devices by address rather
      # than by alias. ssh matches Host blocks on the name as written on the
      # command line, never the resolved address, so a bare IP matches only
      # "*" -- which carries no IdentityFile -- and drops through to the
      # default ~/.ssh/id_* list, including the verify-required FIDO2 keys.
      #
      # ProxyJump is the case that actually bites: it spawns a separate ssh
      # that re-reads this file by name and does NOT inherit -i or -o from the
      # parent command line, so `ssh -o ProxyJump=root@<ip> -i builderKey ...`
      # puts builderKey on the final hop only and leaves the jump hop asking
      # for a touch. Naming an alias is still the right habit; this only makes
      # the failure mode cheap when some tool does not.
      #
      # Covers net-vm over ethernet and USB, the Orin, and the whole internal
      # 192.168.100.0/24 (ghaf-host, sysvms and appvms), which have no aliases.
      "192.168.10.108 192.168.10.135 192.168.10.149 192.168.100.*" = {
        IdentityFile = builderKey;
        IdentitiesOnly = true;
      };

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
      # IdentitiesOnly on the ghaf devices: without it ssh offers every agent
      # identity and every default ~/.ssh/id_* before falling back to the
      # IdentityFile named here. The FIDO2 keys are verify-required, so each
      # such attempt costs a touch and a PIN even though builderKey is the one
      # that actually authenticates. Deliberately not applied to
      # vedenemo-builder / bmg-sh-gr, which are outside this problem.
      ghaf-net = {
        User = "ghaf";
        IdentityFile = builderKey;
        IdentitiesOnly = true;
        # alternates: 192.168.10.108 (x1-carbon), 192.168.10.34 (usb-ethernet)
        HostName = "192.168.10.108"; # x1-carbon
        #HostName = "192.168.10.229"; # darter-pro
      };
      ghaf-usb = {
        User = "ghaf";
        IdentityFile = builderKey;
        IdentitiesOnly = true;
        HostName = "192.168.10.135"; # usb-ethernet
      };
      ghaf-host = {
        User = "ghaf";
        IdentityFile = builderKey;
        IdentitiesOnly = true;
        HostName = "192.168.100.2";
        ProxyJump = "ghaf-net";
      };
      ghaf-host-usb = {
        User = "ghaf";
        IdentityFile = builderKey;
        IdentitiesOnly = true;
        HostName = "192.168.100.2";
        ProxyJump = "ghaf-usb";
      };
      ghaf-ui = {
        User = "ghaf";
        IdentityFile = builderKey;
        IdentitiesOnly = true;
        HostName = "192.168.100.3";
        ProxyJump = "ghaf-net";
      };
      agx-host = {
        User = "ghaf";
        IdentityFile = builderKey;
        IdentitiesOnly = true;
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
