{ self, ... }:

{
  flake = {
    homeOptions = import (self + /nixos/options/home);
  };
}
