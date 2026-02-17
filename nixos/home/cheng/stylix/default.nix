{
  self,
  config,
  pkgs,
  ...
}:

let
  base16Scheme = rec {
    public = name: "${pkgs.base16-schemes}/share/themes/${name}.yaml";
    shared = name: self + "/assets/base16-schemes/${name}.yaml";
    private = name: ./schemes/${name}.yaml;

    get =
      name:
      pkgs.lib.findFirst (p: builtins.pathExists p)
        (throw "base16Scheme.get: scheme '${name}' not found in any location")
        [
          (private name)
          (shared name)
          (public name)
        ];
  };
in
{
  stylix = {
    enable = true;

    base16Scheme = base16Scheme.get config.settings.theme.colorscheme;

    autoEnable = true;
    targets = {
      nixvim.enable = false;
    };
  };
}
