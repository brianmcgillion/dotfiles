# Nixpkgs based installation of linux shell enhancing tools
#
#
#
_: {
  imports = [./basic.nix ./fzf.nix ./git.nix ./terminator.nix];
}
