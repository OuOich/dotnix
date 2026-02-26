{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.yazi = {
      enable = true;
      extraPackages = with pkgs; [
        fd
        ripgrep
        jq
        imagemagick
        ffmpeg
        resvg
        poppler
        fzf
      ];

      shellWrapperName = "y";

      settings = {
        mgr = {
          show_hidden = true;
        };
      };
    };
  }

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) {
    stylix.targets.yazi.enable = false;
    catppuccin.yazi = {
      enable = true;
      accent = "blue";
    };
  })
]
