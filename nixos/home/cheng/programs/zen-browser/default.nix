{ options, lib, ... }:

lib.mkMerge [
  {
    programs.zen-browser = {
      enable = true;

      setAsDefaultBrowser = true;
    };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".zen"
      ];
    };
  })

  {
    stylix.targets.zen-browser.enable = false;
  }
]
