{ lib, ... }:

lib.mkMerge [
  {
    fonts = {
      fontconfig = {
        enable = true;

        hinting = "medium";
        antialiasing = true;
        subpixelRendering = "rgb";

        defaultFonts = {
          sansSerif = lib.mkForce [ "LXGW WenKai" ];
          serif = lib.mkForce [ "LXGW WenKai" ];
          monospace = lib.mkForce [ "Maple Mono NF CN" ];
          emoji = lib.mkForce [ "Noto Color Emoji" ];
        };
      };
    };
  }
]
