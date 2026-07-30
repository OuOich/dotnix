{ lib, ... }:

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
}
