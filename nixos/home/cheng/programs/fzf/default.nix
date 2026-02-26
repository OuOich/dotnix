{
  config,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.fzf = {
      enable = true;
    };
  }

  (lib.mkIf (lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme) {
    stylix.targets.fzf.enable = false;
    catppuccin.fzf = {
      enable = true;
      accent = "teal";
    };
  })
]
