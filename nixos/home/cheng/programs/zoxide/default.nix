{
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.zoxide = {
      enable = true;
    };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".local/share/zoxide"
      ];
    };
  })
]
