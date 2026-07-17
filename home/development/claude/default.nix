# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
#
# Claude Code CLI configuration
#
# Deployed as a mix of read-only nix-store symlinks (statusline script) and a
# nix-seeded *writable* settings.json.
# To update: edit these files, run `nix fmt && sudo nixos-rebuild switch`.
#
# Plugin/skill management (nix is the source of truth for what is *available*):
# - `thirdPartyMarketplaces` are registered on activation.
# - `availablePlugins` are all installed on activation (idempotent), so every
#   skill collection is on disk — a disabled plugin costs ZERO context.
# - Every available plugin is seeded ON except the few listed in
#   `disabledByDefault` (heavy or rarely-relevant outliers, enabled on-demand
#   via `/plugin`).
# - settings.json is seeded/merged (not symlinked) so `claude plugin enable
#   --scope user` (the `/plugin` UI) can flip skills on globally at runtime and
#   have it persist. Nix owns the static keys and the install list; the user
#   owns runtime enablement (their toggles survive rebuilds).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Marketplace-id helpers (right-hand side is the marketplace's *internal* name
  # from its .claude-plugin/marketplace.json, which plugin ids reference).
  official = name: "${name}@claude-plugins-official";
  tob = name: "${name}@trailofbits";

  # Third-party plugin marketplaces (GitHub repos).
  # Official marketplace (anthropics/claude-plugins-official) is built-in.
  thirdPartyMarketplaces = [
    "poemswe/co-researcher" # -> co-researcher-marketplace
    "trailofbits/skills" # -> trailofbits
    "multica-ai/andrej-karpathy-skills" # -> karpathy-skills
    "anthropics/skills" # -> anthropic-agent-skills
    "mattpocock/skills" # -> mattpocock
    "sjungling/claude-plugins" # -> sjungling-plugins
  ];

  # Plugins are ENABLED by default now — a well-written skill costs only its
  # ~40-180 tok description in the listing (the body loads on-invoke), so a broad
  # default is cheap on the 1M context and avoids the enable-and-reload friction.
  # Keep OFF only the heavy or rarely-relevant outliers (enable on-demand via
  # `/plugin`). `github` stays off because its Copilot MCP needs auth and the
  # `gh` CLI is used instead.
  disabledByDefault = [
    (official "plugin-dev") # only when authoring plugins/skills
    (official "pr-review-toolkit") # redundant with code-review/coderabbit
    (official "github") # Copilot MCP needs auth; gh CLI used
    "building-secure-contracts@trailofbits" # blockchain — irrelevant here
    "co-researcher@co-researcher-marketplace" # heavy; enable on-demand for research
  ];

  # Official-marketplace plugins to keep available (installed and, unless in
  # disabledByDefault, enabled).
  officialAvailable = map official [
    "context7"
    "serena"
    "github"
    "superpowers"
    "code-review"
    "code-simplifier"
    "feature-dev"
    "pr-review-toolkit"
    "claude-md-management"
    "agent-sdk-dev"
    "plugin-dev"
    "claude-code-setup"
    "security-guidance"
    "coderabbit"
    "skill-creator"
  ];

  # All 40 Trail of Bits plugins (available-but-off; zero context while disabled).
  trailofbitsPlugins = map tob [
    "agentic-actions-auditor"
    "ask-questions-if-underspecified"
    "audit-context-building"
    "building-secure-contracts"
    "burpsuite-project-parser"
    "claude-in-chrome-troubleshooting"
    "constant-time-analysis"
    "c-review"
    "culture-index"
    "debug-buttercup"
    "devcontainer-setup"
    "differential-review"
    "dimensional-analysis"
    "dwarf-expert"
    "entry-point-analyzer"
    "firebase-apk-scanner"
    "fp-check"
    "gh-cli"
    "git-cleanup"
    "insecure-defaults"
    "let-fate-decide"
    "modern-python"
    "mutation-testing"
    "property-based-testing"
    "rust-review"
    "seatbelt-sandboxer"
    "second-opinion"
    "semgrep-rule-creator"
    "semgrep-rule-variant-creator"
    "sharp-edges"
    "skill-improver"
    "spec-to-code-compliance"
    "static-analysis"
    "supply-chain-risk-auditor"
    "testing-handbook-skills"
    "trailmark"
    "variant-analysis"
    "workflow-skill-design"
    "yara-authoring"
    "zeroize-audit"
  ];

  # Everything installed on activation (available on disk for instant
  # on-demand enable).
  availablePlugins =
    officialAvailable
    ++ [
      "co-researcher@co-researcher-marketplace"
      "andrej-karpathy-skills@karpathy-skills"
      "document-skills@anthropic-agent-skills" # bundles xlsx/docx/pptx/pdf
      "mattpocock-skills@mattpocock" # bundles handoff + more
      "technical-writer@sjungling-plugins"
    ]
    ++ trailofbitsPlugins;

  # enabledPlugins seed: every available plugin listed, enabled unless it is in
  # disabledByDefault. Self-documenting — the settings file shows all available
  # plugins and their on/off state.
  enabledPluginsSeed = builtins.listToAttrs (
    map (id: {
      name = id;
      value = !(builtins.elem id disabledByDefault);
    }) availablePlugins
  );

  # Static settings keys owned by nix (nix always wins on rebuild).
  staticSettings = {
    statusLine = {
      type = "command";
      command = "bash ~/.config/claude/statusline-command.sh";
    };
    skillListingBudgetFraction = 0.03;
  };

  staticSettingsFile = pkgs.writeText "claude-settings-static.json" (builtins.toJSON staticSettings);
  enabledSeedFile = pkgs.writeText "claude-enabled-seed.json" (builtins.toJSON enabledPluginsSeed);

  # User-scope MCP servers managed by nix, from the shared catalog
  # (../mcp-servers.nix) so Claude Code and Copilot CLI cannot drift.
  mcpServers = lib.filterAttrs (_: server: server.claude or true) (
    import ../mcp-servers.nix { inherit (config.home) homeDirectory; }
  );

  # Build `claude mcp add` commands from the mcpServers attrset.
  mcpAddCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: cfg:
      # `claude mcp list` prints one "name: command ..." line per server;
      # anchor on that so one server name being a substring of another's
      # output can never skip a registration.
      if cfg ? transport && cfg.transport == "http" then
        ''
          if ! claude mcp list 2>/dev/null | grep -q "^${name}:"; then
            claude mcp add --scope user --transport http ${lib.escapeShellArg name} ${lib.escapeShellArg cfg.url} 2>/dev/null || true
          fi
        ''
      else
        let
          args = lib.concatStringsSep " " (map lib.escapeShellArg cfg.args);
        in
        ''
          if ! claude mcp list 2>/dev/null | grep -q "^${name}:"; then
            claude mcp add --scope user ${lib.escapeShellArg name} -- ${lib.escapeShellArg cfg.command} ${args} 2>/dev/null || true
          fi
        ''
    ) mcpServers
  );

  pluginSyncScript = pkgs.writeShellApplication {
    name = "claude-plugin-sync";
    runtimeInputs = [
      pkgs.claude-code
      pkgs.jq
      pkgs.git
      pkgs.coreutils
    ];
    text = ''
      # Activation runs without login-shell sessionVariables, so pin the
      # config dir explicitly — otherwise the claude CLI operates on
      # ~/.claude/ while this script writes ~/.config/claude/ (split-brain).
      export CLAUDE_CONFIG_DIR="$HOME/.config/claude"

      target="$CLAUDE_CONFIG_DIR/settings.json"
      marker="$CLAUDE_CONFIG_DIR/.nix-plugins-seeded"
      mkdir -p "$(dirname "$target")"

      # Replace the legacy read-only nix symlink with a writable file.
      if [ -L "$target" ]; then
        rm -f "$target"
      fi

      # Snapshot the user's prior enable choices BEFORE installing. `claude
      # plugin install` auto-enables what it installs, so we must capture the
      # real intent here and re-assert it in the authoritative write below.
      prev='{}'
      if [ -f "$target" ] && jq empty "$target" 2>/dev/null; then
        prev="$(jq -c '.enabledPlugins // {}' "$target")"
      fi

      # Register marketplaces and install every available plugin (needs claude).
      # Installing puts each on disk so it is ready to enable on-demand; its
      # enable-state is fixed authoritatively afterwards, not by install.
      if command -v claude &>/dev/null; then
        for repo in ${lib.concatStringsSep " " thirdPartyMarketplaces}; do
          claude plugin marketplace add "$repo" 2>/dev/null || true
        done
        for plugin in ${lib.concatStringsSep " " availablePlugins}; do
          if ! claude plugin list 2>/dev/null | grep -q "$plugin"; then
            claude plugin install "$plugin" 2>/dev/null || true
          fi
        done
        # Ensure nix-managed MCP servers are registered.
        ${mcpAddCommands}
      else
        echo "claude-plugin-sync: claude not found, seeding settings only"
      fi

      # Authoritative settings write.
      #  - nix always owns the static keys (statusLine, skillListingBudgetFraction).
      #  - enabledPlugins:
      #      * first run / migration (no marker): the nix seed wins, giving the
      #        lean baseline and discarding install's auto-enable.
      #      * thereafter: seed provides defaults but the user's prior /plugin
      #        toggles (prev, snapshotted before install) win — so runtime
      #        enables persist across rebuilds, and newly-added plugins default
      #        to their seed value (off unless in enabledBaseline).
      base='{}'
      if [ -f "$target" ] && jq empty "$target" 2>/dev/null; then
        base="$(cat "$target")"
      fi
      # Preserve user toggles only once past the first-seed/migration run.
      usePrev=false
      if [ -f "$marker" ]; then
        usePrev=true
      fi
      jq -n \
        --argjson base "$base" \
        --argjson prev "$prev" \
        --argjson usePrev "$usePrev" \
        --slurpfile static ${staticSettingsFile} \
        --slurpfile seed ${enabledSeedFile} \
        '$base
         | .statusLine = $static[0].statusLine
         | .skillListingBudgetFraction = $static[0].skillListingBudgetFraction
         | .enabledPlugins = (if $usePrev then ($seed[0] + $prev) else $seed[0] end)' \
        > "$target.tmp"
      install -m 0644 "$target.tmp" "$target"
      rm -f "$target.tmp"
      touch "$marker"
    '';
  };
in
{
  home.file = {
    ".config/claude/statusline-command.sh" = {
      source = ./statusline-command.sh;
      executable = true;
    };
  };

  # Sync on activation: seed settings.json, register marketplaces, install
  # available plugins, register MCP servers.
  home.activation.claudePluginSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe pluginSyncScript}
  '';

  # Clean up ~/.claude.json.backup.* files that Claude Code hardcodes to $HOME.
  # Upstream bug: https://github.com/anthropics/claude-code/issues/1455
  systemd.user.services.claude-backup-cleanup = {
    Unit.Description = "Clean up Claude Code backup file pollution in $HOME";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.findutils}/bin/find %h -maxdepth 1 -name '.claude.json.backup.*' -delete";
    };
  };
  systemd.user.timers.claude-backup-cleanup = {
    Unit.Description = "Daily cleanup of Claude Code backup files";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
