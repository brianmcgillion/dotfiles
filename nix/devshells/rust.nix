# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Rust toolchain. Entered from anywhere with `dev rust`.
{
  perSystem =
    { pkgs, ... }:
    {
      devshells.rust = {
        devshell = {
          name = "rust";
          meta.description = "Rust toolchain: cargo, clippy, rust-analyzer";
          packages = [
            # keep-sorted start
            pkgs.cargo
            pkgs.cargo-audit
            pkgs.cargo-deny
            pkgs.cargo-edit
            pkgs.cargo-expand
            pkgs.cargo-nextest
            pkgs.cargo-watch
            pkgs.clippy
            pkgs.mold
            pkgs.openssl
            pkgs.pkg-config
            pkgs.rust-analyzer
            pkgs.rustc
            pkgs.rustfmt
            # keep-sorted end
          ];
        };

        env = [
          # rust-analyzer resolves std sources through this; without it
          # go-to-definition into std silently fails.
          {
            name = "RUST_SRC_PATH";
            value = "${pkgs.rustPlatform.rustLibSrc}";
          }
          {
            name = "RUST_BACKTRACE";
            value = "1";
          }
        ];
      };
    };
}
