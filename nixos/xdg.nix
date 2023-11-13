# xdg.nix
#
# Set up and enforce XDG compliance. Other modules will take care of their own,
# but this takes care of the general cases.
_: {
  environment = rec {
    sessionVariables = {
      # These are the defaults, and xdg.enable does set them, but due to load
      # order, they're not set before environment.variables are set, which could
      # cause race conditions.
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      #TODO Make sure that the bin dir is created.
      XDG_BIN_HOME = "$HOME/.local/bin";
      PATH = ["$XDG_BIN_HOME"];
    };
    variables = {
      # Conform more programs to XDG conventions. The rest are handled by their
      # respective modules.
      ASPELL_CONF = ''
        per-conf $XDG_CONFIG_HOME/aspell/aspell.conf;
        personal $XDG_CONFIG_HOME/aspell/en_US.pws;
        repl $XDG_CONFIG_HOME/aspell/en.prepl;
      '';
      #TODO the directory has to be created for the HISTFILE before it can be used so create it
      LESSHISTFILE = "$XDG_CACHE_HOME/lesshst";
      WGETRC = "$XDG_CONFIG_HOME/wgetrc";
      HISTFILE = "\${XDG_CACHE_HOME}/history";
      INPUTRC = "\${XDG_CONFIG_HOME}/inputrc";
    };
  };
}
