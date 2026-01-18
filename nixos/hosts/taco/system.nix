{ self, inputs, ... }:

let
  dotnix = self.legacyPackages.x86_64-linux.dotnix;
in
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit self inputs dotnix;
  };

  modules = [
    self.nixosOptions

    inputs.sops-nix.nixosModules.sops

    ./configuration.nix
  ];
}
