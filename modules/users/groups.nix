# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
# User groups configuration
#
# Defines custom user groups for hardware and device access.
#
# Groups:
# - plugdev: USB device access for hardware development
#   - Used by udev rules for various development hardware
#   - Common for Arduino, embedded systems, hardware debuggers
#   - Allows non-root access to USB devices
#
# Usage:
#   Automatically imported by profile-common
#
# Users in plugdev:
# - brian (configured in brian.nix)
_: {
  users.groups.plugdev = { };
}
