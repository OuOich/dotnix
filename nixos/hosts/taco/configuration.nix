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
    ./hardware/bluetooth

    ./security/ssh

    ./services/auto-cpufreq
    ./services/ssh
    ./services/keyd
    ./services/udisks2

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
