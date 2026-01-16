{ self, ... }:

{
  flake = {
    nixosOptions = import (self + /nixos/options/system) { inherit (self) dotnix; };
  };
}
