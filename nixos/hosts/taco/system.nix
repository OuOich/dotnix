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

    inputs.home-manager.nixosModules.default
    inputs.impermanence.nixosModules.default
    inputs.sops-nix.nixosModules.default
    inputs.stylix.nixosModules.default
    inputs.niri.nixosModules.niri
    inputs.noctalia.nixosModules.default

    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        extraSpecialArgs = specialArgs;

        sharedModules = [
          self.homeOptions

          inputs.sops-nix.homeManagerModules.default
          inputs.catppuccin.homeModules.default
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.noctalia.homeModules.default
          inputs.dotnvim.homeModules.default
          inputs.zen-browser.homeModules.default

          # NOTE: These modules are automatically imported by the corresponding system configuration.
          # inputs.impermanence.homeModules.default
          # inputs.stylix.homeModules.default
          # inputs.niri.homeModules.niri
        ];

        # `home-manager.users` defined in ./users.nix
      };
    }

    ./configuration.nix
  ];
}
