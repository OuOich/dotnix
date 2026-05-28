{ lib, ... }:

lib.mkMerge [
  {
    hardware.bluetooth = {
      enable = true;

      powerOnBoot = true;
    };
  }
]
