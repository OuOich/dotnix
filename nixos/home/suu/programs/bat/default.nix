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

  (lib.mkIf (options ? stylix) {
    stylix.targets.bat.enable = lib.mkDefault true;
  })

  (lib.mkIf
    (options ? catppuccin && lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme)
    (
      {
        catppuccin.bat.enable = true;
      }
      // lib.optionalAttrs (options ? stylix) {
        stylix.targets.bat.enable = false;
      }
    )
  )
]
