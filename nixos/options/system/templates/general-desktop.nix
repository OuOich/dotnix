{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.dotnix.templates.general-desktop;
in
{
  options.dotnix.templates.general-desktop = {
    enable = lib.mkEnableOption "Whether to enable general desktop template.";
  };

  config = lib.mkIf cfg.enable {
    dotnix.configurations = {
      trusted-group.enable = lib.mkDefault true;
      common-nix.enable = lib.mkDefault true;
      common-sudo-rs.enable = lib.mkDefault true;
    };

    boot.loader = {
      grub = {
        enable = lib.mkDefault true;

        device = lib.mkDefault "nodev";
        efiSupport = lib.mkDefault true;
        efiInstallAsRemovable = lib.mkDefault true;
      };

      efi.efiSysMountPoint = lib.mkDefault "/boot";
    };

    networking = {
      useDHCP = lib.mkDefault true;
      nameservers = lib.mkDefault [
        "1.1.1.1"
        "8.8.8.8"
      ];

      networkmanager = {
        enable = lib.mkDefault true;

        settings = {
          connectivity.uri = lib.mkDefault "http://nmcheck.gnome.org/check_network_status.txt";
        };
      };
    };

    services.fail2ban = {
      enable = true;

      maxretry = 3;
      bantime = "1h";
    };

    programs.vim = {
      enable = lib.mkDefault true;

      defaultEditor = lib.mkDefault true;
    };

    programs.git = {
      enable = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      curl
      wget
      rsync

      kitty.terminfo
      wezterm.terminfo
      alacritty.terminfo
    ];
  };
}
