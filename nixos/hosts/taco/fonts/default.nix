{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      lxgw-wenkai
    ];

    fontconfig = {
      defaultFonts = {
        sansSerif = [ "LXGW WenKai" ];
        serif = [ "LXGW WenKai" ];
        monospace = [ "Maple Mono NF CN" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
