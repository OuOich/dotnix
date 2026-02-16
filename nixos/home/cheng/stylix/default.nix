{ self, pkgs, ... }:

let
  base16Scheme.public = name: "${pkgs.base16-schemes}/share/themes/${name}.yaml";
  base16Scheme.shared = name: self + /assets/base16-schemes/${name}.yaml;
  base16Scheme.private = name: ./schemes/${name}.yaml;
in
{
  stylix = {
    enable = true;

    base16Scheme = base16Scheme.public "catppuccin-mocha";

    autoEnable = true;
    targets = {
      nixvim.enable = false;
    };
  };
}
