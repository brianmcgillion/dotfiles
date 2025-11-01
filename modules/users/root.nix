# SPDX-License-Identifier: MIT
# Root user SSH configuration
#
# Configures SSH access for the root user using YubiKey hardware keys.
# Multiple keys are provided for redundancy and different physical devices.
#
# SSH keys:
# - 7 YubiKey-based SSH keys (sk-ssh-ed25519)
# - Hardware-backed authentication
# - Different physical YubiKeys for backup/redundancy
#
# Security considerations:
# - Only key-based authentication (no password)
# - Hardware keys cannot be copied or extracted
# - Physical key presence required for authentication
# - Complements per-host root login policies
#
# Usage:
#   Automatically imported by profile-common
#
# Note: Actual root login is controlled by sshd settings.
# These keys allow root login when PermitRootLogin is enabled.
_: {
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEJ9ewKwo5FLj6zE30KnTn8+nw7aKdei9SeTwaAeRdJDAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHVLJLvcd0WcctnIKG7zBtVRQQ385Xt+Phbk8e18fg7YAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKAOSIxjX+JQw8TbQLqP3lt1J5qu7XFTwaM7RKkzHmBAAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA8ENVVAGQeSGrf8aMGszLr08GYe1BnPYBOORy0XKL/4AAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIE6+i2wgKKghwZex+4Elps8yYs2OuOYVqbZyIPXiHA4HAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFDMLJQCzDC8rGZRbWaovxDibRi/iq6uFZPJvsD3ZQumAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA/pwHnzGNM+ZU4lANGROTRe2ZHbes7cnZn72Oeun/MCAAAABHNzaDo="
  ];
}
