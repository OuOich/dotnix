{ lib, ... }:

{
  programs.niri = {
    settings = {
      spawn-at-startup = [
      ];

      outputs = {
        "eDP-1" = {
          mode = {
            width = 1920;
            height = 1080;
            refresh = 60.;
          };
          scale = 1.25;
        };
      };

      layout = {
        # gaps = lib.mkForce 10;
      };
    };
  };
}
