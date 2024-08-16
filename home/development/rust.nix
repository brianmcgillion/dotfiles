{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rust-analyzer
    rustc
    rustfmt
    cargo
    cargo-clone
    clippy
  ];
}
