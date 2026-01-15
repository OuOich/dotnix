{ inputs, self, ... }:

{
  flake = {
    nixosConfigurations.taco = import ../../../nixos/hosts/taco/system.nix { inherit inputs self; };
  };
}
