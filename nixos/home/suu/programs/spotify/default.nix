{
  options,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  {
    home.packages = with pkgs; [ spotify ];
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".config/spotify"
        ".cache/spotify"
      ];
    };
  })
]
