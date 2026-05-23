{
  networking.hostName = "taco";

  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ./packages.nix
    ./impermanence.nix
    ./stylix
    # ./fonts

    ./hardware/trackpoint

    ./security/ssh

    ./services/ssh
    ./services/keyd

    ./desktop/ly
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

  system.stateVersion = "25.11";
}
