{ config, lib, ... }:

lib.mkMerge [
  {
    programs.starship = {
      enable = true;

      settings = builtins.fromTOML (builtins.readFile ./starship.toml);
    };
  }

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) {
    stylix.targets.starship.enable = false;
    catppuccin.starship.enable = true;
  })
]
