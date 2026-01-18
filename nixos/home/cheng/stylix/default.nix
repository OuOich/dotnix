{ pkgs, ... }:

let
  base16Scheme.public = name: "${pkgs.base16-schemes}/share/themes/${name}.yaml";
  base16Scheme.private = name: ./schemes/${name}.yaml;
in
{
  stylix = {
    enable = true;

    base16Scheme = base16Scheme.public "catppuccin-mocha";

    autoEnable = true;
    targets = { };
  };
}
