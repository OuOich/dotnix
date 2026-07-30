{
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.tealdeer = {
      enable = true;
    };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".cache/tealdeer"
      ];
    };
  })
]
