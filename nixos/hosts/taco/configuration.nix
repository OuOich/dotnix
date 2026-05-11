{
  networking.hostName = "taco";

  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ./packages.nix
    ./impermanence.nix
    ./sops.nix
    ./stylix

    ./hardware/trackpoint

    ./security/ssh

    ./services/ssh
    ./services/keyd

    ./desktop/sddm
    ./desktop/niri

    ./programs/fish
    ./programs/gnupg
  ];

  dotnix.templates.general-laptop.enable = true;

  dotnix.configurations = {
    common-sops.enable = true;
    desktop-comps.enable = true;
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

  system.stateVersion = "25.11";
}
