{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.shell;
in {
  imports = [
    ./basic.nix
    ./fzf.nix
    ./git.nix
    ./terminator.nix
    ./kitty.nix
    ./ghostty.nix
    ./tmux.nix
  ];

  config = mkIf cfg.enable {
    # Enable specific shell modules based on their respective flags
    modules.home.shell = {
      basic = lib.mkDefault cfg.basic;
      fzf = lib.mkDefault cfg.fzf;
      git = lib.mkDefault cfg.git;
      kitty = lib.mkDefault cfg.kitty;
      terminator = lib.mkDefault cfg.terminator;
      ghostty = lib.mkDefault cfg.ghostty;
      tmux = lib.mkDefault cfg.tmux;
    };
  };
}
