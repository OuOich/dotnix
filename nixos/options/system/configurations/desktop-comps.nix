{ config, lib, ... }:

let
  cfg = config.dotnix.configurations.desktop-comps;
in
{
  options.dotnix.configurations.desktop-comps = {
    enable = lib.mkEnableOption "Whether to enable common desktop components.";
  };

  config = lib.mkIf cfg.enable {
    xdg.portal.enable = lib.mkDefault true;
    xdg.portal.wlr.enable = lib.mkDefault true;
    xdg.portal.lxqt.enable = lib.mkDefault true;
    xdg.mime.enable = lib.mkDefault true;
    xdg.menus.enable = lib.mkDefault true;
    xdg.icons.enable = lib.mkDefault true;
    xdg.autostart.enable = lib.mkDefault true;
    xdg.sounds.enable = lib.mkDefault true;
    xdg.terminal-exec.enable = lib.mkDefault true;

    xdg.portal.config.common.default = "*";

    programs.dconf.enable = lib.mkDefault true;
  };
}
