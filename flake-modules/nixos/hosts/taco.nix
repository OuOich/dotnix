{ inputs, self, ... }:

{
  flake = {
    nixosConfigurations.taco = import ../../../nixos/hosts/taco { inherit inputs self; };
  };
}
