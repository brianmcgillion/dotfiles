# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Flake-parts modules for flake infrastructure:
# - checks: Pre-commit hooks and code quality checks
# - deployments: Deploy-rs configuration for remote hosts
# - devshells: Repo devshell plus portable per-language shells
# - nixpkgs: Nixpkgs import configuration with overlays
# - treefmt: Code formatting configuration
{
  imports = [
    ./checks.nix
    ./deployments.nix
    ./devshells
    ./nixpkgs.nix
    ./treefmt.nix
  ];
}
