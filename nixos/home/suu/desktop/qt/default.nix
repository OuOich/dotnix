{ pkgs, ... }:

{
  qt = {
    enable = true;

    platformTheme = {
      name = "kde";
    };

    style = {
      name = "breeze";
      package = with pkgs; [
        kdePackages.breeze
        kdePackages.breeze.qt5
      ];
    };
  };

  xdg.configFile."kdeglobals".text = /* ini */ ''
    ${builtins.readFile "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors"}
  '';
}
