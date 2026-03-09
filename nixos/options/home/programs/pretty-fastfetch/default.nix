{ config, lib, ... }:

let
  cfg = config.dotnix.programs.pretty-fastfetch;
in
{
  options.dotnix.programs.pretty-fastfetch = {
    enable = lib.mkEnableOption "Whether to enable super awesome fastfetch configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs.fastfetch = {
      enable = true;

      settings = lib.importJSON ./config.json;
    };
  };
}
