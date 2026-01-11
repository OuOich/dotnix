{ inputs, self, ... }:

inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    inherit (self) dotnix;
  };

  modules = [
    ../../options/system

    inputs.sops-nix.nixosModules.sops

    ./configuration.nix
  ];
}
