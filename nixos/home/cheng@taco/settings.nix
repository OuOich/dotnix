{ dotnix, ... }:

{
  settings = {
    theme = {
      colorscheme = "catppuccin-mocha";

      wallpaper = {
        default = dotnix.pkgs.wallpapers.items.wallhaven-qr3mdr;
      };
    };
  };
}
