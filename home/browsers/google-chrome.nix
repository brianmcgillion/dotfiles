# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ pkgs, ... }:
{
  home.packages = [ pkgs.google-chrome ];

  # Set Chrome as default browser
  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "google-chrome.desktop" ];
    "x-scheme-handler/http" = [ "google-chrome.desktop" ];
    "x-scheme-handler/https" = [ "google-chrome.desktop" ];
    "x-scheme-handler/about" = [ "google-chrome.desktop" ];
    "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
    "x-scheme-handler/mailto" = [ "google-chrome.desktop" ];
  };
}
