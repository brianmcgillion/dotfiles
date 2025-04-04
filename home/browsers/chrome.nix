{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.browsers.chrome;
in
{
  config = mkIf cfg {
    programs.google-chrome = {
      enable = true;
      # Add your Chrome configuration here
    };

    # Set Chrome as the default browser system-wide
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "google-chrome.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-scheme-handler/about" = "google-chrome.desktop";
        "x-scheme-handler/unknown" = "google-chrome.desktop";
      };
    };
  };
}
