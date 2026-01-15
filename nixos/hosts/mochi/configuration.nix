{ pkgs, ... }:

{
  networking.hostName = "mochi";

  imports = [
    ./hardware-configuration.nix

    ./users.nix
    ./packages.nix
  ];

  dotnix.templates.generalDesktop.enable = true;

  dotnix.configurations = {
    qemuGuest.enable = true;
    commonSops.enable = true;
  };

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  programs.fish.enable = true;

  dotnix.security.sshKeysMount = {
    enable = true;

    hostKeys = {
      ed25519 = true;
      rsa = true;
    };

    identityKeys = {
      "cheng@mochi" = {
        ed25519 = true;
        rsa = false;
      };
    };
  };

  system.stateVersion = "25.11";
}
