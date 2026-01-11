{ pkgs, lib, ... }:

{
  flake = rec {
    library = import ../library { inherit pkgs lib; };

    dotnix.lib = library;
  };
}
