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

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) (
    {
      catppuccin.starship.enable = true;
    }
    // lib.optionalAttrs (options ? stylix) {
      stylix.targets.starship.enable = false;
    }
  ))
]
