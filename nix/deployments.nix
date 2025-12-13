# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ self, inputs, ... }:
let
  inherit (inputs) deploy-rs;

  # Use impure evaluation to get HOME, or fallback to config value
  sshKeyPath =
    let
      home = builtins.getEnv "HOME";
      # Get SSH key from system configuration (using caelus as reference)
      configKey = self.nixosConfigurations.arcadia.config.common.remoteBuild.sshKey or null;
    in
    if home != "" then
      "${home}/.ssh/builder-key"
    else if configKey != null then
      configKey
    else
      throw "Cannot determine SSH key path for deployment. Set HOME environment variable or configure common.remoteBuild.sshKey.";

  mkDeployment = arch: hostname: {
    inherit hostname;
    profiles.system = {
      user = "root";
      path = deploy-rs.lib.${arch}.activate.nixos self.nixosConfigurations.${hostname};
      sshUser = "root";
      sshOpts = [
        "-i"
        sshKeyPath
        "-o"
        "StrictHostKeyChecking=accept-new"
      ];
    };
  };

  x86-nodes = {
    caelus = mkDeployment "x86_64-linux" "caelus";
    nubes = mkDeployment "x86_64-linux" "nubes";
  };

  aarch64-nodes = { };
in
{
  flake = {
    deploy.nodes = x86-nodes // aarch64-nodes;

    checks = {
      x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks { nodes = x86-nodes; };
      aarch64-linux = deploy-rs.lib.aarch64-linux.deployChecks { nodes = aarch64-nodes; };
    };
  };
}
