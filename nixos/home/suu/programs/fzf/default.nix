{
  config,
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.fzf = {
      enable = true;
    };
  }

  (lib.mkIf (options ? stylix) {
    stylix.targets.fzf.enable = lib.mkDefault true;
  })

  (lib.mkIf
    (options ? catppuccin && lib.strings.hasPrefix "catppuccin-" config.settings.theme.colorscheme)
    (
      {
        catppuccin.fzf.enable = true;
      }
      // lib.optionalAttrs (options ? stylix) {
        stylix.targets.fzf.enable = false;
      }
    )
  )
]
