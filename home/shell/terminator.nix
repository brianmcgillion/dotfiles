{config, ...}: {
  programs = {
    terminator = {
      enable = true;
      config = {
        global_config.suppress_multiple_term_dialog = true;

        profiles.default = {
          background_color = "#1c1d1f";
          background_darkness = 0.43;
          cursor_color = "#708284";
          font = "Fira Code 12";
          foreground_color = "#eeeeec";
          scrollback_infinite = true;
          palette = "#56595c:#c94c22:#85981c:#b4881d:#2e8bce:#d13a82:#32a198:#c9c6bd:#45484b:#bd3613:#738a04:#a57705:#2176c7:#c61c6f:#259286:#c9c6bd";
          use_system_font = false;
        };

        layouts.default.root = {
          position = 0;
          type = "Window";
          order = 0;
          parent = "";
          maximised = true;
          fullscreen = false;
          #       size = 1920, 1016
        };
        layouts.default.grand = {
          position = 536;
          type = "HPaned";
          order = 0;
          parent = "root";
        };
        layouts.default.left = {
          position = 536;
          type = "VPaned";
          order = 0;
          parent = "grand";
        };
        layouts.default.right = {
          position = 536;
          type = "VPaned";
          order = 1;
          parent = "grand";
        };
        layouts.default.terminal1 = {
          profile = "default";
          type = "Terminal";
          order = 0;
          parent = "left";
        };
        layouts.default.terminal2 = {
          profile = "default";
          type = "Terminal";
          order = 1;
          parent = "left";
        };
        layouts.default.terminal3 = {
          profile = "default";
          type = "Terminal";
          order = 1;
          parent = "right";
        };
        layouts.default.terminal4 = {
          profile = "default";
          type = "Terminal";
          order = 0;
          parent = "right";
        };
      };
    };
  };
}
