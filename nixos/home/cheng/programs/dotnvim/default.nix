{
  options,
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

  (lib.optionalAttrs (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".local/state/nvim"
      ];
    };
  })
]
