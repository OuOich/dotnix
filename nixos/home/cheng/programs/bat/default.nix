{ config, lib, ... }:

lib.mkMerge [
  {
    programs.bat = {
      enable = true;
    };
  }

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) {
    stylix.targets.bat.enable = false;
    catppuccin.bat.enable = true;
  })
]
