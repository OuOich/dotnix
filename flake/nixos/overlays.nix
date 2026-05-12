{ self, inputs, ... }:

let
  lib = inputs.nixpkgs.lib;
  dotnix.lib.utils = import ../../library/utils/fs/list.nix { inherit lib; };

  overlays = import (self + /nixos/overlays) {
    inherit
      dotnix
      inputs
      lib
      self
      ;
  };
in

{
  flake = {
    inherit overlays;

    nixosOverlays =
      { lib, ... }:
      {
        nixpkgs.overlays = lib.mkBefore [ overlays.default ];
      };

    homeOverlays =
      { lib, ... }:
      {
        nixpkgs.overlays = lib.mkBefore [ overlays.default ];
      };
  };
}
