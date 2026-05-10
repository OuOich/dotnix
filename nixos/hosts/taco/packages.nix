{ inputs, pkgs, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      inputs.niri.overlays.niri
    ];
  };

  environment.systemPackages = with pkgs; [
  ];
}
