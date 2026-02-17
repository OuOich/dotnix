{ lib, ... }:

{
  options.settings = {
    theme = {
      colorscheme = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config.settings = {
    theme = {
      colorscheme = "catppuccin-mocha";
    };
  };
}
