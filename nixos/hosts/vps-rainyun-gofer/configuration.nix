{
  networking.hostName = "vps-rainyun-gofer";

  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ./network.nix

    ./security/ssh

    ./services/ssh
  ];

  dotnix.configurations = {
    common-nix = {
      enable = true;
      trustUsersInTrustedGroup = false;
    };
    common-sops.enable = true;
  };

  time.timeZone = "UTC";

  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.11";
}
