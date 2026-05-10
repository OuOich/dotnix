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

  (lib.optionalAttrs (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".cache/tealdeer"
      ];
    };
  })
]
