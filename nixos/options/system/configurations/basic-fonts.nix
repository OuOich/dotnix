{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.dotnix.configurations.basic-fonts;
in
{
  options.dotnix.configurations.basic-fonts = {
    enable = lib.mkEnableOption "Whether to enable basic fonts configuration.";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif

        maple-mono.NF-CN

        noto-fonts-color-emoji
      ];

      fontconfig = {
        enable = lib.mkDefault true;

        hinting = {
          enable = lib.mkDefault true;
          style = lib.mkDefault "medium";
        };
        antialias = lib.mkDefault true;
        subpixel.rgba = lib.mkDefault "rgb";

        defaultFonts = {
          sansSerif = [ "Noto Sans CJK SC" ];
          serif = [ "Noto Serif CJK SC" ];
          monospace = [ "Maple Mono NF CN" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  };
}
