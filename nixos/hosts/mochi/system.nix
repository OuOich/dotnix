{ self, inputs, ... }:

inputs.nixpkgs.lib.nixosSystem rec {
  specialArgs = {
    inherit self inputs;
    inherit (self) dotnix;
  };

  modules = [
    self.nixosOptions

    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.home-manager

    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        extraSpecialArgs = specialArgs;

        # `home-manager.users` defined in ./users.nix
      };
    }

    ./configuration.nix
  ];
}
