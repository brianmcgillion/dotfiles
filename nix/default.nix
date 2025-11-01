# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
# Flake-parts modules for flake infrastructure:
# - checks: Pre-commit hooks and code quality checks
# - deployments: Deploy-rs configuration for remote hosts
# - devshell: Development shell with tools and utilities
# - nixpkgs: Nixpkgs import configuration with overlays
# - treefmt: Code formatting configuration
{
  imports = [
    ./checks.nix
    ./deployments.nix
    ./devshell.nix
    ./nixpkgs.nix
    ./treefmt.nix
  ];
}
