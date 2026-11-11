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
        # codex points openssl-sys at aws-lc's compat openssl.pc, which nixpkgs
        # made opt-in in 8e5d4ae19 (withOpenSSLShim, off by default). The
        # symbol prefixing e527e5e4d turned on the same day then breaks
        # openssl-sys' bindgen, which cannot strip the prefix.
        codex = llm.codex.override {
          aws-lc = final.aws-lc.override {
            withOpenSSLShim = true;
            symbolPrefix = null;
          };
        };
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

        # onig_sys wants pkg-config and a system oniguruma, which nixpkgs'
        # neocmakelsp never declared. Fixed upstream in 5246ebb2d, which
        # nixos-unstable has not picked up yet -- drop this when it does.
        neocmakelsp = prev.neocmakelsp.overrideAttrs (o: {
          nativeBuildInputs = o.nativeBuildInputs ++ [ final.pkg-config ];
          buildInputs = (o.buildInputs or [ ]) ++ [ final.oniguruma ];
        });
      };
  };
}
