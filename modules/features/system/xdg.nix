# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# XDG Base Directory specification compliance
#
# Enforces XDG Base Directory specification to keep $HOME clean and organized.
# Sets environment variables to encourage XDG-compliant applications.
#
# XDG directories:
# - XDG_CONFIG_HOME: ~/.config (application configuration)
# - XDG_DATA_HOME: ~/.local/share (application data)
# - XDG_CACHE_HOME: ~/.cache (application caches)
# - XDG_BIN_HOME: ~/.local/bin (user executables)
#
# Configured applications:
# - aspell: Configuration and dictionaries
# - less: History file
# - wget: Configuration file
# - bash: History file
# - readline: Input configuration
#
# Usage:
#   features.system.xdg.enable = true;
#
# Enabled by default in: profile-common (applies to all systems)
#
# Benefits:
# - Cleaner home directory
# - Easier backup (know what to include/exclude)
# - Better separation of config, data, and cache
# - Consistent application behavior
#
# Note: Not all applications respect XDG variables.
# Additional configuration may be needed per-application.
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.system.xdg;
in
{
  options.features.system.xdg = {
    enable = lib.mkEnableOption "XDG base directory compliance";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      sessionVariables = {
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_BIN_HOME = "$HOME/.local/bin";
        PATH = [ "\${XDG_BIN_HOME}" ];
      };
      variables = {
        ASPELL_CONF = ''
          per-conf $XDG_CONFIG_HOME/aspell/aspell.conf;
          personal $XDG_CONFIG_HOME/aspell/aspell.en.pws;
          repl $XDG_CONFIG_HOME/aspell/en.prepl;
        '';
        LESSHISTFILE = "\${XDG_CACHE_HOME}/lesshst";
        WGETRC = "\${XDG_CONFIG_HOME}/wgetrc";
        HISTFILE = "\${XDG_CACHE_HOME}/history";
        INPUTRC = "\${XDG_CONFIG_HOME}/inputrc";
      };
    };
  };
}
