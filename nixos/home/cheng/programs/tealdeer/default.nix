{
  options,
  osConfig,
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
    home.persistence.${osConfig.fileSystems."/persist".mountPoint} = {
      directories = [
        ".cache/tealdeer"
      ];
    };
  })
]
