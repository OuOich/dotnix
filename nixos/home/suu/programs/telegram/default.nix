{
  options,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  {
    home.packages = with pkgs; [ telegram-desktop ];
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".local/share/TelegramDesktop"
      ];
    };
  })
]
