{ self, inputs, ... }:

inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit self inputs;
    inherit (self) dotnix;
  };

  modules = [
    self.nixosOptions

    inputs.sops-nix.nixosModules.sops

    ./configuration.nix
  ];
}
