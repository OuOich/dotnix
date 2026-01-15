{ inputs, self, ... }:

{
  flake = {
    nixosConfigurations.mochi = import ../../../nixos/hosts/mochi/system.nix { inherit inputs self; };
  };
}
