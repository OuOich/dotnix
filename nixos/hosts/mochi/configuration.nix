{ pkgs, ... }:

{
  networking.hostName = "mochi";

  imports = [
    ./hardware-configuration.nix

    ./users.nix
    ./packages.nix
  ];

  dotnix.templates.general-desktop.enable = true;

  dotnix.configurations = {
    qemu-guest.enable = true;
    common-sops.enable = true;
  };

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  programs.dconf.enable = true;

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

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };

  system.stateVersion = "25.11";
}
