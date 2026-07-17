# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
# reMarkable USB Web Interface sync tool.
#
# Single source of the sync logic — consumed as a CLI on client systems
# (modules/features/development/remarkable.nix) and by the home-manager
# automation units (home/apps/remarkable.nix).
{
  writeShellApplication,
  curl,
  jq,
  coreutils,
  findutils,
}:
writeShellApplication {
  name = "remarkable-sync";

  runtimeInputs = [
    curl
    jq
    coreutils
    findutils
  ];

  text = builtins.readFile ./remarkable-sync.sh;
}
