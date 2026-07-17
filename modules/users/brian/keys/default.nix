# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
#
let
  # Software-backed automation key.
  #
  # Private half: the `builder-key` entry in modules/users/brian/bmg-secrets.yaml,
  # provisioned to /run/secrets/builder-key by features.system.remote-builders.
  #
  builder = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILu6O3swRVWAjP7J8iYGT6st7NAa+o/XaemokmtKdpGa builder key";
  # Hardware-backed (FIDO2) keys — the interactive path for both brian and
  # root, and the set trusted to verify git commit signatures.
  #
  # Seven physical devices; the *-yk.ident.txt files beside this one name them
  # Key1-Key5, Mini1 and Mini2, but those are separate PIV identities — the
  # sk-ssh keys below carry no comments, so which line is which device is not
  # recorded. Label them here if that ever matters (e.g. to revoke one).
  #
  # Adding a key: append here, then `nixos-rebuild switch` (authorized_keys
  # and ~/.ssh/allowed_signers are both generated from this list).
  yubikeys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEJ9ewKwo5FLj6zE30KnTn8+nw7aKdei9SeTwaAeRdJDAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHVLJLvcd0WcctnIKG7zBtVRQQ385Xt+Phbk8e18fg7YAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKAOSIxjX+JQw8TbQLqP3lt1J5qu7XFTwaM7RKkzHmBAAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA8ENVVAGQeSGrf8aMGszLr08GYe1BnPYBOORy0XKL/4AAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIE6+i2wgKKghwZex+4Elps8yYs2OuOYVqbZyIPXiHA4HAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFDMLJQCzDC8rGZRbWaovxDibRi/iq6uFZPJvsD3ZQumAAAABHNzaDo="
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA/pwHnzGNM+ZU4lANGROTRe2ZHbes7cnZn72Oeun/MCAAAABHNzaDo="
  ];
in
{
  inherit builder yubikeys;

  # The builder key as granted to root on deploy targets: deploy-rs only needs
  # to run activation commands, never to forward agents, ports or X11.
  builderAsRoot = "no-agent-forwarding,no-port-forwarding,no-X11-forwarding ${builder}";
}
