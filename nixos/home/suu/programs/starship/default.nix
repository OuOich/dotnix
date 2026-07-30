{
  config,
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.starship = {
      enable = true;

      settings = builtins.fromTOML (builtins.readFile ./starship.toml);
    };
  }

  (lib.mkIf (options ? stylix) {
    stylix.targets.starship.enable = lib.mkDefault true;
  })

  (lib.mkIf
    (options ? catppuccin && lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme)
    (
      {
        catppuccin.starship.enable = true;
      }
      // lib.optionalAttrs (options ? stylix) {
        stylix.targets.starship.enable = false;
      }
    )
  )
]
