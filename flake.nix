{
  description = "Cheng's NixOS configuration! <3";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts/main";

    deploy-rs.url = "github:serokell/deploy-rs/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake/main";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit self inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.home-manager.flakeModules.home-manager

        ./flake-modules/shell.nix

        ./flake-modules/library.nix

        ./flake-modules/dotnix.nix

        ./flake-modules/nixos/options/system.nix
        ./flake-modules/nixos/options/home.nix

        ./flake-modules/nixos/hosts/mochi.nix
        ./flake-modules/nixos/hosts/taco.nix

        ./flake-modules/nixos/deploy.nix
      ];

      debug = true;
    };
}
