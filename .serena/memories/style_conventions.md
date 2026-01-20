# Style and Conventions

## Nix Code Style

### Formatting
- **Formatter**: nixfmt (RFC 166 standard)
- **Run**: `nix fmt` before committing
- **Additional tools**: deadnix (dead code), statix (anti-patterns), nixf-diagnose (diagnostics)

### License Headers
All files MUST have SPDX license headers:
```nix
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
```

### Module Structure
Feature modules follow this pattern:
```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.<category>.<feature>;
in
{
  options.features.<category>.<feature> = {
    enable = lib.mkEnableOption "feature description";
    # Additional options with mkOption...
  };

  config = lib.mkIf cfg.enable {
    # Implementation
  };
}
```

### Flake-parts Modules
For modules that export flake outputs:
```nix
# Simple export
_: {
  flake.nixosModules.my-module = import ./module.nix;
}

# With inputs
{ inputs, ... }:
{
  imports = [ inputs.something.flakeModule ];
  flake.nixosModules.my-module = import ./module.nix;
}
```

### Naming Conventions
- **Feature modules**: `feature-<name>` (e.g., `feature-audio`, `feature-sshd`)
- **Profile modules**: `profile-<type>` (e.g., `profile-client`, `profile-server`)
- **Host modules**: `host-<hostname>` (e.g., `host-arcadia`)
- **User modules**: `user-<username>` (e.g., `user-brian`)
- **Home modules**: `home-profile-<type>` or `user-profile-<username>`

### Sorted Lists
Use `keep-sorted` comments for maintaining sorted lists:
```nix
environment.systemPackages = [
  # keep-sorted start
  pkgs.git
  pkgs.vim
  pkgs.wget
  # keep-sorted end
];
```

## Shell Scripts
- **Linter**: shellcheck
- **Formatter**: shfmt
- Include shebang: `#!/usr/bin/env bash` or appropriate

## File Organization
- Features go in `modules/features/<category>/<feature>.nix`
- Hardware configs go in `modules/hardware/`
- User configs go in `modules/users/<username>/`
- Host configs go in `hosts/<hostname>/`
- Home-manager profiles go in `home/profiles/`

## Comments
- Use comments sparingly - code should be self-documenting
- Document non-obvious configurations
- Reference external docs/issues where relevant
