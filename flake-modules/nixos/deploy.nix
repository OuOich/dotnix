{ inputs, self, ... }:

{
  flake = {
    deploy = import ../../nixos/deploy.nix { inherit inputs self; };
  };
}
