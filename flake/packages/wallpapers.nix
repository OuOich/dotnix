{
  perSystem =
    { pkgs, ... }:
    {
      packages.wallpapers = import ../../packages/wallpapers/package.nix {
        inherit pkgs;
        inherit (pkgs) lib;
      };
    };
}
