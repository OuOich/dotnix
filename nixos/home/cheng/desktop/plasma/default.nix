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

  (lib.optionalAttrs (options ? stylix) {
    stylix.targets.kde.enable = false;
  })
]
