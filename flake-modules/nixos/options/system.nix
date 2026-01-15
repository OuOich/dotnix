{ self, ... }:

{
  flake = {
    nixosOptions = import ../../../nixos/options/system { inherit (self) dotnix; };
  };
}
