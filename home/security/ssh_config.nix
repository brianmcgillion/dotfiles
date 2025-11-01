# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
_: {
  programs.ssh = { };

  services = {
    ssh-agent.enable = true;
  };
}
