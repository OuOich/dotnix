{
  perSystem =
    { self', pkgs, ... }:
    {
      legacyPackages.dotnix = {
        inherit (self'.legacyPackages) lib;
        pkgs = self'.packages;
      };
    };
}
