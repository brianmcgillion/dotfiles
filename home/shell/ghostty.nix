# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
_: {
  programs = {
    ghostty = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        font-size = 10;
        shell-integration-features = "no-cursor,sudo,no-title";
        theme = "Dracula";
      };
    };
  };
}
