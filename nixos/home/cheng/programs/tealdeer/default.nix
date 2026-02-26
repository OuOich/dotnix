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

  (lib.mkIf (options.home ? persistence) {
    home.persistence.${osConfig.fileSystems."/persist".mountPoint} = {
      directories = [
        ".cache/tealdeer/tldr-pages"
      ];
    };
  })
]
