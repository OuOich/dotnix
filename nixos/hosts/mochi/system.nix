{ self, inputs, ... }:

inputs.nixpkgs.lib.nixosSystem rec {
  specialArgs = {
    inherit self inputs;
    inherit (self) dotnix;
  };

  modules = [
    self.nixosOptions

    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.stylix.nixosModules.stylix

    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        extraSpecialArgs = specialArgs;

        sharedModules = [
          inputs.stylix.homeModules.stylix
        ];

        # `home-manager.users` defined in ./users.nix
      };
    }

    ./configuration.nix
  ];
}
