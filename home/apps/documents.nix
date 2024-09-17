_:

{
  programs = {
    #modern pdf viewer for books and research papers.
    sioyek = {
      enable = true;
      config = {
        # === DRACULA THEME === #
        "startup_commands" = "toggle_custom_color";

        "background_color" = "0.15686 0.16471 0.21176";
        "dark_mode_background_color" = "0.15686 0.16471 0.21176";
        #"dark_mode_contrast" = "0.8";

        "text_highlight_color" = "0.94510 0.98039 0.54902";
        "visual_mark_color" = "0.15686 0.16471 0.21176 0.8";

        "search_highlight_color" = "0.94510 0.98039 0.54902";
        "link_highlight_color" = "0.38431 0.44706 0.64314";
        "synctex_highlight_color" = "0.31373 0.98039 0.48235";

        "highlight_color_a" = "1.00000 0.72157 0.42353";
        "highlight_color_b" = "0.31373 0.98039 0.48235";
        "highlight_color_c" = "0.54510 0.91373 0.99216";
        "highlight_color_d" = "1.00000 0.47451 0.77647";
        "highlight_color_e" = "0.74118 0.57647 0.97647";
        "highlight_color_f" = "1.00000 0.33333 0.33333";
        "highlight_color_g" = "0.94510 0.98039 0.54902";

        #default_dark_mode		1

        "font_size" = "12";
        "ui_font" = "FiraCode Mono";

        "custom_background_color" = "0.15686 0.16471 0.21176";
        "custom_text_color" = "0.97255 0.97255 0.94902";

        "ui_text_color" = "0.97255 0.97255 0.94902";
        "ui_background_color" = "0.15686 0.16471 0.21176";
        "ui_selected_text_color" = "0.97255 0.97255 0.94902";
        "ui_selected_background_color" = "0.26667 0.27843 0.35294";
        "status_bar_font_size" = "16";
      };
    };
  };
}
