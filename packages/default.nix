# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{ inputs, ... }:
{
  # Expose the overlay's CI-buildable packages as flake outputs so the
  # package-<name> checks in nix/checks.nix actually build them.
  #
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (pkgs)
          rebiber
          remarkable-sync
          ;
      };
    };

  flake = {
    nixosModules = {
      scripts = ./scripts;
    };

    overlays.own-pkgs-overlay =
      final: prev:
      let
        # AI coding agents sourced from numtide/llm-agents.nix (see flake.nix).
        # Aliasing claude-code / claude-agent-acp here routes every existing
        # `pkgs.claude-code` reference (system packages, the home-manager plugin
        # sync `runtimeInputs`, etc.) to the faster-moving llm-agents build.
        llm = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
      in
      {
        inherit (llm) claude-code;
        inherit (llm) claude-agent-acp;
        inherit (llm) ccusage;
        inherit (llm) ccstatusline;
        inherit (llm) coderabbit-cli;
        inherit (llm) codex;
        # The Codex desktop app ships as `chatgpt`: one Electron app, both
        # products. See modules/features/ai/codex.nix.
        inherit (llm) chatgpt;
        inherit (llm) opencode;
        inherit (llm) oh-my-opencode;

        rebiber = final.callPackage ./rebiber/default.nix { };
        remarkable-sync = final.callPackage ./remarkable-sync/default.nix { };

        # Convenience top-level alias so greatfet (which nixpkgs only exposes under
        # python3Packages) is referenced as `pkgs.greatfet` like our other tools.
        greatfet = final.python3Packages.greatfet;

        # The bundled Qt5 has no Wayland backend, so the package pins
        # QT_QPA_PLATFORM=xcb and runs on XWayland, where every MIT-SHM
        # ShmPutImage round-trip fails with BadMatch. Skip that doomed path.
        # The .desktop Exec lines hardcode the unwrapped store path, so they
        # need rewriting or the launcher bypasses the wrapper.
        onlyoffice-desktopeditors =
          let
            oo = prev.onlyoffice-desktopeditors;
            desktop = "share/applications/onlyoffice-desktopeditors.desktop";
          in
          final.symlinkJoin {
            inherit (oo) name meta;
            paths = [ oo ];
            nativeBuildInputs = [ final.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/onlyoffice-desktopeditors \
                --set QT_X11_NO_MITSHM 1
              rm $out/${desktop}
              substitute ${oo}/${desktop} $out/${desktop} \
                --replace-fail "${oo}/bin" "$out/bin"
            '';
          };

        # nixos-unstable is parked on 7fd4004 (2026-10-11 15:54Z), which carries
        # the 6.0.2 bump but not the pnpm hash fix that landed in ac7b1aae four
        # hours later. Drop this once the channel moves past that commit.
        typescript-language-server = prev.typescript-language-server.overrideAttrs (o: {
          pnpmDeps = o.pnpmDeps.overrideAttrs {
            outputHash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
          };
        });
      };
  };
}
