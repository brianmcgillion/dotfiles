#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# direnv library function for generating nixd LSP configuration
#
# This provides a reusable `use_nixd` function that automatically generates
# .nixd.json configuration for nixd language server based on project type.
#
# Usage in any project's .envrc:
#   use_nixd
#
# Supports:
# - NixOS flake configurations (nixosConfigurations)
# - Home-manager flake configurations (homeConfigurations)
# - Generic flakes (packages, devShells)
# - Non-flake Nix projects
#
# The function automatically detects project type and generates appropriate
# .nixd.json with proper evaluation targets and options.

use_nixd() {
  local flake_path
  flake_path=$(pwd)

  # Check if this is a flake project
  if [[ ! -f "flake.nix" ]]; then
    log_status "No flake.nix found, skipping nixd configuration"
    return
  fi

  log_status "Generating nixd configuration..."

  # Detect project type and available configurations
  local has_nixos_configs=false
  local has_home_configs=false
  local hostname
  local username

  hostname=$(hostname)
  username="${USER}"

  # Check if nixosConfigurations exist
  if nix flake show --json 2>/dev/null | jq -e '.nixosConfigurations' >/dev/null 2>&1; then
    has_nixos_configs=true
  fi

  # Check if homeConfigurations exist
  if nix flake show --json 2>/dev/null | jq -e '.homeConfigurations' >/dev/null 2>&1; then
    has_home_configs=true
  fi

  # Generate .nixd.json based on project type
  if [[ $has_nixos_configs == "true" ]]; then
    # NixOS configuration project
    _generate_nixos_nixd_config "$flake_path" "$hostname" "$username"
  elif [[ $has_home_configs == "true" ]]; then
    # Home-manager configuration project
    _generate_home_manager_nixd_config "$flake_path" "$username" "$hostname"
  else
    # Generic flake project (packages, devShells, etc.)
    _generate_generic_nixd_config "$flake_path"
  fi

  log_status "nixd configuration generated at .nixd.json"
}

_generate_nixos_nixd_config() {
  local flake_path=$1
  local hostname=$2
  local username=$3

  cat >.nixd.json <<EOF
{
  "eval": {
    "target": {
      "installable": "${flake_path}#nixosConfigurations.${hostname}.config.system.build.toplevel"
    },
    "workers": 3
  },
  "formatting": {
    "command": ["nixfmt"]
  },
  "options": {
    "nixos": {
      "expr": "(builtins.getFlake \"path:${flake_path}\").nixosConfigurations.${hostname}.options"
    },
    "home-manager": {
      "expr": "(builtins.getFlake \"path:${flake_path}\").nixosConfigurations.${hostname}.config.home-manager.users.${username}.options"
    }
  }
}
EOF
}

_generate_home_manager_nixd_config() {
  local flake_path=$1
  local username=$2
  local hostname=$3

  # Try common home-manager configuration patterns
  local config_name="${username}@${hostname}"

  cat >.nixd.json <<EOF
{
  "eval": {
    "target": {
      "installable": "${flake_path}#homeConfigurations.\"${config_name}\".activationPackage"
    },
    "workers": 3
  },
  "formatting": {
    "command": ["nixfmt"]
  },
  "options": {
    "home-manager": {
      "expr": "(builtins.getFlake \"path:${flake_path}\").homeConfigurations.\"${config_name}\".options"
    }
  }
}
EOF
}

_generate_generic_nixd_config() {
  local flake_path=$1

  cat >.nixd.json <<EOF
{
  "eval": {
    "target": {
      "installable": "${flake_path}"
    },
    "workers": 3
  },
  "formatting": {
    "command": ["nixfmt"]
  },
  "options": {
    "nixpkgs": {
      "expr": "import (builtins.getFlake \"path:${flake_path}\").inputs.nixpkgs { }"
    }
  }
}
EOF
}
