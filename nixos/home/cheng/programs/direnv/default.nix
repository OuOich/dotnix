{
  options,
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
    home.persistence."/persist" = {
      directories = [
        ".local/share/direnv"
      ];
    };
  })
]
