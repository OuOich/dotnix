{
  perSystem =
    { inputs', pkgs, ... }:
    {
      devShells.default = import ../shell.nix {
        inherit inputs' pkgs;
      };
    };
}
