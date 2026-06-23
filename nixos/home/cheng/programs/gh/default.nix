{
  config,
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.gh = {
      enable = true;

      settings = {
        git_protocol = "ssh";

        editor = config.home.sessionVariables.EDITOR or "nano";
      };
    };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      files = [
        ".config/gh/hosts.yml"
      ];
    };
  })
]
