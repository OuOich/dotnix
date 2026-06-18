{ self, inputs, ... }:

{
  flake = {
    nixosConfigurations.vps-rainyun-gofer = import (self + /nixos/hosts/vps-rainyun-gofer/system.nix) {
      inherit self inputs;
    };
  };
}
