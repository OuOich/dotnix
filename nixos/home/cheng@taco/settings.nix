{ dotnix, lib, ... }:

{
  options.settings = {
    theme = {
      colorscheme = lib.mkOption {
        type = lib.types.str;
      };

      wallpaper = {
        default = lib.mkOption {
          type = lib.types.either lib.types.path lib.types.str;
        };
      };
    };
  };

  config.settings = {
    theme = {
      colorscheme = "catppuccin-mocha";

      wallpaper = {
        default = dotnix.pkgs.wallpapers.items.wallhaven-qr3mdr;
      };
    };
  };
}
