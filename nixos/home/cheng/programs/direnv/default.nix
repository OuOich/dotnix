{
  options,
  osConfig,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;

      config = {
        hide_env_diff = true;
      };
    };
  }

  (lib.optionalAttrs (options.home ? persistence) {
    home.persistence.${osConfig.fileSystems."/persist".mountPoint} = {
      directories = [
        ".local/share/direnv"
      ];
    };
  })
]
