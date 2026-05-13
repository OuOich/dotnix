{ pkgs, lib, ... }:

{
  programs.niri = {
    settings = {
      spawn-at-startup = [
        { sh = "${pkgs.gammastep}/bin/gammastep -O 7000"; }
      ];

      outputs = {
        "LVDS-1" = {
          mode = {
            width = 1366;
            height = 768;
            refresh = 60.;
          };
          scale = 1;
        };
      };

      layout = {
        gaps = lib.mkForce 10;
      };
    };
  };
}
