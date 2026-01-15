{
  description = "Cheng's NixOS configuration! <3";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts/main";
    deploy-rs.url = "github:serokell/deploy-rs/master";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs self; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.home-manager.flakeModules.home-manager

        ./flake-modules/shell.nix

        ./flake-modules/library.nix

        ./flake-modules/nixos/options/system.nix

        ./flake-modules/nixos/hosts/taco.nix
        ./flake-modules/nixos/deploy.nix
      ];

      debug = true;
    };
}
