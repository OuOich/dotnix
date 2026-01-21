{ self, inputs, ... }:

let
  inherit (self.legacyPackages.x86_64-linux) dotnix;
in
inputs.nixpkgs.lib.nixosSystem rec {
  specialArgs = {
    inherit self inputs dotnix;
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
          self.homeOptions

          # inputs.stylix.homeModules.stylix
        ];

        # `home-manager.users` defined in ./users.nix
      };
    }

    ./configuration.nix
  ];
}
