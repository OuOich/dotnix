{ inputs, ... }:

{
  networking.hostName = "taco";

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
    ./desktop/niri

    ./programs/gnupg
  ];

  dotnix.templates.general-laptop.enable = true;

  dotnix.configurations = {
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

  networking = {
    defaultGateway = "192.168.2.1";

    interfaces = {
      wlp3s0 = {
        ipv4 = {
          addresses = [
            {
              address = "192.168.2.5";
              prefixLength = 24;
            }
          ];
        };
      };
    };
  };

  programs.fish.enable = true;

  system.stateVersion = "25.11";
}
