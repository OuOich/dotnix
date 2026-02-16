{ self, inputs, ... }:

{
  flake = {
    nixosConfigurations.mochi = import (self + /nixos/hosts/mochi/system.nix) { inherit self inputs; };
  };
}
