{ self, inputs, ... }:

let
  inherit (self.legacyPackages.x86_64-linux) dotnix;
in
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit self inputs dotnix;
  };

  modules = [
    self.nixosOverlays
    self.nixosOptions

    inputs.disko.nixosModules.default
    inputs.sops-nix.nixosModules.default

    ./configuration.nix
  ];
}
