{ self, inputs, ... }:
let
  inherit (inputs) deploy-rs;

  mkDeployment = arch: hostname: {
    inherit hostname;
    profiles.system = {
      user = "root";
      path = deploy-rs.lib.${arch}.activate.nixos self.nixosConfigurations.${hostname};
    };
  };

  x86-nodes = {
    nephele = mkDeployment "x86_64-linux" "nephele";
    caelus = mkDeployment "x86_64-linux" "caelus";
  };

  aarch64-nodes = {
    #name = mkDeployment "aarch64-linux" "name" "ip";
  };
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
