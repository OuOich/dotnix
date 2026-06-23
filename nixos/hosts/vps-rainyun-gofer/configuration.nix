{
  networking.hostName = "vps-rainyun-gofer";

  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ./network.nix

    ./virtualisation/podman

    ./security/ssh

    ./services/ssh
    ./services/hermes

    ./containerized/searxng
  ];

  dotnix.templates.general-server.enable = true;

  dotnix.configurations = {
    trusted-group.enable = true;
    common-sops.enable = true;
  };

  time.timeZone = "UTC";

  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.11";
}
