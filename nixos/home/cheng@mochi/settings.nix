{ dotnix, ... }:

{
  settings = {
    theme = {
      colorscheme = "catppuccin-mocha";

      wallpaper = {
        default = dotnix.pkgs.wallpapers.items.pixiv-120560744;
      };
    };
  };
}
