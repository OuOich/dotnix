{
  flake = {
    lib = import ../library;
  };

  perSystem =
    { pkgs, ... }:
    {
      legacyPackages.lib = import ../library {
        inherit pkgs;
        inherit (pkgs) lib;
      };
    };
}
