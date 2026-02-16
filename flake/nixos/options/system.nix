{ self, ... }:

{
  flake = {
    nixosOptions = import (self + /nixos/options/system);
  };
}
