{
  dotnix,
  config,
  options,
  osConfig,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.fish = {
      enable = true;

      interactiveShellInit = /* bash */ ''
        # `nix` and `nix-shell` wrapper for fish shell
        ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
      '';

      shellAliases = {
        ip = "ip -c";
        grep = "grep --color=auto";
      };

      shellAbbrs = lib.mkMerge [
        {
          i = "fastfetch";
          e = config.home.sessionVariables.EDITOR or "nano";
          wlc = "wl-copy";
        }

        (lib.mkIf config.programs.bat.enable {
          b = "bat";
        })

        (lib.mkIf config.programs.git.enable {
          g = "git";
        })

        (lib.mkIf config.programs.eza.enable {
          l = "eza";
          ls = "eza -a";
          la = "eza -a";
          ll = "eza -la";
          lt = "eza -Ta";
          llt = "eza -lTa";
        })
      ];
    };

    xdg.configFile =
      let
        subst = src: dotnix.lib.substituteDir { inherit src vars; };

        vars = {
          fastfetch = "${pkgs.fastfetch}/bin/fastfetch";
        };
      in
      {
        "fish/conf.d" = {
          source = subst ./conf.d;
          recursive = true;
        };
        "fish/functions" = {
          source = subst ./functions;
          recursive = true;
        };
      };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence.${osConfig.fileSystems."/persist".mountPoint} = {
      directories = [
        ".local/share/fish"
      ];
    };
  })

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) {
    stylix.targets.fish.enable = false;
    catppuccin.fish.enable = true;
    programs.fish.shellInitLast = lib.mkIf (config.catppuccin.fish.flavor != "latte") /* bash */ ''
      # FIX: Force dark mode to resolve the issue with strange colorscheme failing to apply. 2026-02-17
      fish_config theme choose "Catppuccin ${lib.toSentenceCase config.catppuccin.fish.flavor}" --color-theme=dark
    '';
  })
]
