# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# GNOME desktop interface behaviour
#
# gtk-enable-primary-paste governs middle-click pasting of the PRIMARY
# selection for every GTK application, not just terminals. Its schema
# default in gsettings-desktop-schemas flipped from true (47.x, 49.x) to
# false in 50.1, so moving to GNOME 50 silently disabled middle-click
# paste desktop-wide for anyone who had never set the key explicitly.
#
# Pinned here so the behaviour stops tracking whatever upstream chooses as
# the default.
_: {
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-enable-primary-paste = true;
  };
}
