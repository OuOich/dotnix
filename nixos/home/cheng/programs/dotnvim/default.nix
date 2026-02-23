{
  options,
  osConfig,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.dotnvim = {
      enable = true;

      useFlakeNixpkgs = true;
      selfContainedOverlays = true;

      defaultEditor = true;

      vimdiffAlias = true;
      vimAlias = true;
      viAlias = true;
    };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence.${osConfig.fileSystems."/persist".mountPoint} = {
      directories = [
        ".local/state/nvim"
      ];
    };
  })
]
