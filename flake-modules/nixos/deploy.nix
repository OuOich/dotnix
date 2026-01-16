{ self, inputs, ... }:

{
  flake = {
    deploy = import (self + /nixos/deploy.nix) { inherit inputs self; };
  };
}
