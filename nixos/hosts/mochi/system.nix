{ inputs, self, ... }:

inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    inherit (self) dotnix;
  };

  modules = [
    self.nixosOptions

    inputs.sops-nix.nixosModules.sops

    ./configuration.nix
  ];
}
