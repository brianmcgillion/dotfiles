{pkgs, ...}: {
  #environment.systemPackages = with pkgs; [
  home.packages = with pkgs; [
    rust-analyzer
    rustc
    rustfmt
    tree-sitter-grammars.tree-sitter-rust
    cargo
    cargo-clone
    clippy
  ];
}
