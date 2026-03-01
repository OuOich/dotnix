{ inputs, ... }:

{
  networking.hostName = "mochi";

  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix
    ./sops.nix

    ./users.nix
    ./packages.nix

    ./stylix

    ./security/ssh

    ./services/ssh
    ./services/keyd

    ./desktop/sddm
    ./desktop/plasma
    ./desktop/niri

    ./programs/gnupg
  ];

  dotnix.templates.general-desktop.enable = true;

  dotnix.configurations = {
    qemu-guest.enable = true;
    common-sops.enable = true;
    desktop-comps.enable = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      inputs.niri.overlays.niri
    ];
  };

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "en_US.UTF-8";

  programs.fish.enable = true;

  system.stateVersion = "25.11";
}
