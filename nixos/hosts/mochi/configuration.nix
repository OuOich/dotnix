{ inputs, pkgs, ... }:

{
  networking.hostName = "mochi";

  imports = [
    ./hardware-configuration.nix

    ./users.nix
    ./packages.nix

    ./stylix

    ./security/ssh

    ./desktop/sddm
    ./desktop/niri
  ];

  dotnix.templates.general-desktop.enable = true;

  dotnix.configurations = {
    qemu-guest.enable = true;
    common-sops.enable = true;
    desktop-comps.enable = true;
  };

  nixpkgs = {
    overlays = [
      inputs.niri.overlays.niri
    ];
  };

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "en_US.UTF-8";

  programs.fish.enable = true;

  system.stateVersion = "25.11";
}
