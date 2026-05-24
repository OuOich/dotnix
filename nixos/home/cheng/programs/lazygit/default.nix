{
  config,
  options,
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

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".local/state/lazygit"
      ];
    };
  })

  (lib.mkIf (options ? stylix) {
    stylix.targets.lazygit.enable = lib.mkDefault true;
  })

  (lib.mkIf
    (options ? catppuccin && lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme)
    (
      {
        catppuccin.lazygit.enable = true;
      }
      // lib.optionalAttrs (options ? stylix) {
        stylix.targets.lazygit.enable = false;
      }
    )
  )
]
