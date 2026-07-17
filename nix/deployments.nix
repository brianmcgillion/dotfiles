# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ self, inputs, ... }:
let
  inherit (inputs) deploy-rs;

  # SSH key of the operator running deploy-rs — the same builder key the
  # target hosts authorize for root, provisioned from sops by
  # features.system.remote-builders (hence /run/secrets, not ~/.ssh).
  # A constant, because pure evaluation (nix flake check, deploy-rs) cannot
  # read $HOME, and reading it out of a host's config would force a full
  # nixosConfiguration eval just to obtain one string.
  sshKeyPath = "/run/secrets/builder-key";

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

  nodes = {
    argus = mkDeployment "x86_64-linux" "argus";
    caelus = mkDeployment "x86_64-linux" "caelus";
    nubes = mkDeployment "x86_64-linux" "nubes";
  };
in
{
  flake = {
    deploy.nodes = nodes;

    checks.x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks { inherit nodes; };
  };
}
