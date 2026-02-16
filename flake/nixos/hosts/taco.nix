{ self, inputs, ... }:

{
  flake = {
    nixosConfigurations.taco = import (self + /nixos/hosts/taco/system.nix) { inherit self inputs; };
  };
}
