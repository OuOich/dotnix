{
  config,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.lazygit = {
      enable = true;

      settings = {
        git = {
          overrideGpg = true;
        };

        gui = {
          authorColors = {
            "Cheng" = "magenta";
            "Cheng :3" = "magenta";
            "成成0v0" = "magenta";
          };
        };
      };
    };
  }

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) {
    stylix.targets.lazygit.enable = false;
    catppuccin.lazygit = {
      enable = true;
      accent = "blue";
    };
  })
]
