# to use this file with nixd you need to  run
# nix eval --json --file .nixd.nix > .nixd.json
{
  eval = {
    target.args = ["-f" "default.nix"];
    installable = "nixosConfigurations.arcadia";
    depth = 10;
  };
  formatting.command = "nixfmt";
  options = {
    enable = true;
    target = {
      args = [];
      # nixOs configuration
      installable = ".#nixosConfigurations.arcadia.options";
      # flake-parts
      #installable = ".#debug.options";
      # home-manager
      #installable = ".#homeConfigurations.home-manager.options";
    };
  };
}
