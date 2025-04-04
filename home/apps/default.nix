{ config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.modules.home.apps;
in
{
  imports = [
    ./chat.nix
    ./documents.nix
  ];

  config = mkIf cfg.enable {
    # Enable specific app modules based on their respective flags
    modules.home.apps = {
      chat = lib.mkDefault cfg.chat;
      documents = lib.mkDefault cfg.documents;
    };
  };
}
