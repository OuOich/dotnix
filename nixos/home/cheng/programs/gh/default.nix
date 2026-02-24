{
  config,
  options,
  osConfig,
  lib,
  ...
}:

lib.mkMerge [

  {
    programs.gh = {
      enable = true;

      settings = {
        editor = config.home.sessionVariables.EDITOR or "nano";
      };
    };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence.${osConfig.fileSystems."/persist".mountPoint} = {
      files = [
        ".config/gh/hosts.yml"
      ];
    };
  })
]
