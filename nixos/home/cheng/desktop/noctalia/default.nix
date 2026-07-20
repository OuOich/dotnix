{
  config,
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.noctalia-shell = {
      enable = true;

      settings = {
        ui = {
          panelBackgroundOpacity = 1;
        };

        colorSchemes = {
          predefinedScheme = lib.mkIf config.dotnix.programs.matugen.enable "Matugen";
          darkMode = true;
        };

        wallpaper = {
          overviewEnabled = false;
        };

        bar = {
          density = "comfortable";
        };

        dock = {
          enabled = false;
        };

        location = {
          weatherShowEffects = false;
        };

        hooks = {
          enabled = true;

          wallpaperChange = lib.mkIf (
            config.programs.noctalia-shell.settings.colorSchemes.predefinedScheme == "Matugen"
          ) /* bash */ "matugen image $1";
        };
      };
    };

    home.file.".cache/noctalia/wallpapers.json" = {
      text = builtins.toJSON {
        defaultWallpaper = config.settings.theme.wallpaper.default;
      };
    };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      files = [
        ".config/noctalia/colorschemes/Matugen/Matugen.json"
        ".cache/noctalia/shell-state.json"
      ];
    };
  })

  (lib.mkIf (options ? stylix) {
    stylix.targets.noctalia-shell.enable = false;
  })
]
