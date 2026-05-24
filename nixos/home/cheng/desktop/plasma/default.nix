{
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.plasma = {
      enable = true;
    };
  }

  (lib.mkIf (options ? stylix) {
    stylix.targets.kde.enable = false;
  })
]
