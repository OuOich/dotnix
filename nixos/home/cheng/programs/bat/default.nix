{
  config,
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.bat = {
      enable = true;
    };
  }

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) (
    {
      catppuccin.bat.enable = true;
    }
    // lib.optionalAttrs (options ? stylix) {
      stylix.targets.bat.enable = false;
    }
  ))
]
